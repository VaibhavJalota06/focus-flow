import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Crisp vector-rendered official Google 4-Color 'G' Logo
class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cx = w / 2;
    final double cy = h / 2;
    final double radius = w * 0.46;
    final double strokeWidth = w * 0.20;

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: radius - (strokeWidth / 2));

    // Colors according to official Google Brand Guidelines
    const blue = Color(0xFF4285F4);
    const green = Color(0xFF34A853);
    const yellow = Color(0xFFFBBC05);
    const red = Color(0xFFEA4335);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // 1. Red Top Arc (~ -45 deg to 55 deg equivalent / counter-clockwise)
    paint.color = red;
    canvas.drawArc(rect, -math.pi * 0.75, math.pi * 0.52, false, paint);

    // 2. Yellow Left Arc
    paint.color = yellow;
    canvas.drawArc(rect, -math.pi * 1.23, math.pi * 0.48, false, paint);

    // 3. Green Bottom Arc
    paint.color = green;
    canvas.drawArc(rect, math.pi * 0.25, math.pi * 0.52, false, paint);

    // 4. Blue Right Arc
    paint.color = blue;
    canvas.drawArc(rect, -math.pi * 0.23, math.pi * 0.48, false, paint);

    // 5. Blue Horizontal Crossbar
    final barPaint = Paint()
      ..color = blue
      ..style = PaintingStyle.fill;

    final barHeight = strokeWidth;
    final barWidth = radius + (strokeWidth / 2);
    final barRect = Rect.fromLTWH(
      cx,
      cy - (barHeight / 2),
      barWidth * 0.95,
      barHeight,
    );
    canvas.drawRect(barRect, barPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
