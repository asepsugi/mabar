import 'package:flutter/foundation.dart';

/// Jenis permainan.
enum SportType { tennis, padel }

extension SportTypeX on SportType {
  String get label => switch (this) {
    SportType.tennis => 'Tennis',
    SportType.padel => 'Padel',
  };

  /// Default durasi per match (menit).
  int get defaultMatchDurationMinutes => switch (this) {
    SportType.tennis => 20,
    SportType.padel => 15,
  };

  String get assetPath => switch (this) {
    SportType.tennis => 'assets/images/racket_tennis.png',
    SportType.padel => 'assets/images/racket_padel.png',
  };
}

enum PartnerMode { fixed, mixed }

extension PartnerModeX on PartnerMode {
  String get label => switch (this) {
    PartnerMode.fixed => 'Fixed',
    PartnerMode.mixed => 'Mixed',
  };

  String get assetPath => switch (this) {
    PartnerMode.fixed => 'assets/images/mode_fixed.png',
    PartnerMode.mixed => 'assets/images/mode_mixed.png',
  };
}

enum RankingMethod { winPercent, totalGames }

extension RankingMethodX on RankingMethod {
  String get label => switch (this) {
    RankingMethod.winPercent => 'Win %',
    RankingMethod.totalGames => 'Total Point',
  };
}

enum MatchStatus {
  pending, // belum dimain
  done, // skor sudah terinput
  wo, // walkover — salah satu pair menang otomatis
  cancelled, // tidak dimainkan (turnamen dihentikan sebelum match)
}

enum WoReason { absent, injury, timeOut, other }

extension WoReasonX on WoReason {
  String get label => switch (this) {
    WoReason.absent => 'Absen',
    WoReason.injury => 'Cedera',
    WoReason.timeOut => 'Waktu habis',
    WoReason.other => 'Lainnya',
  };
}

@immutable
class Player {
  final String id;
  final String name;
  const Player({required this.id, required this.name});

  Player copyWith({String? name}) => Player(id: id, name: name ?? this.name);
}

@immutable
class Court {
  final String id;
  final String name; // "Court 1" atau "Merah" dst
  final int colorIndex; // 0-9 index ke MabarColors.courtPalette
  final int bookingDurationMinutes;

  const Court({required this.id, required this.name, required this.colorIndex, required this.bookingDurationMinutes});

  Court copyWith({String? name, int? colorIndex, int? bookingDurationMinutes}) => Court(
    id: id,
    name: name ?? this.name,
    colorIndex: colorIndex ?? this.colorIndex,
    bookingDurationMinutes: bookingDurationMinutes ?? this.bookingDurationMinutes,
  );
}

@immutable
class Pair {
  final String id;
  final String player1Id;
  final String player2Id;
  const Pair({required this.id, required this.player1Id, required this.player2Id});

  bool contains(String playerId) => player1Id == playerId || player2Id == playerId;
  List<String> get playerIds => [player1Id, player2Id];
}

@immutable
class SetScore {
  final int side1;
  final int side2;
  const SetScore({required this.side1, required this.side2});
}

/// Satu match antara 2 pair. Pair bisa fixed (dari tournament.pairs) atau ad-hoc (mixed).
@immutable
class MatchGame {
  final String id;
  final int roundNumber;
  final int matchNumberInRound;
  final String courtId;
  final Pair pair1;
  final Pair pair2;
  final List<SetScore> sets;
  final MatchStatus status;
  final String? woLoserPairId; // pair yang WO (kalah); pemenang = pair sebelahnya
  final WoReason? woReason;

  const MatchGame({
    required this.id,
    required this.roundNumber,
    required this.matchNumberInRound,
    required this.courtId,
    required this.pair1,
    required this.pair2,
    this.sets = const [],
    this.status = MatchStatus.pending,
    this.woLoserPairId,
    this.woReason,
  });

  MatchGame copyWith({List<SetScore>? sets, MatchStatus? status, String? woLoserPairId, WoReason? woReason}) =>
      MatchGame(
        id: id,
        roundNumber: roundNumber,
        matchNumberInRound: matchNumberInRound,
        courtId: courtId,
        pair1: pair1,
        pair2: pair2,
        sets: sets ?? this.sets,
        status: status ?? this.status,
        woLoserPairId: woLoserPairId ?? this.woLoserPairId,
        woReason: woReason ?? this.woReason,
      );

  int get pair1TotalGames => sets.fold(0, (sum, s) => sum + s.side1);
  int get pair2TotalGames => sets.fold(0, (sum, s) => sum + s.side2);

  /// Winner pair id (null kalau pending/cancelled).
  String? get winnerPairId {
    switch (status) {
      case MatchStatus.pending:
      case MatchStatus.cancelled:
        return null;
      case MatchStatus.wo:
        return woLoserPairId == pair1.id ? pair2.id : pair1.id;
      case MatchStatus.done:
        int p1Sets = 0, p2Sets = 0;
        for (final s in sets) {
          if (s.side1 > s.side2)
            p1Sets++;
          else if (s.side2 > s.side1)
            p2Sets++;
        }
        if (p1Sets == p2Sets) return null; // draw
        return p1Sets > p2Sets ? pair1.id : pair2.id;
    }
  }
}

/// Konfigurasi turnamen (immutable snapshot dari setup).
@immutable
class TournamentConfig {
  final SportType sport;
  final PartnerMode mode;
  final int matchDurationMinutes;
  final List<Court> courts;
  final List<Player> players;
  final List<Pair>? fixedPairs; // null kalau mode = mixed
  const TournamentConfig({
    required this.sport,
    required this.mode,
    required this.matchDurationMinutes,
    required this.courts,
    required this.players,
    this.fixedPairs,
  });

  /// Max round berdasarkan durasi booking terpendek dari semua court.
  int get maxRounds {
    if (courts.isEmpty || matchDurationMinutes <= 0) return 0;
    final minBooking = courts.map((c) => c.bookingDurationMinutes).reduce((a, b) => a < b ? a : b);
    return minBooking ~/ matchDurationMinutes;
  }

  int get courtCount => courts.length;

  TournamentConfig copyWith({List<Player>? players}) => TournamentConfig(
    sport: sport,
    mode: mode,
    matchDurationMinutes: matchDurationMinutes,
    courts: courts,
    players: players ?? this.players,
    fixedPairs: fixedPairs,
  );
}

@immutable
class Tournament {
  final String id;
  final DateTime createdAt;
  final TournamentConfig config;
  final List<MatchGame> matches;
  final bool isFinished; // ditandai true saat host tekan "Selesaikan Turnamen" atau semua match done
  const Tournament({
    required this.id,
    required this.createdAt,
    required this.config,
    this.matches = const [],
    this.isFinished = false,
  });

  Tournament copyWith({TournamentConfig? config, List<MatchGame>? matches, bool? isFinished}) => Tournament(
    id: id,
    createdAt: createdAt,
    config: config ?? this.config,
    matches: matches ?? this.matches,
    isFinished: isFinished ?? this.isFinished,
  );
}

/// Turnamen yang sedang berjalan + metadata jadwal yang tidak disimpan di
/// [Tournament] (pair yang bye per round).
@immutable
class ActiveTournament {
  final Tournament tournament;
  final Map<int, String> byePairIdByRound;

  /// Pemain yang istirahat, per nomor round (mode Mixed).
  final Map<int, List<String>> restingPlayerIdsByRound;

  /// Mode Mixed: pemain yang keluar di tengah turnamen. Sengaja tidak dihapus
  /// dari `config.players` supaya nama di match lama dan peringkatnya tetap ada.
  final Set<String> withdrawnPlayerIds;

  /// Mode Mixed: tambahan jumlah main untuk pemain yang masuk/kembali di tengah
  /// jalan, supaya generator tidak menyuruhnya main terus sampai "menyusul".
  /// Hanya dipakai untuk prioritas jadwal, tidak ikut ranking.
  final Map<String, int> matchCredits;

  const ActiveTournament({
    required this.tournament,
    this.byePairIdByRound = const {},
    this.restingPlayerIdsByRound = const {},
    this.withdrawnPlayerIds = const {},
    this.matchCredits = const {},
  });

  TournamentConfig get config => tournament.config;
  List<MatchGame> get matches => tournament.matches;

  /// Pemain yang ikut dijadwalkan di round berikutnya.
  List<Player> get activePlayers => [
    for (final p in config.players)
      if (!withdrawnPlayerIds.contains(p.id)) p,
  ];

  int get roundCount => matches.isEmpty ? 0 : matches.last.roundNumber;

  List<MatchGame> matchesOfRound(int round) => matches.where((m) => m.roundNumber == round).toList();

  /// Round dianggap selesai kalau tidak ada lagi match yang menunggu skor.
  bool isRoundComplete(int round) => matchesOfRound(round).every((m) => m.status != MatchStatus.pending);

  /// Round pertama yang belum selesai — batas navigasi linier mode Fixed.
  int get currentRound {
    for (var r = 1; r <= roundCount; r++) {
      if (!isRoundComplete(r)) return r;
    }
    return roundCount;
  }

  int get playedMatchCount => matches.where((m) => m.status == MatchStatus.done || m.status == MatchStatus.wo).length;

  MatchGame? matchById(String id) => matches.where((m) => m.id == id).firstOrNull;

  /// "Andi + Budi" — nama depan kedua pemain di satu pair.
  String pairLabel(Pair pair) => pair.playerIds.map((id) => playerName(id).split(' ').first).join(' + ');

  Pair? pairById(String id) => config.fixedPairs?.where((p) => p.id == id).firstOrNull;

  String playerName(String id) => config.players
      .firstWhere(
        (p) => p.id == id,
        orElse: () => const Player(id: '', name: '?'),
      )
      .name;

  Court courtById(String id) => config.courts.firstWhere((c) => c.id == id, orElse: () => config.courts.first);

  /// Court yang masih punya sisa waktu booking untuk round ke-[round].
  List<Court> courtsAvailableForRound(int round) => [
    for (final c in config.courts)
      if (round * config.matchDurationMinutes <= c.bookingDurationMinutes) c,
  ];

  /// Mode Mixed: round berikutnya baru boleh digenerate kalau skor round
  /// berjalan sudah lengkap dan masih ada court yang waktunya cukup.
  bool get canGenerateNextRound =>
      !tournament.isFinished &&
      (roundCount == 0 || isRoundComplete(roundCount)) &&
      courtsAvailableForRound(roundCount + 1).isNotEmpty;

  /// Mode Mixed: round terakhir boleh dibatalkan & dibuat ulang selama belum
  /// ada satu skor pun (mis. pemain baru datang dan ingin langsung main).
  bool get canRedoLastRound =>
      config.mode == PartnerMode.mixed &&
      !tournament.isFinished &&
      roundCount > 0 &&
      matchesOfRound(roundCount).every((m) => m.status == MatchStatus.pending);

  ActiveTournament copyWith({
    Tournament? tournament,
    Map<int, List<String>>? resting,
    Set<String>? withdrawn,
    Map<String, int>? matchCredits,
  }) => ActiveTournament(
    tournament: tournament ?? this.tournament,
    byePairIdByRound: byePairIdByRound,
    restingPlayerIdsByRound: resting ?? restingPlayerIdsByRound,
    withdrawnPlayerIds: withdrawn ?? withdrawnPlayerIds,
    matchCredits: matchCredits ?? this.matchCredits,
  );
}
