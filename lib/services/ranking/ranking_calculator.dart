import '../../models/models.dart';

/// Rekap satu pemain untuk leaderboard.
class PlayerStanding {
  final Player player;
  final int wins;
  final int losses;
  final int draws;
  /// Game/poin dari match yang benar-benar dimainkan.
  final int gamesWon;
  final int gamesLost;
  final int woLosses;

  /// Game/poin yang didapat dari menang WO ([ScoreFormat.woWinnerScore]). Masuk [totalPoint], tidak
  /// masuk [gameDiff] — selisih kedua tim tidak berubah oleh WO.
  final int woPoints;

  const PlayerStanding({
    required this.player,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.gamesWon = 0,
    this.gamesLost = 0,
    this.woLosses = 0,
    this.woPoints = 0,
  });

  /// Hanya match yang benar-benar dihitung (selesai + WO).
  int get matchesPlayed => wins + losses + draws;

  /// Menang = 1, seri = 0.5, kalah = 0. Dipakai untuk win%.
  double get matchPoints => wins + draws * 0.5;

  /// "Total point" — seluruh game yang dimenangkan, dijumlah lintas match
  /// (mis. 6-5, 4-6, 3-6 → 6+4+3 = 13), ditambah nilai menang WO.
  int get totalPoint => gamesWon + woPoints;

  double get winPercent => matchesPlayed == 0 ? 0 : matchPoints / matchesPlayed * 100;

  int get gameDiff => gamesWon - gamesLost;

  /// Statistik yang tampil sama persis (poin, selisih, W–L–D) → nomor peringkat sama (09a).
  bool hasSameStatsAs(PlayerStanding other) =>
      totalPoint == other.totalPoint &&
      gameDiff == other.gameDiff &&
      wins == other.wins &&
      losses == other.losses &&
      draws == other.draws;

  PlayerStanding _add({
    int wins = 0,
    int losses = 0,
    int draws = 0,
    int gamesWon = 0,
    int gamesLost = 0,
    int woLosses = 0,
    int woPoints = 0,
  }) => PlayerStanding(
    player: player,
    wins: this.wins + wins,
    losses: this.losses + losses,
    draws: this.draws + draws,
    gamesWon: this.gamesWon + gamesWon,
    gamesLost: this.gamesLost + gamesLost,
    woLosses: this.woLosses + woLosses,
    woPoints: this.woPoints + woPoints,
  );
}

/// Penghitung ranking sesuai PRD bagian 4.2 & 4.3.
class RankingCalculator {
  /// Urutkan pemain menurut [method], dengan tie-breaker berjenjang:
  /// metode utama → total point → head-to-head → selisih game → nama.
  static List<PlayerStanding> rank({
    required List<Player> players,
    required List<MatchGame> matches,
    required RankingMethod method,
    required ScoreFormat format,
  }) {
    final standings = _standings(players, matches, format);
    final sorted = [...standings];

    sorted.sort((a, b) {
      final byMethod = _compareByMethod(a, b, method);
      if (byMethod != 0) return byMethod;

      final byPoint = b.totalPoint.compareTo(a.totalPoint);
      if (byPoint != 0) return byPoint;

      final byHeadToHead = _headToHead(a, b, matches);
      if (byHeadToHead != 0) return byHeadToHead;

      final byDiff = b.gameDiff.compareTo(a.gameDiff);
      if (byDiff != 0) return byDiff;

      // Langkah terakhir PRD adalah undian; di sini dipakai urutan nama supaya
      // peringkat tidak berubah-ubah tiap layar di-rebuild.
      return a.player.name.compareTo(b.player.name);
    });

    return sorted;
  }

  static int _compareByMethod(PlayerStanding a, PlayerStanding b, RankingMethod method) {
    switch (method) {
      case RankingMethod.winPercent:
        return b.winPercent.compareTo(a.winPercent);
      case RankingMethod.totalGames:
        return b.totalPoint.compareTo(a.totalPoint);
    }
  }

  /// Selisih kemenangan langsung antara dua pemain saat berhadapan.
  static int _headToHead(PlayerStanding a, PlayerStanding b, List<MatchGame> matches) {
    var aWins = 0;
    var bWins = 0;

    for (final m in matches) {
      if (!_counts(m)) continue;
      final winnerId = m.winnerPairId;
      if (winnerId == null) continue;

      final aSide = _sideOf(m, a.player.id);
      final bSide = _sideOf(m, b.player.id);
      if (aSide == null || bSide == null || aSide == bSide) continue;

      if (winnerId == aSide) {
        aWins++;
      } else {
        bWins++;
      }
    }
    return bWins.compareTo(aWins);
  }

  static Map<String, PlayerStanding> _byId(List<Player> players) => {
    for (final p in players) p.id: PlayerStanding(player: p),
  };

  static List<PlayerStanding> _standings(List<Player> players, List<MatchGame> matches, ScoreFormat format) {
    final table = _byId(players);

    for (final m in matches) {
      if (m.status != MatchStatus.done) continue;
      final winnerId = m.winnerPairId;
      for (final pair in [m.pair1, m.pair2]) {
        final isPair1 = pair.id == m.pair1.id;
        final won = winnerId == pair.id;
        final drawn = winnerId == null;
        for (final id in pair.playerIds) {
          final current = table[id];
          if (current == null) continue;
          table[id] = current._add(
            wins: won ? 1 : 0,
            losses: !won && !drawn ? 1 : 0,
            draws: drawn ? 1 : 0,
            gamesWon: isPair1 ? m.pair1TotalGames : m.pair2TotalGames,
            gamesLost: isPair1 ? m.pair2TotalGames : m.pair1TotalGames,
          );
        }
      }
    }

    // WO sesudah semua match yang dimainkan: nilai menang WO memakai rata-rata skor pemain itu sendiri,
    // jadi ikut berubah setiap kali dia main lagi (PRD 4.4).
    final played = {for (final e in table.entries) e.key: (games: e.value.gamesWon, count: e.value.matchesPlayed)};
    for (final m in matches) {
      if (m.status != MatchStatus.wo) continue;
      final winnerId = m.winnerPairId;
      for (final pair in [m.pair1, m.pair2]) {
        final won = winnerId == pair.id;
        for (final id in pair.playerIds) {
          final current = table[id];
          if (current == null) continue;
          final own = played[id]!;
          table[id] = current._add(
            wins: won ? 1 : 0,
            losses: won ? 0 : 1,
            woLosses: won ? 0 : 1,
            woPoints: won ? format.woWinnerScore(own.count == 0 ? null : own.games / own.count) : 0,
          );
        }
      }
    }

    return table.values.toList();
  }

  /// Match "Tidak Dimainkan" dan yang belum diisi tidak masuk hitungan apa pun.
  static bool _counts(MatchGame m) => m.status == MatchStatus.done || m.status == MatchStatus.wo;

  static String? _sideOf(MatchGame m, String playerId) {
    if (m.pair1.contains(playerId)) return m.pair1.id;
    if (m.pair2.contains(playerId)) return m.pair2.id;
    return null;
  }
}

/// Rekap per pemain untuk halaman detail.
class PlayerProfile {
  /// Match yang benar-benar dihitung dan melibatkan pemain ini, urut per round.
  final List<MatchGame> playedMatches;
  final Set<String> partnerIds;
  final Set<String> opponentIds;

  const PlayerProfile({required this.playedMatches, required this.partnerIds, required this.opponentIds});

  static PlayerProfile of({required String playerId, required List<MatchGame> matches}) {
    final played = <MatchGame>[];
    final partners = <String>{};
    final opponents = <String>{};

    for (final m in matches) {
      if (m.status != MatchStatus.done && m.status != MatchStatus.wo) continue;

      final own = m.pair1.contains(playerId)
          ? m.pair1
          : m.pair2.contains(playerId)
          ? m.pair2
          : null;
      if (own == null) continue;

      played.add(m);
      partners.addAll(own.playerIds.where((id) => id != playerId));
      final other = own.id == m.pair1.id ? m.pair2 : m.pair1;
      opponents.addAll(other.playerIds);
    }

    played.sort((a, b) => a.roundNumber.compareTo(b.roundNumber));
    return PlayerProfile(playedMatches: played, partnerIds: partners, opponentIds: opponents);
  }
}

/// Satu baris peringkat: satu pemain (mode Mixed) atau satu pasangan tetap
/// (mode Fixed).
///
/// Di mode Fixed pasangan tidak pernah berganti, jadi statistik kedua anggotanya
/// selalu identik — menampilkannya sebagai dua baris kembar cuma memanjangkan
/// klasemen tanpa menambah informasi.
class StandingEntry {
  /// Satu nama (Mixed) atau dua nama sesuai urutan di [Pair.playerIds] (Fixed).
  final List<Player> players;

  /// Statistik barisnya. Untuk pasangan, ini statistik yang dimiliki bersama.
  final PlayerStanding standing;

  /// Nomor peringkat; sama untuk baris yang statistiknya identik (1, 1, 3). Null = belum main (grup
  /// "Belum main" di Peringkat, tanpa nomor).
  final int? position;

  const StandingEntry({required this.players, required this.standing, required this.position});

  /// "Andi Pratama + Budi Santoso" — nama lengkap, bukan nama depan seperti di
  /// kartu jadwal, karena di klasemen ruangnya cukup dan homonim harus terbaca.
  String get label => players.map((p) => p.name).join(' + ');

  bool hasPlayer(String playerId) => players.any((p) => p.id == playerId);
}

/// Mengubah klasemen per pemain jadi baris peringkat bernomor.
///
/// [fixedPairs] kosong/null (mode Mixed) → satu baris per pemain. Urutan hasil
/// [RankingCalculator.rank] tidak pernah diubah di sini: pasangan mengambil
/// posisi anggota yang peringkatnya lebih tinggi. Baris tanpa match selesai/WO
/// dipindah ke belakang tanpa nomor — 0 poin belum main bisa terurut di atas
/// pemain yang kalah 0–21, padahal yang belum main memang tidak diperingkat.
List<StandingEntry> standingEntries({required List<PlayerStanding> standings, List<Pair>? fixedPairs}) {
  final rows = <(List<Player>, PlayerStanding)>[];
  if (fixedPairs == null || fixedPairs.isEmpty) {
    for (final s in standings) {
      rows.add(([s.player], s));
    }
  } else {
    final pairOfPlayer = <String, Pair>{
      for (final pair in fixedPairs)
        for (final id in pair.playerIds) id: pair,
    };
    final standingOfPlayer = {for (final s in standings) s.player.id: s};
    final taken = <String>{};
    for (final s in standings) {
      if (!taken.add(s.player.id)) continue;

      final pair = pairOfPlayer[s.player.id];
      // Pemain sisa (jumlah ganjil) tidak punya pasangan → tetap satu nama.
      if (pair == null) {
        rows.add(([s.player], s));
        continue;
      }

      final members = [
        for (final id in pair.playerIds)
          if (standingOfPlayer[id] != null) standingOfPlayer[id]!.player,
      ];
      taken.addAll(members.map((p) => p.id));
      rows.add((members, s));
    }
  }

  final entries = <StandingEntry>[];
  PlayerStanding? previous;
  for (final (players, s) in rows) {
    if (s.matchesPlayed == 0) continue;
    final position = previous != null && s.hasSameStatsAs(previous) ? entries.last.position : entries.length + 1;
    entries.add(StandingEntry(players: players, standing: s, position: position));
    previous = s;
  }
  return [
    ...entries,
    for (final (players, s) in rows)
      if (s.matchesPlayed == 0) StandingEntry(players: players, standing: s, position: null),
  ];
}
