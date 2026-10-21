import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import '../../models/models.dart';
import '../theme/mabar_theme.dart';

/// Ukuran gambar lapangan untuk satu pemakaian. Semua jarak lapangan dihitung dalam meter dari sudut
/// kanan atas permukaan (sideline luar × baseline/dinding belakang), dikali [scale].
class CourtLayout {
  /// Jarak sudut dari tepi kanan dan tepi atas kanvas, dalam satuan desain.
  final double cornerRight, cornerTop;

  /// Satuan desain per meter.
  final double scale;
  final double baselineWidth, lineWidth;

  /// Panjang center mark tennis di baseline.
  final double centerMark;

  /// Opasitas seluruh lapisan garis (`.marks`); 1 = tanpa `saveLayer`.
  final double marksOpacity;

  /// Lebar kanvas desain; null = 1 satuan = 1 pt (banner). Ikon digambar di kanvas 1024 lalu diskalakan.
  final double? designWidth;

  const CourtLayout({
    required this.cornerRight,
    required this.cornerTop,
    required this.scale,
    required this.baselineWidth,
    required this.lineWidth,
    required this.centerMark,
    required this.marksOpacity,
    this.designWidth,
  });

  /// Banner Beranda: 60 pt = 1 m, sudut di x = lebar − 34, y = 104 (status bar 47 di frame). Garis
  /// dipertebal lalu dipudarkan ke 35% sebagai satu lapisan.
  static const banner = CourtLayout(
    cornerRight: 34,
    cornerTop: 104,
    scale: 60,
    baselineWidth: 7,
    lineWidth: 4.5,
    centerMark: 14,
    marksOpacity: 0.35,
  );

  /// Ikon app opsi A (`#appicon-a`, kanvas 1024): garis putih penuh, skala 120 per meter.
  static const icon = CourtLayout(
    cornerRight: 164,
    cornerTop: 210,
    scale: 120,
    baselineWidth: 30,
    lineWidth: 20,
    centerMark: 40,
    marksOpacity: 1,
    designWidth: 1024,
  );

  CourtLayout withTop(double top) => CourtLayout(
    cornerRight: cornerRight,
    cornerTop: top,
    scale: scale,
    baselineWidth: baselineWidth,
    lineWidth: lineWidth,
    centerMark: centerMark,
    marksOpacity: marksOpacity,
    designWidth: designWidth,
  );
}

/// Sudut lapangan tampak atas (`.court-band svg.lines`), proporsi asli. [t] = posisi garis dari tennis
/// (0) ke padel (1) — frame 01g; banner menganimasikannya, ikon app selalu 0.
///
/// Warna permukaan tidak dicampur: warna olahraga [toward] menyapu dari dinding belakang ke bawah
/// dengan tepi tegas sejauh [t] menuju olahraga itu, di atas warna olahraga asal. Run-off tetap.
class CourtPainter extends CustomPainter {
  final double t;
  final SportType toward;
  final CourtLayout layout;

  const CourtPainter({required this.t, required this.toward, this.layout = CourtLayout.banner});

  /// Gambar diam satu olahraga.
  CourtPainter.of(SportType sport, {this.layout = CourtLayout.banner})
    : t = sport == SportType.padel ? 1 : 0,
      toward = sport;

  // Tennis: alley 1,37 m, service line 5,485 m dari baseline, center line 4,115 m dari singles
  // sideline. Padel: lebar separuh 5 m, service line 3,05 m dari dinding, center line menonjol 20 cm.
  static const _alley = 1.37, _tennisService = 5.485, _tennisCenter = 1.37 + 4.115;
  static const _padelService = 3.05, _padelCenter = 5.0, _padelCenterOver = 0.2, _panel = 2.0;

  static Color surfaceOf(SportType sport) => sport == SportType.padel ? MabarColors.padel : MabarColors.court;

  @override
  void paint(Canvas canvas, Size size) {
    var width = size.width, height = size.height;
    final design = layout.designWidth;
    if (design != null) {
      canvas.scale(size.width / design);
      height = height * design / size.width;
      width = design;
    }
    final m = layout.scale;
    final cx = width - layout.cornerRight, cy = layout.cornerTop;
    // Satuan gambar padel (kaca, tiang, jaring) ditulis dalam pt banner.
    final k = m / 60;
    final far = -width; // ujung kiri garis & permukaan, cukup jauh di luar kanvas
    final bottom = height + layout.lineWidth;

    canvas.clipRect(Offset.zero & Size(width, height));
    canvas.drawColor(MabarColors.courtDeep, BlendMode.src);

    final from = toward == SportType.padel ? SportType.tennis : SportType.padel;
    final sweep = toward == SportType.padel ? t : 1 - t;
    final surface = Rect.fromLTRB(far, cy, cx, bottom);
    canvas.drawRect(surface, Paint()..color = surfaceOf(from));
    if (sweep > 0) {
      canvas.drawRect(
        Rect.fromLTRB(far, cy, cx, cy + sweep * (bottom - cy)),
        Paint()..color = surfaceOf(toward),
      );
    }

    // Satu lapisan beropasitas di atas warna court, bukan opasitas per garis: persilangan tidak menebal.
    final layered = layout.marksOpacity < 1;
    if (layered) {
      canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, layout.marksOpacity));
    }

    final white = const Color(0xFFFFFFFF);
    Paint stroke(double width, [double opacity = 1]) => Paint()
      ..color = white.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..strokeWidth = width;

    // Kaca, tiang, jaring padel muncul di 60% terakhir.
    final glass = ((t - 0.4) / 0.6).clamp(0.0, 1.0);
    if (glass > 0) {
      final fill = Paint()..color = white.withValues(alpha: 0.3 * glass);
      canvas.drawRect(Rect.fromLTRB(far, cy - 14 * k, cx + 14 * k, cy), fill);
      canvas.drawRect(Rect.fromLTRB(cx, cy - 14 * k, cx + 14 * k, cy + _panel * m), fill);
      canvas.drawRect(
        Rect.fromLTRB(cx, cy + _panel * m, cx + 14 * k, cy + 2 * _panel * m),
        Paint()..color = white.withValues(alpha: 0.18 * glass),
      );
    }

    // Baseline → tepi dinding, sideline luar → tepi kaca samping: menipis dan sedikit pudar. Dua garis
    // dalam satu lapisan supaya sudutnya tidak tumpuk saat beropasitas.
    canvas.saveLayer(null, Paint()..color = white.withValues(alpha: lerpDouble(1, 0.85, t)!));
    canvas.drawLine(Offset(far, cy), Offset(cx, cy), stroke(lerpDouble(layout.baselineWidth, 2 * k, t)!));
    canvas.drawLine(Offset(cx, cy), Offset(cx, bottom), stroke(lerpDouble(layout.lineWidth, 2 * k, t)!));
    canvas.restore();

    if (glass > 0) {
      // Jaring di sisi setelah 4 m: titik-titik (`stroke-dasharray 1 7`, ujung bulat).
      final mesh = Paint()
        ..color = white.withValues(alpha: 0.55 * glass)
        ..strokeWidth = 3 * k
        ..strokeCap = StrokeCap.round;
      for (var y = cy + 2 * _panel * m + 6 * k; y <= height; y += 8 * k) {
        canvas.drawLine(Offset(cx + 7 * k, y), Offset(cx + 7 * k, y + k), mesh);
      }
      // Tiang tiap panel 2 m, di tengah tebal kaca.
      final post = Paint()..color = MabarColors.ink.withValues(alpha: 0.55 * glass);
      final mid = cy - 7 * k, side = cx + 7 * k;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(side, mid), width: 20 * k, height: 20 * k), Radius.circular(2 * k)),
        post,
      );
      for (var x = cx - _panel * m; x > -3 * k; x -= _panel * m) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, mid), width: 6 * k, height: 18 * k), Radius.circular(k)),
          post,
        );
      }
      for (var y = cy + _panel * m; y - 3 * k < height; y += _panel * m) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(side, y), width: 18 * k, height: 6 * k), Radius.circular(k)),
          post,
        );
      }
    }

    final line = stroke(layout.lineWidth);
    // Singles sideline menyatu ke sideline luar lalu hilang.
    if (t < 1) {
      final x = cx - lerpDouble(_alley, 0, t)! * m;
      canvas.drawLine(Offset(x, cy), Offset(x, bottom), stroke(layout.lineWidth, 1 - t));
    }
    final serviceY = cy + lerpDouble(_tennisService, _padelService, t)! * m;
    final serviceEnd = lerpDouble(cx - _alley * m, cx - 2 * k, t)!;
    canvas.drawLine(Offset(far, serviceY), Offset(serviceEnd, serviceY), line);
    final centerX = cx - lerpDouble(_tennisCenter, _padelCenter, t)! * m;
    canvas.drawLine(Offset(centerX, serviceY - t * _padelCenterOver * m), Offset(centerX, bottom), line);
    if (t < 1) {
      canvas.drawLine(Offset(centerX, cy), Offset(centerX, cy + layout.centerMark), stroke(layout.lineWidth, 1 - t));
    }

    if (layered) canvas.restore();
  }

  @override
  bool shouldRepaint(CourtPainter old) => old.t != t || old.toward != toward || old.layout != layout;
}
