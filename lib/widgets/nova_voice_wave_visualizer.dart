import 'dart:math' as math;
import 'package:flutter/material.dart';

class NovaVoiceWaveVisualizer extends StatefulWidget {
  final double soundLevel;
  final bool isListening;
  final bool isSpeaking;
  final Color primaryColor;
  final double height;

  const NovaVoiceWaveVisualizer({
    super.key,
    required this.soundLevel,
    required this.isListening,
    required this.isSpeaking,
    this.primaryColor = const Color(0xFF00FF66),
    this.height = 140,
  });

  @override
  State<NovaVoiceWaveVisualizer> createState() => _NovaVoiceWaveVisualizerState();
}

class _NovaVoiceWaveVisualizerState extends State<NovaVoiceWaveVisualizer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: _NovaShaderWavePainter(
            time: _controller.value * 2 * math.pi,
            soundLevel: widget.soundLevel,
            isListening: widget.isListening,
            isSpeaking: widget.isSpeaking,
            primaryColor: widget.primaryColor,
          ),
        );
      },
    );
  }
}

class _NovaShaderWavePainter extends CustomPainter {
  final double time;
  final double soundLevel;
  final bool isListening;
  final bool isSpeaking;
  final Color primaryColor;

  _NovaShaderWavePainter({
    required this.time,
    required this.soundLevel,
    required this.isListening,
    required this.isSpeaking,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final width = size.width;
    final height = size.height;

    // 1. Draw subtle HUD grid background
    final gridPaint = Paint()
      ..color = primaryColor.withOpacity(0.04)
      ..strokeWidth = 0.5;

    for (double y = 0; y <= height; y += 14) {
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }
    for (double x = 0; x <= width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, height), gridPaint);
    }

    // 2. Central Pulsing Radial Glow (Core from Stitch shader)
    final pulseScale = isListening
        ? 1.0 + (soundLevel.clamp(0.0, 10.0) / 12.0)
        : (isSpeaking ? 1.1 + 0.15 * math.sin(time * 3) : 0.8 + 0.2 * math.sin(time * 2));

    final coreRadius = (35.0 * pulseScale).clamp(20.0, 70.0);
    final coreGradient = RadialGradient(
      colors: [
        primaryColor.withOpacity(isListening ? 0.35 : 0.20),
        primaryColor.withOpacity(isListening ? 0.12 : 0.05),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final corePaint = Paint()
      ..shader = coreGradient.createShader(
        Rect.fromCircle(center: center, radius: coreRadius),
      );
    canvas.drawCircle(center, coreRadius, corePaint);

    // 3. Multi-Harmonic Sine Waves (5 distinct layers directly matching Stitch WebGL shader)
    final activeMultiplier = isListening
        ? (1.0 + (soundLevel.clamp(0.0, 10.0) / 4.0))
        : (isSpeaking ? 1.4 : 0.5);

    const int waveCount = 5;
    for (int i = 0; i < waveCount; i++) {
      final speed = time * (1.5 + i * 0.25);
      final baseAmplitude = (height * 0.12) + (i * 4.0);
      final amplitude = baseAmplitude * activeMultiplier;
      final frequency = (3.5 + i * 0.8) / width * 2 * math.pi;

      final path = Path();
      bool isFirst = true;

      for (double x = 0; x <= width; x += 3) {
        // Normalized distance from center (-1.0 to 1.0)
        final nx = (x - center.dx) / (width / 2);
        // Smoothstep horizontal edge mask: fades wave near edges
        final edgeMask = math.max(0.0, 1.0 - (nx.abs() * nx.abs()));

        final y = center.dy + math.sin(x * frequency + speed + (i * 0.7)) * amplitude * edgeMask;

        if (isFirst) {
          path.moveTo(x, y);
          isFirst = false;
        } else {
          path.lineTo(x, y);
        }
      }

      final alpha = (0.9 - (i * 0.14)).clamp(0.2, 0.95);
      final glowPaint = Paint()
        ..color = primaryColor.withOpacity(alpha * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (i == 0 ? 3.0 : (2.0 - i * 0.2)).clamp(1.0, 3.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, (i == 0 ? 4.0 : 2.0));

      final linePaint = Paint()
        ..color = (i == 0 ? Colors.white : primaryColor).withOpacity(alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (i == 0 ? 2.0 : 1.2);

      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, linePaint);
    }

    // 4. Center Core Energy Ring
    final ringPaint = Paint()
      ..color = primaryColor.withOpacity(isListening ? 0.8 : 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, 12 * pulseScale, ringPaint);

    final dotPaint = Paint()
      ..color = isListening ? Colors.white : primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3.5, dotPaint);

    // 5. Scanlines overlay
    final scanlinePaint = Paint()
      ..color = Colors.black.withOpacity(0.18)
      ..strokeWidth = 1.0;
    for (double y = 0; y <= height; y += 4) {
      canvas.drawLine(Offset(0, y), Offset(width, y), scanlinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _NovaShaderWavePainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.soundLevel != soundLevel ||
        oldDelegate.isListening != isListening ||
        oldDelegate.isSpeaking != isSpeaking ||
        oldDelegate.primaryColor != primaryColor;
  }
}
