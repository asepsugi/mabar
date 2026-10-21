import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'hifi_golden.dart';

/// Memastikan alat pembanding hi-fi sendiri benar sebelum dipakai untuk layar sungguhan
/// (lihat design/spec/README.md). Layar app belum dibandingkan di sini karena desain v2 belum diimplementasi.
double _width(TextStyle style) =>
    (TextPainter(text: TextSpan(text: 'Round 3', style: style), textDirection: TextDirection.ltr)..layout()).width;

void main() {
  testWidgets('frame hi-fi yang ditampilkan ulang identik dengan dirinya', (tester) async {
    final frame = await hifiFrame(tester, '03a');
    final diff = await compareWithHifi(
      tester,
      RawImage(image: frame, width: hifiScreenSize.width, height: hifiScreenSize.height, fit: BoxFit.fill, filterQuality: FilterQuality.none),
      '03a',
    );
    expect(diff.differentPixels, 0, reason: '$diff');
  });

  testWidgets('layar yang salah terdeteksi', (tester) async {
    final diff = await compareWithHifi(tester, const ColoredBox(color: Color(0xFFEEF2F5)), '03a');
    expect(diff.ratio, greaterThan(0.05), reason: '$diff');
  });

  test('Archivo variabel: wdth dan wght bekerja di flutter_test', () async {
    await loadArchivo();
    const base = TextStyle(fontFamily: 'Archivo', fontSize: 54, fontWeight: FontWeight.w800);
    final condensed = _width(base.copyWith(fontVariations: const [ui.FontVariation('wdth', 72)]));
    final normal = _width(base);
    final wide = _width(base.copyWith(fontVariations: const [ui.FontVariation('wdth', 125)]));
    expect(condensed, lessThan(normal));
    expect(wide, greaterThan(normal));
    // fontWeight diteruskan ke sumbu wght, jadi tidak perlu FontVariation('wght', ...).
    expect(_width(base.copyWith(fontWeight: FontWeight.w400)), lessThan(normal));
  });
}
