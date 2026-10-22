import 'package:mabar/features/schedule/tournament_controller.dart';
import 'package:mabar/models/models.dart';

/// Turnamen yang sudah berjalan, seperti hasil resume: layar menerima config yang sama persis (identical),
/// jadi `startIfNeeded` tidak membuat jadwal baru.
class LoadedTournament extends TournamentController {
  final ActiveTournament active;
  LoadedTournament(this.active);

  @override
  ActiveTournament? build() => active;
}

/// Satu match Mixed: (atas, bawah) nama depan, skor atas–bawah; null = belum diisi.
typedef MatchSpec = (String, String, String, String, int?, int?);

/// Nama pemain contoh layar Pemain.
const fixtureNames = [
  'Andi P', 'Budi S', 'Citra L', 'Dewant R', 'Eko M', 'Fajar K', 'Gina R', 'Hana T', 'Indra W', 'Joko S', 'Kiki A', //
  'Lina M', 'Maya P', 'Nanda R', 'Oki S', 'Putri A', 'Rizky H', 'Sari D', 'Tono B', 'Umar F',
];

final fixtureStart = DateTime(2026, 10, 22, 19);

/// Turnamen Mixed dari daftar round. Bawaannya Padel Americano 21, 2 court × [bookingHours], 15 menit.
/// [roster] = nama pemain urut daftar (bawaan [players] nama pertama [fixtureNames]); [withdrawn] = nama
/// depan pemain yang keluar. Yang istirahat per round dicatat dari pemain yang tidak main, seperti generator.
ActiveTournament mixedTournament(
  List<List<MatchSpec>> rounds, {
  int players = 10,
  List<String>? roster,
  SportType sport = SportType.padel,
  ScoreFormat format = const ScoreFormat(ScoringMethod.americano, 21),
  int durationMinutes = 15,
  int bookingHours = 2,
  int courtCount = 2,
  List<String> courtNames = const [],
  Set<String> withdrawn = const {},
  String id = 't-mixed',
  bool finished = false,
  MatchGame Function(MatchGame m)? adjust,
}) {
  final names = roster ?? fixtureNames.take(players).toList();
  final people = [for (var i = 0; i < names.length; i++) Player(id: 'p${i.toString().padLeft(2, '0')}', name: names[i])];
  String pid(String first) => people.firstWhere((p) => p.name.split(' ').first == first).id;
  Pair pair(String a, String b) => Pair(id: '${pid(a)}+${pid(b)}', player1Id: pid(a), player2Id: pid(b));
  final matches = <MatchGame>[];
  for (final (r, round) in rounds.indexed) {
    for (final (c, (a, b, x, y, s1, s2)) in round.indexed) {
      var m = MatchGame(
        id: 'r${r + 1}c${c + 1}',
        roundNumber: r + 1,
        matchNumberInRound: c + 1,
        courtId: 'c${c + 1}',
        pair1: pair(a, b),
        pair2: pair(x, y),
      );
      if (s1 != null) m = m.withScore([SetScore(side1: s1, side2: s2!)]);
      if (finished && s1 == null) m = m.copyWith(status: MatchStatus.cancelled);
      matches.add(adjust?.call(m) ?? m);
    }
  }
  return ActiveTournament(
    tournament: Tournament(
      id: id,
      createdAt: fixtureStart,
      isFinished: finished,
      config: TournamentConfig(
        sport: sport,
        mode: PartnerMode.mixed,
        matchDurationMinutes: durationMinutes,
        courts: [
          for (var i = 0; i < courtCount; i++)
            Court(
              id: 'c${i + 1}',
              name: i < courtNames.length ? courtNames[i] : 'Court ${i + 1}',
              colorIndex: i,
              bookingDurationMinutes: bookingHours * 60,
            ),
        ],
        players: people,
        format: format,
      ),
      matches: matches,
    ),
    restingPlayerIdsByRound: {
      for (var r = 1; r <= rounds.length; r++)
        r: [
          for (final p in people)
            if (!withdrawn.contains(p.name.split(' ').first) &&
                !matches.any((m) => m.roundNumber == r && (m.pair1.contains(p.id) || m.pair2.contains(p.id))))
              p.id,
        ],
    },
    withdrawnPlayerIds: {for (final first in withdrawn) pid(first)},
  );
}

/// Round contoh Jadwal Mixed 06f–06j (10 pemain): R1 Gina·Hana istirahat, R2 Eko·Fajar, R3 Indra·Joko.
const mixedR1 = <MatchSpec>[('Andi', 'Budi', 'Citra', 'Dewant', 12, 9), ('Eko', 'Fajar', 'Indra', 'Joko', 10, 11)];
const mixedR2 = <MatchSpec>[('Gina', 'Andi', 'Hana', 'Citra', 11, 10), ('Indra', 'Budi', 'Joko', 'Dewant', 13, 8)];
const mixedR3Running = <MatchSpec>[('Andi', 'Dewant', 'Citra', 'Fajar', 13, 8), ('Eko', 'Budi', 'Hana', 'Gina', null, null)];

/// R8 di 06l (waktu habis); R1–R7 bergantian [mixedR1]/[mixedR2].
final mixedTimeUpRounds = [
  for (var r = 0; r < 7; r++) r.isEven ? mixedR1 : mixedR2,
  const <MatchSpec>[('Citra', 'Joko', 'Andi', 'Eko', 9, 12), ('Dewant', 'Indra', 'Budi', 'Fajar', 14, 7)],
];
