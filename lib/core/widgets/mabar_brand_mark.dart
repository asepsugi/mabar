import 'package:flutter/material.dart';

/// Lapangan biru + garis court + bola tennis — bagian visual dari hero Home
/// (`.brand-hero` di mockup) yang juga dipakai sebagai icon aplikasi.
///
/// Dipisah ke sini supaya icon launcher dan judul di layar utama tidak pernah
/// jadi dua gambar yang berbeda; generator icon (`tool/generate_app_icon.dart`)
/// me-render widget yang sama persis.
class MabarCourtBackground extends StatelessWidget {
  final Widget? child;
  const MabarCourtBackground({super.key, this.child});

  /// Gradien lapangan; `courtBlue` juga dipakai sebagai latar adaptive icon.
  static const courtBlue = Color(0xFF1E6BB8);
  static const courtBlueLight = Color(0xFF2F8FD4);

  static const gradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [courtBlue, courtBlueLight],
  );

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: gradient),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.hardEdge,
        children: [
          const Positioned.fill(
            child: Opacity(opacity: 0.35, child: CustomPaint(painter: MabarCourtLinesPainter())),
          ),
          // Sun glare
          Positioned(
            top: -20,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [Color(0x38FFFFFF), Color(0x00FFFFFF)], stops: [0.0, 0.65]),
              ),
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

/// Bola tennis dengan dua jahitan — svg 48×48 di mockup, diskalakan ke [size].
class MabarTennisBall extends StatelessWidget {
  final double size;

  /// Bayangan dimatikan saat bola dipakai sebagai foreground adaptive icon:
  /// Android menerapkan bayangannya sendiri.
  final bool shadow;

  const MabarTennisBall({super.key, this.size = 48, this.shadow = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: shadow
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    offset: Offset(0, size * 0.125),
                    blurRadius: size / 3,
                  ),
                ]
              : null,
        ),
        child: const CustomPaint(painter: MabarTennisBallPainter()),
      ),
    );
  }
}

class MabarTennisBallPainter extends CustomPainter {
  const MabarTennisBallPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Bola digambar di viewport 48×48 (sama dengan svg di hifi), lalu diskalakan.
    final s = size.width / 48;
    final r = 21 * s;
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawCircle(center, r, Paint()..color = const Color(0xFFCDE84A));
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = const Color(0xFFA8C233)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1 * s,
    );

    final seamPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * s
      ..strokeCap = StrokeCap.round;
    final p1 = Path()
      ..moveTo(6 * s, 15 * s)
      ..cubicTo(14 * s, 20 * s, 20 * s, 26 * s, 20 * s, 42 * s);
    final p2 = Path()
      ..moveTo(42 * s, 33 * s)
      ..cubicTo(34 * s, 28 * s, 28 * s, 22 * s, 28 * s, 6 * s);
    canvas.drawPath(p1, seamPaint);
    canvas.drawPath(p2, seamPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MabarCourtLinesPainter extends CustomPainter {
  const MabarCourtLinesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // viewBox 0 0 300 220 dengan preserveAspectRatio=none → skala x & y independen.
    final sx = size.width / 300;
    final sy = size.height / 220;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12 * ((sx + sy) / 2)
      ..strokeCap = StrokeCap.round;

    Offset p(double x, double y) => Offset(x * sx, y * sy);

    canvas.drawLine(p(-5, 70), p(210, 44), paint); // baseline
    canvas.drawLine(p(210, 44), p(305, 32), paint); // service line
    canvas.drawLine(p(210, 44), p(238, 240), paint); // sideline
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
