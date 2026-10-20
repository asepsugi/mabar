import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/router/app_router.dart';
import 'core/theme/mabar_theme.dart';
import 'features/schedule/tournament_controller.dart';
import 'services/storage/tournament_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Tanggal di kartu hasil ditulis dalam bahasa Indonesia.
  initializeDateFormatting('id');

  // Seluruh layout mockup disusun untuk portrait; landscape tidak pernah didesain.
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  SystemChrome.setSystemUIOverlayStyle(MabarTheme.statusBarDark);

  runApp(
    ProviderScope(overrides: [tournamentStoreProvider.overrideWithValue(await _openStore())], child: const MabarApp()),
  );
}

/// Box Hive untuk turnamen. Kalau gagal dibuka (disk penuh, browser mode
/// private), app tetap jalan dengan penyimpanan memori — lebih baik kehilangan
/// resume daripada gagal start.
Future<TournamentStore> _openStore() async {
  try {
    await Hive.initFlutter();
    return TournamentStore(await Hive.openBox<String>(TournamentStore.boxName));
  } catch (_) {
    return TournamentStore.memory();
  }
}

class MabarApp extends StatelessWidget {
  const MabarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Mabar',
      debugShowCheckedModeBanner: false,
      theme: MabarTheme.light(),
      routerConfig: appRouter,
      // Default untuk semua layar. Beranda memasang region putih sendiri; tanpa
      // default ini gaya putihnya terbawa ke layar berikutnya (Flutter hanya
      // mengganti gaya status bar kalau menemukan region lain).
      builder: (context, child) =>
          AnnotatedRegion<SystemUiOverlayStyle>(value: MabarTheme.statusBarDark, child: child!),
    );
  }
}
