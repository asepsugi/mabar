import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mabar/core/widgets/mabar_brand_mark.dart';

/// Membuat sumber icon aplikasi dari brand mark yang sama dengan hero Home.
///
/// Bukan test — ini generator sekali jalan, ditaruh di `tool/` supaya tidak ikut
/// `flutter test`. Jalankan ulang setiap kali brand mark berubah:
///
///   flutter test tool/generate_app_icon.dart
///   dart run flutter_launcher_icons
///
/// Hasilnya tiga PNG 1024×1024 di `assets/icon/`: icon utuh (iOS & fallback),
/// latar dan foreground terpisah untuk adaptive icon Android.
void main() {
  const size = 1024.0;

  testWidgets('render sumber icon', (tester) async {
    await _capture(
      tester,
      'assets/icon/app_icon.png',
      const SizedBox(
        width: size,
        height: size,
        child: MabarCourtBackground(
          child: MabarTennisBall(size: size * 0.52),
        ),
      ),
    );

    await _capture(
      tester,
      'assets/icon/app_icon_background.png',
      const SizedBox(width: size, height: size, child: MabarCourtBackground()),
    );

    // Adaptive icon memangkas ~25% tiap sisi, jadi bolanya dibuat lebih kecil
    // dari versi utuh supaya tidak terpotong mask bulat/squircle.
    await _capture(
      tester,
      'assets/icon/app_icon_foreground.png',
      const SizedBox(
        width: size,
        height: size,
        child: Center(child: MabarTennisBall(size: size * 0.40, shadow: false)),
      ),
    );
  });
}

Future<void> _capture(WidgetTester tester, String path, Widget child) async {
  // Surface test default 800×600 memotong kanvas 1024 persegi.
  await tester.binding.setSurfaceSize(const Size(1024, 1024));

  final key = GlobalKey();
  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: RepaintBoundary(key: key, child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path).writeAsBytesSync(data!.buffer.asUint8List());
  });

  debugPrint('wrote $path');
}
