import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mabar/core/theme/mabar_theme.dart';

import '../hifi_golden.dart';

/// Layar penuh untuk golden: tema v2, safe area frame (47/34), provider yang di-override.
Widget hifiScreen(Widget home, {List<Override> overrides = const []}) => ProviderScope(
  overrides: overrides,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: MabarTheme.light(),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(padding: hifiSafeArea, viewPadding: hifiSafeArea),
      child: child!,
    ),
    home: home,
  ),
);
