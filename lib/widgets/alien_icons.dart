import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Glowing Alien Head Emblem matching the Alienware Cyberpunk UI
class AlienEmblem extends StatelessWidget {
  final double size;
  final Color glowColor;
  final bool hasGlow;

  const AlienEmblem({
    super.key,
    this.size = 32,
    this.glowColor = const Color(0xFF00FF66),
    this.hasGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: hasGlow
          ? BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: glowColor.withOpacity(0.45),
                  blurRadius: size * 0.45,
                  spreadRadius: size * 0.1,
                ),
              ],
            )
          : null,
      child: CustomPaint(
        size: Size(size, size),
        painter: _AlienEmblemPainter(color: glowColor),
      ),
    );
  }
}

class _AlienEmblemPainter extends CustomPainter {
  final Color color;

  _AlienEmblemPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Alien Head Contour Path
    final headPath = Path();
    headPath.moveTo(w * 0.5, h * 0.05); // Top center
    // Top-right curve
    headPath.cubicTo(w * 0.85, h * 0.05, w * 0.95, h * 0.35, w * 0.88, h * 0.60);
    // Right cheek down to chin
    headPath.cubicTo(w * 0.82, h * 0.78, w * 0.62, h * 0.95, w * 0.5, h * 0.98);
    // Chin up left cheek
    headPath.cubicTo(w * 0.38, h * 0.95, w * 0.18, h * 0.78, w * 0.12, h * 0.60);
    // Left curve to top
    headPath.cubicTo(w * 0.05, h * 0.35, w * 0.15, h * 0.05, w * 0.5, h * 0.05);
    headPath.close();

    // Head Fill (Gradient)
    final fillPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withOpacity(0.9),
          color.withOpacity(0.4),
          const Color(0xFF021206),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(headPath, fillPaint);

    // Head Outline
    final outlinePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, w * 0.04);
    canvas.drawPath(headPath, outlinePaint);

    // Left Eye (Tilted Almond)
    final leftEyePath = Path();
    leftEyePath.moveTo(w * 0.28, h * 0.38);
    leftEyePath.cubicTo(w * 0.38, h * 0.30, w * 0.44, h * 0.44, w * 0.42, h * 0.58);
    leftEyePath.cubicTo(w * 0.36, h * 0.66, w * 0.22, h * 0.54, w * 0.28, h * 0.38);
    leftEyePath.close();

    // Right Eye (Tilted Almond)
    final rightEyePath = Path();
    rightEyePath.moveTo(w * 0.72, h * 0.38);
    rightEyePath.cubicTo(w * 0.62, h * 0.30, w * 0.56, h * 0.44, w * 0.58, h * 0.58);
    rightEyePath.cubicTo(w * 0.64, h * 0.66, w * 0.78, h * 0.54, w * 0.72, h * 0.38);
    rightEyePath.close();

    // Eyes Fill (Deep obsidian void)
    final eyePaint = Paint()
      ..color = const Color(0xFF020803)
      ..style = PaintingStyle.fill;
    canvas.drawPath(leftEyePath, eyePaint);
    canvas.drawPath(rightEyePath, eyePaint);

    // Eyes Inner Glow
    final eyeOutlinePaint = Paint()
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, w * 0.025);
    canvas.drawPath(leftEyePath, eyeOutlinePaint);
    canvas.drawPath(rightEyePath, eyeOutlinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Circular Holographic Radar / Reticle Target
class HudRadarCircle extends StatelessWidget {
  final double size;
  final Widget? child;
  final Color color;

  const HudRadarCircle({
    super.key,
    required this.size,
    this.child,
    this.color = const Color(0xFF00FF66),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _HudRadarPainter(color: color),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _HudRadarPainter extends CustomPainter {
  final Color color;

  _HudRadarPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer Ring
    final outerRing = Paint()
      ..color = color.withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius - 2, outerRing);

    // Arc Segments (HUD reticle brackets)
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Top-left arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      -math.pi * 0.75,
      math.pi * 0.4,
      false,
      arcPaint,
    );
    // Bottom-right arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      math.pi * 0.25,
      math.pi * 0.4,
      false,
      arcPaint,
    );

    // Inner Dashed Ring
    final innerRing = Paint()
      ..color = color.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(center, radius * 0.75, innerRing);

    // Mini crosshairs tick marks
    final tickPaint = Paint()
      ..color = color.withOpacity(0.7)
      ..strokeWidth = 1.2;

    canvas.drawLine(
      Offset(center.dx, 1),
      Offset(center.dx, 5),
      tickPaint,
    );
    canvas.drawLine(
      Offset(center.dx, size.height - 5),
      Offset(center.dx, size.height - 1),
      tickPaint,
    );
    canvas.drawLine(
      Offset(1, center.dy),
      Offset(5, center.dy),
      tickPaint,
    );
    canvas.drawLine(
      Offset(size.width - 5, center.dy),
      Offset(size.width - 1, center.dy),
      tickPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
