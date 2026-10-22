import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mabar/core/widgets/match_score_row.dart';
import 'package:mabar/core/widgets/mabar_controls.dart';
import 'package:mabar/features/schedule/schedule_fixed_screen.dart';
import 'package:mabar/features/schedule/tournament_controller.dart';
import 'package:mabar/models/models.dart';

import '../hifi_golden.dart';
import 'screen_harness.dart';

/// Turnamen yang sudah berjalan, seperti hasil resume: layar menerima config yang sama persis (identical),
/// jadi `startIfNeeded` tidak membuat jadwal baru.
class _Loaded extends TournamentController {
  final ActiveTournament active;
  _Loaded(this.active);

  @override
  ActiveTournament? build() => active;
}

/// Golden layar penuh Jadwal Fixed, frame 06a–06e. Tennis Race to 6, 10 pemain (5 pasangan), 2 court × 2 jam,
/// mulai 45 menit lalu. Jadwal round-robin sah (tiap pasangan istirahat sekali):
/// R1 A istirahat (B–C, D–E) · R2 E (A–B, C–D) · R3 D (A–C, B–E) · R4 B (A–D, C–E) · R5 C (A–E, B–D),
/// dengan A Andi·Budi, B Citra·Dewant, C Eko·Fajar, D Gina·Hana, E Indra·Joko.
void main() {
  const names = ['Andi P', 'Budi S', 'Citra L', 'Dewant R', 'Eko M', 'Fajar K', 'Gina R', 'Hana T', 'Indra W', 'Joko S'];
  final players = [for (var i = 0; i < names.length; i++) Player(id: 'p$i', name: names[i])];
  final pairs = [for (var i = 0; i < 5; i++) Pair(id: 'pair$i', player1Id: 'p${2 * i}', player2Id: 'p${2 * i + 1}')];
  final start = DateTime(2026, 10, 22, 19);
  final config = TournamentConfig(
    sport: SportType.tennis,
    mode: PartnerMode.fixed,
    matchDurationMinutes: 20,
    courts: const [
      Court(id: 'c1', name: 'Court 1', colorIndex: 0, bookingDurationMinutes: 120),
      Court(id: 'c2', name: 'Court 2', colorIndex: 1, bookingDurationMinutes: 120),
    ],
    players: players,
    fixedPairs: pairs,
  );
  // (pasangan istirahat, [pair1, pair2] court 1, [pair1, pair2] court 2) per round.
  const rounds = [
    (0, [1, 2], [3, 4]),
    (4, [0, 1], [2, 3]),
    (3, [0, 2], [1, 4]),
    (1, [0, 3], [2, 4]),
    (2, [0, 4], [1, 3]),
  ];

  /// [scores] per match id ("r2c1") = skor pair1–pair2; match lain pending, atau dibatalkan kalau [finished].
  ActiveTournament tournament(Map<String, (int, int)> scores, {bool finished = false}) {
    MatchGame match(int round, int court, List<int> p) {
      final id = 'r${round}c$court';
      final base = MatchGame(
        id: id,
        roundNumber: round,
        matchNumberInRound: court,
        courtId: 'c$court',
        pair1: pairs[p[0]],
        pair2: pairs[p[1]],
      );
      final score = scores[id];
      if (score != null) return base.withScore([SetScore(side1: score.$1, side2: score.$2)]);
      return finished ? base.copyWith(status: MatchStatus.cancelled) : base;
    }

    return ActiveTournament(
      tournament: Tournament(
        id: 't-fixed',
        createdAt: start,
        isFinished: finished,
        config: config,
        matches: [
          for (final (i, (_, c1, c2)) in rounds.indexed) ...[match(i + 1, 1, c1), match(i + 1, 2, c2)],
        ],
      ),
      byePairIdByRound: {for (final (i, (bye, _, _)) in rounds.indexed) i + 1: pairs[bye].id},
    );
  }

  final running = tournament({'r1c1': (6, 3), 'r1c2': (4, 6), 'r2c1': (6, 4)});
  final ended = tournament({
    for (var r = 1; r <= 4; r++) ...{'r${r}c1': (6, 2), 'r${r}c2': (3, 6)},
    'r5c1': (6, 5),
  }, finished: true);

  Widget screen(ActiveTournament active) {
    return hifiScreen(
      ScheduleFixedScreen(config: active.config),
      overrides: [
        tournamentProvider.overrideWith(() => _Loaded(active)),
        clockProvider.overrideWithValue(() => start.add(const Duration(minutes: 45))),
      ],
    );
  }

  testWidgets('06a round berjalan', (tester) async {
    await expectMatchesHifi(tester, screen(running), '06a');
  });

  testWidgets('06b round yang belum terbuka', (tester) async {
    await expectMatchesHifi(
      tester,
      screen(running),
      '06b',
      act: (tester) => tester.tap(find.text('R3')),
    );
  });

  // Beda disengaja: ⋯ digambar pudar (mati) karena satu-satunya item menu Fixed hilang setelah diakhiri;
  // frame menggambarnya aktif. Ditanyakan ke host.
  testWidgets('06c turnamen diakhiri', (tester) async {
    await expectMatchesHifi(tester, screen(ended), '06c');
  });

  testWidgets('06d menu ⋯', (tester) async {
    await expectMatchesHifi(
      tester,
      screen(running),
      '06d',
      act: (tester) => tester.tap(find.bySemanticsLabel('Menu')),
    );
  });

  testWidgets('06e dialog akhiri', (tester) async {
    await expectMatchesHifi(
      tester,
      screen(running),
      '06e',
      act: (tester) async {
        await tester.tap(find.bySemanticsLabel('Menu'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Akhiri turnamen'));
      },
    );
  });

  Future<void> pumpRouted(WidgetTester tester, ActiveTournament active, List<String> visited) async {
    tester.view.physicalSize = const Size(390, 844) * hifiPixelRatio;
    tester.view.devicePixelRatio = hifiPixelRatio;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: '/schedule',
      routes: [
        GoRoute(path: '/schedule', builder: (_, _) => ScheduleFixedScreen(config: active.config)),
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
    await tester.pumpWidget(hifiRouterScreen(router, overrides: [tournamentProvider.overrideWith(() => _Loaded(active))]));
    await tester.pumpAndSettle();
  }

  testWidgets('Round terkunci tidak bisa diketuk; round sebelumnya tetap bisa diubah', (tester) async {
    final visited = <String>[];
    await pumpRouted(tester, running, visited);
    await tester.tap(find.text('R3'));
    await tester.pumpAndSettle();
    expect(find.text('Isi skor'), findsNothing);
    await tester.tap(find.text('Andi · Budi'));
    await tester.pumpAndSettle();
    expect(visited, isEmpty);

    await tester.tap(find.text('R1'));
    await tester.pumpAndSettle();
    expect(find.text('Round 1'), findsOneWidget);
    await tester.tap(find.text('Citra · Dewant'));
    await tester.pumpAndSettle();
    expect(visited, ['score:r1c1']);
  });

  testWidgets('Akhiri: match kosong tidak dimainkan, buka Peringkat, item menu hilang', (tester) async {
    final visited = <String>[];
    await pumpRouted(tester, running, visited);
    await tester.tap(find.bySemanticsLabel('Menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Akhiri turnamen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Akhiri'));
    await tester.pumpAndSettle();
    expect(visited, ['leaderboard']);

    final element = tester.element(find.byType(ScheduleFixedScreen, skipOffstage: false));
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    expect(element.mounted, isTrue);
    expect(find.text('Tennis · Race to 6 · diakhiri'), findsOneWidget);
    // Tab default = round terakhir setelah diakhiri; R5 belum dimainkan sama sekali.
    expect(find.text('Round 5'), findsOneWidget);
    expect(find.text('Tidak dimainkan'), findsNWidgets(2));
    expect(find.text('Lihat peringkat'), findsOneWidget);
    expect(tester.widget<MabarIconButton>(find.byType(MabarIconButton).last).onPressed, isNull);
    expect(tester.widget<MatchScoreRow>(find.byType(MatchScoreRow).last).onTap, isNull);
  });
}
