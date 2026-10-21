import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pembanding layar Flutter dengan frame hi-fi (`design/frames/<id>.png`).
///
/// Frame di-render `tool/hifi_extract.py` dari `design/hifi.html` pada 2x, jadi layar app berukuran
/// 390×844 pt = 780×1688 px. Di sini ukuran, rasio piksel, font Archivo, dan font ikon Phosphor Bold
/// disamakan; tanpa [loadHifiFonts] `flutter test` memakai Ahem dan hasilnya pasti beda total.
///
/// Anti-alias teks Chrome dan Skia tidak pernah identik, jadi piksel dihitung "beda" hanya kalau salah
/// satu kanalnya selisih lebih dari [HifiDiff.channelTolerance], dan layar lolos kalau rasio piksel beda
/// tidak melebihi `maxDiffRatio`. Kalau gagal, `build/hifi_diff/<id>.png` (merah = beda) dan
/// `build/hifi_diff/<id>_flutter.png` ditulis untuk dilihat.
const hifiScreenSize = Size(390, 844);
const hifiPixelRatio = 2.0;
const _fonts = {'Archivo': 'assets/fonts/Archivo[wdth,wght].ttf', 'PhosphorBold': 'assets/fonts/Phosphor-Bold.ttf'};

bool _fontsLoaded = false;

/// Memuat font Archivo variabel dan font ikon Phosphor Bold (`MabarIcons`) sekali per proses test.
/// Berat cukup lewat `fontWeight` (Flutter meneruskannya ke sumbu `wght`); lebar lewat
/// `FontVariation('wdth', n)` = `font-stretch: n%` di hi-fi.
Future<void> loadHifiFonts() async {
  if (_fontsLoaded) return;
  for (final MapEntry(key: family, value: path) in _fonts.entries) {
    final bytes = File(path).readAsBytesSync();
    await (FontLoader(family)..addFont(Future.value(ByteData.sublistView(bytes)))).load();
  }
  _fontsLoaded = true;
}

class HifiDiff {
  /// Selisih kanal (0–255) yang masih dianggap sama.
  static const channelTolerance = 32;

  final String frameId;
  final int width;
  final int height;
  final int differentPixels;

  const HifiDiff(this.frameId, this.width, this.height, this.differentPixels);

  double get ratio => differentPixels / (width * height);

  @override
  String toString() => '$frameId: ${(ratio * 100).toStringAsFixed(2)}% piksel beda ($differentPixels dari ${width * height})';
}

Future<ui.Image> _decode(Uint8List png) async {
  final codec = await ui.instantiateImageCodec(png);
  return (await codec.getNextFrame()).image;
}

Future<Uint8List> _rgba(ui.Image image) async =>
    (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!.buffer.asUint8List();

/// Gambar frame hi-fi apa adanya (untuk dibandingkan atau ditampilkan di test).
Future<ui.Image> hifiFrame(WidgetTester tester, String frameId) async =>
    (await tester.runAsync(() => _decode(File('design/frames/$frameId.png').readAsBytesSync())))!;

/// Me-render [screen] seukuran layar hi-fi lalu membandingkannya dengan `design/frames/<frameId>.png`.
/// [screen] harus sudah lengkap (MaterialApp, tema, data); helper ini hanya mengatur ukuran layar.
Future<HifiDiff> compareWithHifi(WidgetTester tester, Widget screen, String frameId) async {
  await loadHifiFonts();
  tester.view.physicalSize = hifiScreenSize * hifiPixelRatio;
  tester.view.devicePixelRatio = hifiPixelRatio;
  addTearDown(tester.view.reset);

  final key = GlobalKey();
  await tester.pumpWidget(RepaintBoundary(key: key, child: screen));
  await tester.pumpAndSettle();
  final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;

  return (await tester.runAsync(() async {
    final actual = await boundary.toImage(pixelRatio: hifiPixelRatio);
    final expected = await _decode(File('design/frames/$frameId.png').readAsBytesSync());
    if (actual.width != expected.width || actual.height != expected.height) {
      throw StateError('$frameId: ukuran render ${actual.width}×${actual.height} ≠ hi-fi ${expected.width}×${expected.height}');
    }
    final a = await _rgba(actual), e = await _rgba(expected);
    final diff = Uint8List(a.length);
    var different = 0;
    for (var i = 0; i < a.length; i += 4) {
      var worst = 0;
      for (var c = 0; c < 3; c++) {
        final d = (a[i + c] - e[i + c]).abs();
        if (d > worst) worst = d;
      }
      final isDifferent = worst > HifiDiff.channelTolerance;
      if (isDifferent) different++;
      // Gambar selisih: piksel beda merah, sisanya hi-fi dipudarkan supaya posisinya tetap terbaca.
      final grey = ((e[i] + e[i + 1] + e[i + 2]) ~/ 3) ~/ 3 + 170;
      diff[i] = isDifferent ? 230 : grey;
      diff[i + 1] = isDifferent ? 40 : grey;
      diff[i + 2] = isDifferent ? 40 : grey;
      diff[i + 3] = 255;
    }
    final result = HifiDiff(frameId, actual.width, actual.height, different);
    if (different > 0) await _writeDiff(frameId, actual, diff);
    return result;
  }))!;
}

/// [compareWithHifi] + `expect`. Toleransi bawaan 2% piksel: cukup untuk perbedaan anti-alias, tapi
/// pergeseran 4 pt atau warna yang salah di satu komponen sudah melewatinya.
Future<void> expectMatchesHifi(WidgetTester tester, Widget screen, String frameId, {double maxDiffRatio = 0.02}) async {
  final diff = await compareWithHifi(tester, screen, frameId);
  expect(diff.ratio, lessThanOrEqualTo(maxDiffRatio),
      reason: '$diff — lihat build/hifi_diff/$frameId.png (merah = beda) dan ${frameId}_flutter.png');
}

Future<void> _writeDiff(String frameId, ui.Image actual, Uint8List diffRgba) async {
  final dir = Directory('build/hifi_diff')..createSync(recursive: true);
  final png = await actual.toByteData(format: ui.ImageByteFormat.png);
  File('${dir.path}/${frameId}_flutter.png').writeAsBytesSync(png!.buffer.asUint8List());
  final buffer = await ui.ImmutableBuffer.fromUint8List(diffRgba);
  final descriptor = ui.ImageDescriptor.raw(buffer, width: actual.width, height: actual.height, pixelFormat: ui.PixelFormat.rgba8888);
  final image = (await (await descriptor.instantiateCodec()).getNextFrame()).image;
  final diffPng = await image.toByteData(format: ui.ImageByteFormat.png);
  File('${dir.path}/$frameId.png').writeAsBytesSync(diffPng!.buffer.asUint8List());
}
