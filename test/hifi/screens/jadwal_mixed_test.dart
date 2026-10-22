import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mabar/core/widgets/mabar_controls.dart';
import 'package:mabar/features/schedule/schedule_mixed_screen.dart';
import 'package:mabar/features/schedule/tournament_controller.dart';
import 'package:mabar/models/models.dart';

import '../hifi_golden.dart';
import 'screen_harness.dart';

/// Turnamen yang sudah berjalan, seperti hasil resume: config `identical`, jadi tidak dibuat ulang.
class _Loaded extends TournamentController {
  final ActiveTournament active;
  _Loaded(this.active);

  @override
  ActiveTournament? build() => active;
}

/// Satu match: (atas, bawah) nama depan, skor atas–bawah; null = belum diisi.
typedef _M = (String, String, String, String, int?, int?);

/// Golden layar penuh Jadwal Mixed, frame 06f–06o. Padel Americano 21, 2 court, durasi 15 menit; 10 pemain
/// (06o: 20). Yang istirahat per round dicatat dari pemain yang tidak main, seperti generator.
void main() {
  const names = [
    'Andi P', 'Budi S', 'Citra L', 'Dewant R', 'Eko M', 'Fajar K', 'Gina R', 'Hana T', 'Indra W', 'Joko S', 'Kiki A', //
    'Lina M', 'Maya P', 'Nanda R', 'Oki S', 'Putri A', 'Rizky H', 'Sari D', 'Tono B', 'Umar F',
  ];
  final start = DateTime(2026, 10, 22, 19);

  ActiveTournament tournament(
    List<List<_M>> rounds, {
    int players = 10,
    int bookingHours = 2,
    String id = 't-mixed',
    bool finished = false,
    MatchGame Function(MatchGame m)? adjust,
  }) {
    final roster = [for (var i = 0; i < players; i++) Player(id: 'p${i.toString().padLeft(2, '0')}', name: names[i])];
    String pid(String first) => roster.firstWhere((p) => p.name.split(' ').first == first).id;
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
        createdAt: start,
        isFinished: finished,
        config: TournamentConfig(
          sport: SportType.padel,
          mode: PartnerMode.mixed,
          matchDurationMinutes: 15,
          courts: [
            for (var i = 0; i < 2; i++)
              Court(id: 'c${i + 1}', name: 'Court ${i + 1}', colorIndex: i, bookingDurationMinutes: bookingHours * 60),
          ],
          players: roster,
          format: const ScoreFormat(ScoringMethod.americano, 21),
        ),
        matches: matches,
      ),
      restingPlayerIdsByRound: {
        for (var r = 1; r <= rounds.length; r++)
          r: [
            for (final p in roster)
              if (!matches.any((m) => m.roundNumber == r && (m.pair1.contains(p.id) || m.pair2.contains(p.id)))) p.id,
          ],
      },
    );
  }

  // Round awal yang tidak tampil di frame 06f–06j (lengkap, Gina·Hana lalu Eko·Fajar istirahat).
  const r1 = <_M>[('Andi', 'Budi', 'Citra', 'Dewant', 12, 9), ('Eko', 'Fajar', 'Indra', 'Joko', 10, 11)];
  const r2 = <_M>[('Gina', 'Andi', 'Hana', 'Citra', 11, 10), ('Indra', 'Budi', 'Joko', 'Dewant', 13, 8)];
  const r3Running = <_M>[('Andi', 'Dewant', 'Citra', 'Fajar', 13, 8), ('Eko', 'Budi', 'Hana', 'Gina', null, null)];
  const r3Done = <_M>[('Andi', 'Dewant', 'Citra', 'Fajar', 13, 8), ('Hana', 'Gina', 'Eko', 'Budi', null, null)];
  const r4 = <_M>[('Indra', 'Citra', 'Joko', 'Hana', null, null), ('Andi', 'Fajar', 'Budi', 'Gina', null, null)];
  MatchGame wo(MatchGame m) => m.id == 'r3c2' ? m.asWalkover(loserPairId: m.pair2.id, reason: WoReason.absent) : m;

  final f = tournament([r1, r2, r3Running]);
  final g = tournament([r1, r2, r3Done], adjust: wo);
  final h = tournament([r1, r2, r3Done, r4], adjust: wo);

  Widget screen(ActiveTournament active, Duration elapsed) => hifiScreen(
    ScheduleMixedScreen(config: active.config),
    overrides: [
      tournamentProvider.overrideWith(() => _Loaded(active)),
      clockProvider.overrideWithValue(() => start.add(elapsed)),
    ],
  );

  testWidgets('06f round berjalan', (tester) async {
    await expectMatchesHifi(tester, screen(f, const Duration(minutes: 40)), '06f');
  });

  testWidgets('06g round lengkap, WO beralasan', (tester) async {
    await expectMatchesHifi(tester, screen(g, const Duration(minutes: 52)), '06g');
  });

  testWidgets('06h round baru, masih bisa dibatalkan', (tester) async {
    await expectMatchesHifi(tester, screen(h, const Duration(minutes: 53)), '06h');
  });

  testWidgets('06i menu ⋯', (tester) async {
    await expectMatchesHifi(
      tester,
      screen(h, const Duration(minutes: 53)),
      '06i',
      act: (tester) => tester.tap(find.bySemanticsLabel('Menu')),
    );
  });

  testWidgets('06j dialog batalkan round', (tester) async {
    await expectMatchesHifi(
      tester,
      screen(h, const Duration(minutes: 53)),
      '06j',
      act: (tester) => tester.tap(find.text('Batalkan R4')),
    );
  });

  testWidgets('06k sheet cara kerja Mixed', (tester) async {
    await expectMatchesHifi(
      tester,
      screen(tournament([r1.map((m) => (m.$1, m.$2, m.$3, m.$4, null, null)).toList()]), Duration.zero),
      '06k',
      act: (tester) async {
        await tester.tap(find.bySemanticsLabel('Menu'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cara kerja Mixed'));
      },
    );
  });

  testWidgets('06l waktu booking habis', (tester) async {
    final rounds = [
      for (var r = 0; r < 7; r++) r.isEven ? r1 : r2,
      const <_M>[('Citra', 'Joko', 'Andi', 'Eko', 9, 12), ('Dewant', 'Indra', 'Budi', 'Fajar', 14, 7)],
    ];
    await expectMatchesHifi(tester, screen(tournament(rounds), const Duration(hours: 2, minutes: 4)), '06l');
  });

  testWidgets('06m diakhiri, bisa dilanjutkan', (tester) async {
    final rounds = [
      r1, r2, r3Running.map((m) => (m.$1, m.$2, m.$3, m.$4, 11, 10)).toList(), r1, //
      const <_M>[('Andi', 'Gina', 'Budi', 'Indra', 11, 10), ('Citra', 'Eko', 'Hana', 'Joko', null, null)],
    ];
    await expectMatchesHifi(tester, screen(tournament(rounds, finished: true), Duration.zero), '06m');
  });

  testWidgets('06n banyak round, melihat round awal', (tester) async {
    final rounds = [
      r1,
      const <_M>[('Andi', 'Citra', 'Budi', 'Dewant', 12, 9), ('Eko', 'Gina', 'Fajar', 'Hana', 10, 11)],
      for (var r = 2; r < 11; r++) r.isEven ? r1 : r2,
      const <_M>[('Andi', 'Budi', 'Citra', 'Dewant', 12, 9), ('Eko', 'Fajar', 'Indra', 'Joko', null, null)],
    ];
    await expectMatchesHifi(
      tester,
      screen(tournament(rounds, bookingHours: 4), const Duration(hours: 3, minutes: 10)),
      '06n',
      act: (tester) async {
        // Host menggeser baris tab ke awal, lalu mengetuk R2.
        await tester.drag(find.text('R10'), const Offset(800, 0));
        await tester.pumpAndSettle();
        await tester.tap(find.text('R2'));
      },
    );
  });

  testWidgets('06o banyak yang istirahat, 20 pemain', (tester) async {
    // R1: Andi·Budi·Citra·Dewant + Eko·Fajar·Gina·Hana; R2: 8 lainnya; R3: 4 pertama R1 + 4 yang belum main.
    // Untuk R4: Eko–Hana paling lama istirahat; 4 dari 8 pemain R2 diundi (seed id turnamen, round 4).
    const rounds = [
      <_M>[('Andi', 'Eko', 'Budi', 'Fajar', 11, 10), ('Citra', 'Gina', 'Dewant', 'Hana', 12, 9)],
      <_M>[('Kiki', 'Indra', 'Maya', 'Joko', 11, 10), ('Rizky', 'Nanda', 'Umar', 'Tono', 12, 9)],
      <_M>[('Andi', 'Lina', 'Budi', 'Oki', 13, 8), ('Citra', 'Putri', 'Dewant', 'Sari', null, null)],
    ];
    await expectMatchesHifi(
      tester,
      screen(tournament(rounds, players: 20, id: 't-06o-25'), const Duration(minutes: 40)),
      '06o',
    );
  });

  Future<void> pumpRouted(WidgetTester tester, ActiveTournament active, List<String> visited) async {
    tester.view.physicalSize = const Size(390, 844) * hifiPixelRatio;
    tester.view.devicePixelRatio = hifiPixelRatio;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/schedule',
      routes: [
        GoRoute(path: '/schedule', builder: (_, _) => ScheduleMixedScreen(config: active.config)),
        GoRoute(
          path: '/score-input',
          builder: (_, state) {
            visited.add('score:${state.extra}');
            return const Text('Input skor');
          },
        ),
        GoRoute(
          path: '/leaderboard',
          builder: (_, _) {
            visited.add('leaderboard');
            return const Text('Peringkat');
          },
        ),
      ],
    );
    await tester.pumpWidget(
      hifiRouterScreen(
        router,
        overrides: [
          tournamentProvider.overrideWith(() => _Loaded(active)),
          clockProvider.overrideWithValue(() => start),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  MabarButton primary(WidgetTester tester) => tester.widget<MabarButton>(find.byType(MabarButton).last);

  testWidgets('Buat R4 pindah ke round baru; Batalkan kembali ke R3', (tester) async {
    await pumpRouted(tester, g, []);
    await tester.tap(find.text('R1'));
    await tester.pumpAndSettle();
    expect(find.text('Batalkan R3'), findsNothing);
    await tester.tap(find.text('Buat R4'));
    await tester.pumpAndSettle();
    expect(find.text('Round 4'), findsOneWidget);
    expect(find.text('Batalkan R4'), findsOneWidget);
    expect(primary(tester).meta, '· tunggu 2 match');

    await tester.tap(find.text('R2'));
    await tester.pumpAndSettle();
    expect(find.text('Batalkan R4'), findsNothing, reason: 'hanya di tab round terakhir');
    await tester.tap(find.text('R4'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batalkan R4'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Batalkan R4').last);
    await tester.pumpAndSettle();
    expect(find.text('Round 3'), findsOneWidget);
    expect(primary(tester).label, 'Buat R4');
  });

  testWidgets('Round lewat: Istirahat tanpa prioritas; Akhiri → menu hanya Cara kerja, Pemain hilang', (tester) async {
    final visited = <String>[];
    await pumpRouted(tester, g, visited);
    await tester.tap(find.text('R2'));
    await tester.pumpAndSettle();
    expect(find.text('Istirahat'), findsOneWidget);
    expect(find.textContaining('Prioritas'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Akhiri turnamen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Akhiri'));
    await tester.pumpAndSettle();
    expect(visited, ['leaderboard']);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Pemain'), findsNothing);
    expect(primary(tester).label, 'Lanjutkan turnamen');
    await tester.tap(find.bySemanticsLabel('Menu'));
    await tester.pumpAndSettle();
    expect(find.text('Cara kerja Mixed'), findsOneWidget);
    expect(find.text('Akhiri turnamen'), findsNothing);
  });

  testWidgets('Court berkurang di round berikutnya: "Buat R… · 1 court"', (tester) async {
    final shortCourt = tournament([r1, r2, r3Done], adjust: wo);
    final config = shortCourt.config;
    final active = shortCourt.copyWith(
      tournament: shortCourt.tournament.copyWith(
        config: config.copyWith(courts: [config.courts[0], config.courts[1].copyWith(bookingDurationMinutes: 45)]),
      ),
    );
    await pumpRouted(tester, active, []);
    expect((primary(tester).label, primary(tester).meta), ('Buat R4', '· 1 court'));
  });

  testWidgets('Cara kerja Mixed muncul sendiri saat R1 dibuat', (tester) async {
    final config = f.config;
    tester.view.physicalSize = const Size(390, 844) * hifiPixelRatio;
    tester.view.devicePixelRatio = hifiPixelRatio;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(hifiScreen(ScheduleMixedScreen(config: config)));
    await tester.pumpAndSettle();
    expect(find.text('Cara kerja Mixed'), findsOneWidget);
    expect(find.text('Round 1'), findsOneWidget);
  });
}
