import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/home_screen.dart';
import '../../features/konfigurasi/konfigurasi_screen.dart';
import '../../features/pair_setup/pair_setup_screen.dart';
import '../../features/detail_player/detail_player_screen.dart';
import '../../features/leaderboard/leaderboard_screen.dart';
import '../../features/live/live_screen.dart';
import '../../features/schedule/schedule_fixed_screen.dart';
import '../../features/schedule/schedule_mixed_screen.dart';
import '../../features/share/share_result_screen.dart';
import '../../features/score_input/score_input_screen.dart';
import '../../features/setup_peserta/setup_peserta_screen.dart';
import '../../models/models.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    GoRoute(
      path: '/setup-peserta',
      builder: (_, state) {
        final sport = state.extra as SportType;
        return SetupPesertaScreen(sport: sport);
      },
    ),
    GoRoute(
      path: '/konfigurasi',
      builder: (_, state) {
        final (sport, players) = state.extra as (SportType, List<Player>);
        return KonfigurasiScreen(sport: sport, players: players);
      },
    ),
    GoRoute(
      path: '/pair-setup',
      builder: (_, state) => PairSetupScreen(config: state.extra as TournamentConfig),
    ),
    GoRoute(
      path: '/schedule',
      builder: (_, state) {
        final config = state.extra as TournamentConfig;
        return config.mode == PartnerMode.fixed
            ? ScheduleFixedScreen(config: config)
            : ScheduleMixedScreen(config: config);
      },
    ),
    GoRoute(
      path: '/score-input',
      builder: (_, state) => ScoreInputScreen(matchId: state.extra as String),
    ),
    GoRoute(path: '/leaderboard', builder: (_, __) => const LeaderboardScreen()),
    GoRoute(
      path: '/detail-player',
      builder: (_, state) => DetailPlayerScreen(playerId: state.extra as String),
    ),
    GoRoute(path: '/share', builder: (_, __) => const ShareResultScreen()),
    // Halaman penonton; kodenya dibaca `main()` dari URL (liveCodeProvider), bukan dari parameter ini.
    GoRoute(path: '/live/:code', builder: (_, __) => const LiveScreen()),
  ],
  errorBuilder: (_, state) => Scaffold(body: Center(child: Text('Halaman tidak ditemukan'))),
);
