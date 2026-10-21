import 'package:flutter/widgets.dart';

import '../theme/mabar_theme.dart';

/// Bola tennis brand (sprite `#ball` hi-fi, viewBox 48): lingkaran bola bertepi, dua jahitan putih.
/// Dipakai wordmark Beranda dan poster Bagikan; gambar brand, bukan ikon.
class MabarBall extends StatelessWidget {
  final double size;

  const MabarBall({super.key, required this.size});

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: const _BallPainter());
}

class _BallPainter extends CustomPainter {
  const _BallPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 48);
    canvas.drawCircle(const Offset(24, 24), 21, Paint()..color = MabarColors.ball);
    canvas.drawCircle(
      const Offset(24, 24),
      21,
      Paint()
        ..color = MabarColors.ballEdge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final seam = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()..moveTo(6, 15)..cubicTo(14, 20, 20, 26, 20, 42), seam);
    canvas.drawPath(Path()..moveTo(42, 33)..cubicTo(34, 28, 28, 22, 28, 6), seam);
  }

  @override
  bool shouldRepaint(_BallPainter oldDelegate) => false;
}
