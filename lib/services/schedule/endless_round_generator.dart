import 'dart:math';

import '../../models/models.dart';

/// Kapan court yang baru ditambah atau diubah jamnya dipakai ([EndlessRoundGenerator.courtUse]).
enum CourtUse { now, nextRound, unused }

/// Hasil generate satu round mode Mixed (endless).
class EndlessRound {
  final List<MatchGame> matches;
  final List<Player> resting;

  const EndlessRound({required this.matches, required this.resting});
}

/// Generator round mode Mixed.
///
/// Urutannya persis seperti di PRD:
/// 1. Pilih pemain prioritas — paling sedikit main, lalu paling lama istirahat ([priorityOrder]).
/// 2. Acak pasangan di antara pemain aktif dengan constraint dari history.
/// 3. Tempatkan tiap match ke satu court.
///
/// Constraint pairing di-relax berjenjang lewat bobot penalti: mengulang lawan
/// jauh lebih murah daripada mengulang partner, dan mengulang pertandingan yang
/// persis sama paling mahal — jadi kalau tidak ada solusi bersih, yang dikorbankan
/// adalah constraint yang paling lunak.
class EndlessRoundGenerator {
  static const _repeatMatchPenalty = 1000;
  static const _repeatPartnerPenalty = 10;
  static const _repeatOpponentPenalty = 3;
  static const _maxAttempts = 400;

  /// [players] hanya pemain aktif (yang keluar tidak dioper). [matchCredits]
  /// ditambahkan ke jumlah main saat memilih prioritas — lihat [catchUpCredit].
  /// [seed] = `ActiveTournament.drawSeed`; [random] hanya untuk menyusun pasangan.
  static EndlessRound? generateRound({
    required List<Player> players,
    required List<Court> courts,
    required List<MatchGame> history,
    required int roundNumber,
    required int seed,
    Map<String, int> matchCredits = const {},
    Random? random,
  }) {
    final capacity = slotsFor(players: players.length, courts: courts.length);
    if (capacity < 4) return null;

    final sorted = priorityOrder(
      players: players,
      history: history,
      roundNumber: roundNumber,
      seed: seed,
      matchCredits: matchCredits,
    );
    final active = sorted.take(capacity).toList();
    final resting = sorted.skip(capacity).toList();

    final arrangement = _bestArrangement(active, _History(history, matchCredits), random ?? Random());

    final matches = <MatchGame>[];
    for (var i = 0; i < arrangement.length; i++) {
      final (pair1, pair2) = arrangement[i];
      matches.add(
        MatchGame(
          id: 'm-r$roundNumber-${i + 1}',
          roundNumber: roundNumber,
          matchNumberInRound: i + 1,
          courtId: courts[i].id,
          pair1: pair1,
          pair2: pair2,
        ),
      );
    }

    return EndlessRound(matches: matches, resting: resting);
  }

  /// Pemain yang main di satu round: 4 per court, dibatasi jumlah pemain, selalu kelipatan 4.
  static int slotsFor({required int players, required int courts}) => (min(players, courts * 4) ~/ 4) * 4;

  /// Urutan prioritas main di round [roundNumber]: paling sedikit main (termasuk kredit), lalu paling
  /// lama istirahat, lalu undian. Undiannya dikunci per round — `Random(seed + roundNumber)` dibagikan
  /// ke pemain urut id — jadi daftar "Prioritas main di R…" yang tampil sebelum tombol Buat ditekan
  /// selalu sama dengan hasil Buat. Kunci terakhir id pemain, karena `List.sort` Dart tidak stabil.
  static List<Player> priorityOrder({
    required List<Player> players,
    required List<MatchGame> history,
    required int roundNumber,
    required int seed,
    Map<String, int> matchCredits = const {},
  }) {
    final stats = _History(history, matchCredits);
    final ids = players.map((p) => p.id).toList()..sort();
    final rng = Random(seed + roundNumber);
    final draw = {for (final id in ids) id: rng.nextInt(1 << 30)};

    return [...players]..sort((a, b) {
      final byMatches = stats.matchCount(a.id).compareTo(stats.matchCount(b.id));
      if (byMatches != 0) return byMatches;
      final byRest = stats.lastRound(a.id).compareTo(stats.lastRound(b.id));
      if (byRest != 0) return byRest;
      final byDraw = draw[a.id]!.compareTo(draw[b.id]!);
      if (byDraw != 0) return byDraw;
      return a.id.compareTo(b.id);
    });
  }

  /// Baris Istirahat di tab round terakhir n (06f–06o): pemain aktif **sekarang** yang tidak main di
  /// round n, urut seperti daftar pemain. [priority] = yang pasti kebagian slot R(n+1) menurut
  /// [priorityOrder] (sama persis dengan hasil Buat pada [now]); [later] = yang istirahat lagi. Kalau tidak
  /// ada court yang muat R(n+1) (waktu habis, 06l), slot dihitung dari semua court — round berikutnya baru
  /// ada setelah Lanjutkan turnamen, dan yang istirahat tetap diprioritaskan di sana.
  static ({List<Player> priority, List<Player> later}) restingAfterLastRound(ActiveTournament active, DateTime now) {
    final n = active.roundCount;
    final playing = {
      for (final m in active.matchesOfRound(n)) ...[...m.pair1.playerIds, ...m.pair2.playerIds],
    };
    final resting = [
      for (final p in active.activePlayers)
        if (!playing.contains(p.id)) p,
    ];
    if (resting.isEmpty) return (priority: const [], later: const []);

    final courts = active.courtsAvailableAt(now);
    final slots = slotsFor(
      players: active.activePlayers.length,
      courts: courts.isEmpty ? active.config.courts.length : courts.length,
    );
    final next = priorityOrder(
      players: active.activePlayers,
      history: active.matches,
      roundNumber: n + 1,
      seed: active.drawSeed,
      matchCredits: active.matchCredits,
    ).take(slots).map((p) => p.id).toSet();

    return (
      priority: [
        for (final p in resting)
          if (next.contains(p.id)) p,
      ],
      later: [
        for (final p in resting)
          if (!next.contains(p.id)) p,
      ],
    );
  }

  /// Apa yang terjadi dengan court [courtId] di [active] (sudah berisi court baru atau jam yang diubah) pada [now]
  /// — Kelola court & detail court, logic.md §10:
  /// - [CourtUse.now]: round terakhir masih berjalan, court belum punya match di round itu, sisanya muat satu match,
  ///   dan yang istirahat minimal 4 → satu match baru untuk [players] (4 teratas urutan prioritas R(n+1) di antara
  ///   yang istirahat, persis daftar "Prioritas main di R…" kalau slotnya 4).
  /// - [CourtUse.nextRound]: court menambah slot round berikutnya.
  /// - [CourtUse.unused]: pemain tidak cukup untuk court ini, atau sisanya tidak muat satu match.
  ///
  /// [wasAvailable] = court lama yang sebelum diubah sudah muat satu match: mengganti nama atau menambah jamnya tidak
  /// boleh tiba-tiba membuat match di round yang sedang berjalan.
  static ({CourtUse use, List<Player> players}) courtUse(
    ActiveTournament active,
    String courtId,
    DateTime now, {
    bool wasAvailable = false,
  }) {
    final court = active.config.courts.firstWhere((c) => c.id == courtId);
    final fits = active.remainingBookingMinutes(court, now) >= active.config.matchDurationMinutes;
    final n = active.roundCount;
    final running = n > 0 && !active.tournament.isFinished && !active.isRoundComplete(n);
    if (fits && running && !wasAvailable && !active.matchesOfRound(n).any((m) => m.courtId == courtId)) {
      final playing = {
        for (final m in active.matchesOfRound(n)) ...[...m.pair1.playerIds, ...m.pair2.playerIds],
      };
      final waiting = priorityOrder(
        players: active.activePlayers,
        history: active.matches,
        roundNumber: n + 1,
        seed: active.drawSeed,
        matchCredits: active.matchCredits,
      ).where((p) => !playing.contains(p.id)).toList();
      if (waiting.length >= 4) return (use: CourtUse.now, players: waiting.take(4).toList());
    }
    final available = active.courtsAvailableAt(now);
    final players = active.activePlayers.length;
    final adds =
        fits &&
        slotsFor(players: players, courts: available.length) >
            slotsFor(players: players, courts: available.where((c) => c.id != courtId).length);
    return (use: adds ? CourtUse.nextRound : CourtUse.unused, players: const []);
  }

  /// Match tambahan di round terakhir untuk court [courtId] (hasil [CourtUse.now]): pasangan disusun dengan penalti
  /// yang sama dengan [generateRound], nomornya melanjutkan match terakhir di round itu.
  static MatchGame courtMatch(ActiveTournament active, String courtId, List<Player> players, {Random? random}) {
    assert(players.length == 4);
    final n = active.roundCount;
    final (pair1, pair2) = _bestArrangement(
      players,
      _History(active.matches, active.matchCredits),
      random ?? Random(),
    ).single;
    final number = active.matchesOfRound(n).fold(0, (top, m) => max(top, m.matchNumberInRound)) + 1;
    return MatchGame(
      id: 'm-r$n-$number',
      roundNumber: n,
      matchNumberInRound: number,
      courtId: courtId,
      pair1: pair1,
      pair2: pair2,
    );
  }

  /// Kredit untuk [playerId] yang masuk (atau kembali) di tengah turnamen:
  /// jumlah mainnya disejajarkan dengan pemain aktif lain yang paling sedikit
  /// main. Tanpa ini pemain baru (0 match) selalu di urutan prioritas teratas
  /// dan main terus beberapa round sampai menyusul, sementara yang lain istirahat.
  /// Kredit tidak pernah turun, jadi pemain yang kembali tidak "diutangi" lagi.
  static int catchUpCredit({
    required String playerId,
    required List<Player> otherActivePlayers,
    required List<MatchGame> history,
    Map<String, int> matchCredits = const {},
  }) {
    final current = matchCredits[playerId] ?? 0;
    if (otherActivePlayers.isEmpty) return current;

    final stats = _History(history, matchCredits);
    final floor = otherActivePlayers.map((p) => stats.matchCount(p.id)).reduce(min);
    final played = stats.matchCount(playerId) - current;
    return max(current, floor - played);
  }

  /// Coba beberapa susunan acak, ambil yang penaltinya paling kecil.
  static List<(Pair, Pair)> _bestArrangement(List<Player> active, _History stats, Random rng) {
    List<(Pair, Pair)>? best;
    var bestPenalty = 1 << 30;

    for (var attempt = 0; attempt < _maxAttempts; attempt++) {
      final shuffled = [...active]..shuffle(rng);
      final candidate = <(Pair, Pair)>[];
      for (var i = 0; i < shuffled.length; i += 4) {
        candidate.add((_pairOf(shuffled[i], shuffled[i + 1]), _pairOf(shuffled[i + 2], shuffled[i + 3])));
      }

      final penalty = _penalty(candidate, stats);
      if (penalty < bestPenalty) {
        best = candidate;
        bestPenalty = penalty;
        if (penalty == 0) break;
      }
    }

    return best!;
  }

  static int _penalty(List<(Pair, Pair)> arrangement, _History stats) {
    var total = 0;
    for (final (p1, p2) in arrangement) {
      total += stats.partnerCount(p1.player1Id, p1.player2Id) * _repeatPartnerPenalty;
      total += stats.partnerCount(p2.player1Id, p2.player2Id) * _repeatPartnerPenalty;
      for (final a in p1.playerIds) {
        for (final b in p2.playerIds) {
          total += stats.opponentCount(a, b) * _repeatOpponentPenalty;
        }
      }
      if (stats.hasPlayedMatchup(p1, p2)) total += _repeatMatchPenalty;
    }
    return total;
  }

  static Pair _pairOf(Player a, Player b) => Pair(id: _pairKey(a.id, b.id), player1Id: a.id, player2Id: b.id);

  static String _pairKey(String a, String b) => (a.compareTo(b) <= 0) ? '$a+$b' : '$b+$a';
}

/// Rekap history pertandingan yang sudah terjadi.
class _History {
  final Map<String, int> _matchCount = {};
  final Map<String, int> _lastRound = {};
  final Map<String, int> _partner = {};
  final Map<String, int> _opponent = {};
  final Set<String> _matchups = {};

  final Map<String, int> _credits;

  _History(List<MatchGame> history, this._credits) {
    for (final m in history) {
      if (m.status == MatchStatus.cancelled) continue;

      for (final pair in [m.pair1, m.pair2]) {
        _bump(_partner, EndlessRoundGenerator._pairKey(pair.player1Id, pair.player2Id));
        for (final id in pair.playerIds) {
          _matchCount[id] = (_matchCount[id] ?? 0) + 1;
          _lastRound[id] = m.roundNumber;
        }
      }
      for (final a in m.pair1.playerIds) {
        for (final b in m.pair2.playerIds) {
          _bump(_opponent, EndlessRoundGenerator._pairKey(a, b));
        }
      }
      _matchups.add(_matchupKey(m.pair1, m.pair2));
    }
  }

  static void _bump(Map<String, int> map, String key) => map[key] = (map[key] ?? 0) + 1;

  static String _matchupKey(Pair a, Pair b) {
    final keys = [
      EndlessRoundGenerator._pairKey(a.player1Id, a.player2Id),
      EndlessRoundGenerator._pairKey(b.player1Id, b.player2Id),
    ]..sort();
    return keys.join('|');
  }

  /// Termasuk kredit — angka inilah yang dipakai untuk prioritas.
  int matchCount(String playerId) => (_matchCount[playerId] ?? 0) + (_credits[playerId] ?? 0);
  int lastRound(String playerId) => _lastRound[playerId] ?? 0;
  int partnerCount(String a, String b) => _partner[EndlessRoundGenerator._pairKey(a, b)] ?? 0;
  int opponentCount(String a, String b) => _opponent[EndlessRoundGenerator._pairKey(a, b)] ?? 0;
  bool hasPlayedMatchup(Pair a, Pair b) => _matchups.contains(_matchupKey(a, b));
}
