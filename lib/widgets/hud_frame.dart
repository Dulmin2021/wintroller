import 'package:flutter/material.dart';

/// Futuristic Chamfered Cyberpunk HUD Frame with Glowing Corner Brackets & Notches
class HudFrame extends StatelessWidget {
  final Widget child;
  final double chamferSize;
  final Color borderColor;
  final Color backgroundColor;
  final double borderWidth;
  final bool showGlow;
  final bool showCornerBrackets;
  final EdgeInsetsGeometry padding;

  const HudFrame({
    super.key,
    required this.child,
    this.chamferSize = 14.0,
    this.borderColor = const Color(0xFF00FF66),
    this.backgroundColor = const Color(0xFF08180B),
    this.borderWidth = 1.0,
    this.showGlow = true,
    this.showCornerBrackets = true,
    this.padding = const EdgeInsets.all(16.0),
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HudFramePainter(
        chamferSize: chamferSize,
        borderColor: borderColor,
        backgroundColor: backgroundColor,
        borderWidth: borderWidth,
        showGlow: showGlow,
        showCornerBrackets: showCornerBrackets,
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}

class _HudFramePainter extends CustomPainter {
  final double chamferSize;
  final Color borderColor;
  final Color backgroundColor;
  final double borderWidth;
  final bool showGlow;
  final bool showCornerBrackets;

  _HudFramePainter({
    required this.chamferSize,
    required this.borderColor,
    required this.backgroundColor,
    required this.borderWidth,
    required this.showGlow,
    required this.showCornerBrackets,
  });

  Path _createChamferedPath(Size size) {
    final w = size.width;
    final h = size.height;
    final c = chamferSize;

    final path = Path();
    path.moveTo(c, 0); // Top-left chamfer start
    path.lineTo(w - c, 0); // Top edge
    path.lineTo(w, c); // Top-right chamfer
    path.lineTo(w, h - c); // Right edge
    path.lineTo(w - c, h); // Bottom-right chamfer
    path.lineTo(c, h); // Bottom edge
    path.lineTo(0, h - c); // Bottom-left chamfer
    path.lineTo(0, c); // Left edge
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _createChamferedPath(size);

    // 1. Draw Background Fill (Subtle Matrix Gradient)
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          backgroundColor.withOpacity(0.95),
          const Color(0xFF030A04).withOpacity(0.98),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 2. Outer Glow Shadow
    if (showGlow) {
      final glowPaint = Paint()
        ..color = borderColor.withOpacity(0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth * 2.5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawPath(path, glowPaint);
    }

    // 3. Main Outline Border
    final borderPaint = Paint()
      ..color = borderColor.withOpacity(0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
    canvas.drawPath(path, borderPaint);

    // 4. Glowing Corner Brackets & Tech Accents
    if (showCornerBrackets) {
      final bracketPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth + 1.2;

      final w = size.width;
      final h = size.height;
      final c = chamferSize;
      final arm = c * 0.8;

      // Top-Left Bracket
      final tl = Path()
        ..moveTo(0, c + arm)
        ..lineTo(0, c)
        ..lineTo(c, 0)
        ..lineTo(c + arm, 0);
      canvas.drawPath(tl, bracketPaint);

      // Top-Right Bracket
      final tr = Path()
        ..moveTo(w - c - arm, 0)
        ..lineTo(w - c, 0)
        ..lineTo(w, c)
        ..lineTo(w, c + arm);
      canvas.drawPath(tr, bracketPaint);

      // Bottom-Left Bracket
      final bl = Path()
        ..moveTo(0, h - c - arm)
        ..lineTo(0, h - c)
        ..lineTo(c, h)
        ..lineTo(c + arm, h);
      canvas.drawPath(bl, bracketPaint);

      // Bottom-Right Bracket
      final br = Path()
        ..moveTo(w - c - arm, h)
        ..lineTo(w - c, h)
        ..lineTo(w, h - c)
        ..lineTo(w, h - c - arm);
      canvas.drawPath(br, bracketPaint);

      // Tech Notch Tick on Top & Bottom Center
      final tickPaint = Paint()
        ..color = borderColor.withOpacity(0.9)
        ..strokeWidth = 2.0;

      canvas.drawLine(
        Offset(w * 0.5 - 12, 0),
        Offset(w * 0.5 + 12, 0),
        tickPaint,
      );
      canvas.drawLine(
        Offset(w * 0.5 - 12, h),
        Offset(w * 0.5 + 12, h),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
