import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../models/models.dart';
import '../../services/pairing/player_name_parser.dart';
import '../../services/ranking/ranking_calculator.dart';
import '../../services/schedule/endless_round_generator.dart';
import '../../services/schedule/round_robin_generator.dart';
import '../../services/storage/tournament_store.dart';

/// Penyimpanan turnamen di device. Di-override di `main()` dengan box Hive yang
/// sudah dibuka; default-nya memori saja supaya test tidak perlu plugin.
final tournamentStoreProvider = Provider<TournamentStore>((ref) => TournamentStore.memory());

/// Sumber kebenaran tunggal untuk turnamen yang sedang jalan.
class TournamentController extends Notifier<ActiveTournament?> {
  TournamentStore get _store => ref.read(tournamentStoreProvider);

  /// Config yang dipakai memulai turnamen di sesi ini (lihat [startIfNeeded]).
  TournamentConfig? _startedFrom;

  static const maxPlayers = 20;
  static const _minPlayers = 4;

  @override
  ActiveTournament? build() {
    // Auto-save lewat satu listener: semua mutasi di controller ini berakhir di
    // `state =`, jadi tidak ada call site yang bisa lupa menyimpan.
    listenSelf((_, next) {
      if (next != null) unawaited(_store.saveActive(next));
    });
    // Resume: kalau app sebelumnya di-kill, turnamennya kembali dari sini.
    return _store.loadActive();
  }

  /// Mulai turnamen baru dari [config]. Tidak melakukan apa-apa kalau turnamen
  /// dengan config yang sama sudah jalan (mis. screen di-rebuild).
  void startIfNeeded(TournamentConfig config) {
    // Dua-duanya perlu: config di state berganti kalau host menambah pemain,
    // sementara layar konfirmasi Mixed di belakangnya masih memegang config awal.
    if (state != null && (identical(state!.config, config) || identical(_startedFrom, config))) {
      return;
    }
    _startedFrom = config;

    final schedule = config.mode == PartnerMode.fixed
        ? RoundRobinGenerator.generate(pairs: config.fixedPairs ?? const [], courts: config.courts)
        : const FixedSchedule(matches: [], byePairIdByRound: {});

    state = ActiveTournament(
      tournament: Tournament(
        id: const Uuid().v4(),
        createdAt: DateTime.now(),
        config: config,
        matches: schedule.matches,
      ),
      byePairIdByRound: schedule.byePairIdByRound,
    );

    // Mode Mixed tidak punya jadwal di awal — round 1 langsung digenerate.
    if (config.mode == PartnerMode.mixed) generateNextRound();
  }

  /// Mode Mixed: buat round berikutnya dari history yang sudah ada.
  void generateNextRound() {
    final current = state;
    if (current == null || !current.canGenerateNextRound) return;

    final roundNumber = current.roundCount + 1;
    final round = EndlessRoundGenerator.generateRound(
      players: current.activePlayers,
      courts: current.courtsAvailableForRound(roundNumber),
      history: current.matches,
      roundNumber: roundNumber,
      matchCredits: current.matchCredits,
    );
    if (round == null) return;

    state = current.copyWith(
      tournament: current.tournament.copyWith(matches: [...current.matches, ...round.matches]),
      resting: {...current.restingPlayerIdsByRound, roundNumber: round.resting.map((p) => p.id).toList()},
    );
  }

  /// Mode Mixed: tambah pemain di tengah turnamen, ikut mulai round berikutnya.
  /// Mengembalikan pesan error untuk ditampilkan, atau null kalau berhasil.
  String? addPlayer(String rawName) {
    final current = state;
    if (current == null || current.config.mode != PartnerMode.mixed) return null;

    final name = PlayerNameParser.parse(rawName).names.firstOrNull;
    if (name == null) return 'Nama tidak boleh kosong';
    final taken = current.config.players.where((p) => p.name.toLowerCase() == name.toLowerCase());
    if (taken.isNotEmpty) {
      return current.withdrawnPlayerIds.contains(taken.first.id)
          ? '$name sudah ada — pakai "Kembalikan" di bawah'
          : '$name sudah ada di daftar';
    }
    if (current.activePlayers.length >= maxPlayers) return 'Maksimal $maxPlayers pemain aktif';

    final player = Player(id: const Uuid().v4(), name: name);
    state = current.copyWith(
      tournament: current.tournament.copyWith(
        config: current.config.copyWith(players: [...current.config.players, player]),
      ),
      matchCredits: _withCatchUpCredit(current, player.id),
    );
    return null;
  }

  /// Mode Mixed: pemain keluar (cedera, pulang duluan). Berlaku mulai round
  /// berikutnya — match yang sudah terjadwal tetap ada, host bisa menandainya WO.
  /// Mengembalikan false kalau sisa pemain aktif tidak cukup untuk satu match.
  bool withdrawPlayer(String playerId) {
    final current = state;
    if (current == null || current.activePlayers.length <= _minPlayers) return false;
    state = current.copyWith(withdrawn: {...current.withdrawnPlayerIds, playerId});
    return true;
  }

  /// Kebalikan [withdrawPlayer]; jumlah mainnya disejajarkan lagi lewat kredit.
  String? reinstatePlayer(String playerId) {
    final current = state;
    if (current == null || !current.withdrawnPlayerIds.contains(playerId)) return null;
    if (current.activePlayers.length >= maxPlayers) return 'Maksimal $maxPlayers pemain aktif';
    state = current.copyWith(
      withdrawn: {...current.withdrawnPlayerIds}..remove(playerId),
      matchCredits: _withCatchUpCredit(current, playerId),
    );
    return null;
  }

  static Map<String, int> _withCatchUpCredit(ActiveTournament active, String playerId) => {
    ...active.matchCredits,
    playerId: EndlessRoundGenerator.catchUpCredit(
      playerId: playerId,
      otherActivePlayers: [
        for (final p in active.activePlayers)
          if (p.id != playerId) p,
      ],
      history: active.matches,
      matchCredits: active.matchCredits,
    ),
  };

  void _update(Tournament Function(Tournament) change) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(tournament: change(current.tournament));
  }

  void submitScore(String matchId, List<SetScore> sets) {
    _update(
      (t) => t.copyWith(
        matches: [
          for (final m in t.matches)
            if (m.id == matchId) m.copyWith(sets: sets, status: MatchStatus.done) else m,
        ],
      ),
    );
  }

  void markWalkover(String matchId, {required String loserPairId, WoReason? reason}) {
    _update(
      (t) => t.copyWith(
        matches: [
          for (final m in t.matches)
            if (m.id == matchId)
              m.copyWith(status: MatchStatus.wo, woLoserPairId: loserPairId, woReason: reason)
            else
              m,
        ],
      ),
    );
  }

  /// Tutup turnamen aktif dan kembali ke keadaan awal. Hasilnya tidak dihapus,
  /// hanya pindah ke slot "turnamen terakhir selesai".
  /// Future-nya dikembalikan supaya test bisa menunggu tulisan ke device
  /// selesai; UI cukup memanggil dan langsung pindah layar.
  Future<void> close() async {
    final current = state;
    state = null;
    if (current != null) await _store.archiveActive(current);
  }

  /// Hentikan turnamen: match yang belum dimainkan ditandai "tidak dimainkan"
  /// supaya tidak ikut hitungan ranking.
  void finishNow() {
    _update(
      (t) => t.copyWith(
        isFinished: true,
        matches: [
          for (final m in t.matches)
            if (m.status == MatchStatus.pending) m.copyWith(status: MatchStatus.cancelled) else m,
        ],
      ),
    );
  }
}

final tournamentProvider = NotifierProvider<TournamentController, ActiveTournament?>(TournamentController.new);

/// Metode peringkat yang sedang dipilih host di layar Peringkat. Dipakai
/// bersama layar Detail Pemain dan Share supaya urutannya tidak berbeda-beda.
final rankingMethodProvider = StateProvider<RankingMethod>((ref) => RankingMethod.totalGames);

/// Baris peringkat siap tampil: per pemain di mode Mixed, per pasangan di mode
/// Fixed. Dibaca layar Peringkat, Detail Pemain, dan Share supaya nomor urut
/// yang sama muncul di ketiganya.
final standingEntriesProvider = Provider<List<StandingEntry>>((ref) {
  final active = ref.watch(tournamentProvider);
  if (active == null) return const [];
  return standingEntries(
    standings: ref.watch(standingsProvider),
    fixedPairs: active.config.mode == PartnerMode.fixed ? active.config.fixedPairs : null,
  );
});

/// Klasemen turnamen aktif menurut [rankingMethodProvider].
final standingsProvider = Provider<List<PlayerStanding>>((ref) {
  final active = ref.watch(tournamentProvider);
  if (active == null) return const [];
  return RankingCalculator.rank(
    players: active.config.players,
    matches: active.matches,
    method: ref.watch(rankingMethodProvider),
  );
});
