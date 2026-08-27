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
    this.height = 130,
  });

  @override
  State<NovaVoiceWaveVisualizer> createState() => _NovaVoiceWaveVisualizerState();
}

class _NovaVoiceWaveVisualizerState extends State<NovaVoiceWaveVisualizer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  double _smoothedVoicePower = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Noise gate: filters out ambient hiss and negative decibels
  double _calculateVoicePower() {
    if (widget.isSpeaking) return 0.75;
    if (!widget.isListening) return 0.0;

    // Filter background noise threshold (below 2.0 dB is room hiss/silence)
    if (widget.soundLevel <= 2.0) {
      return 0.0;
    }

    // Normalize voice volume from 2.0 dB to 10.0+ dB into 0.0 -> 1.0
    final normalized = (widget.soundLevel - 2.0) / 7.5;
    return normalized.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final targetPower = _calculateVoicePower();
    // Smooth transition between silence and voice
    _smoothedVoicePower += (targetPower - _smoothedVoicePower) * 0.35;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(double.infinity, widget.height),
          painter: _NovaShaderWavePainter(
            time: _controller.value * 2 * math.pi,
            voicePower: _smoothedVoicePower,
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
  final double voicePower; // 0.0 = silence, 1.0 = loud voice
  final bool isListening;
  final bool isSpeaking;
  final Color primaryColor;

  _NovaShaderWavePainter({
    required this.time,
    required this.voicePower,
    required this.isListening,
    required this.isSpeaking,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final width = size.width;
    final height = size.height;

    // 1. Subtle HUD grid background
    final gridPaint = Paint()
      ..color = primaryColor.withOpacity(0.04)
      ..strokeWidth = 0.5;

    for (double y = 0; y <= height; y += 14) {
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }
    for (double x = 0; x <= width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, height), gridPaint);
    }

    // 2. Center Baseline Laser Glow (Steady when silent, pulses when speaking)
    final isVoiceActive = voicePower > 0.05;
    final pulseScale = isVoiceActive
        ? 1.0 + (voicePower * 0.8)
        : (isSpeaking ? 1.0 + 0.15 * math.sin(time * 3) : 0.6 + 0.08 * math.sin(time * 1.5));

    final coreRadius = (30.0 * pulseScale).clamp(14.0, 60.0);
    final coreGradient = RadialGradient(
      colors: [
        primaryColor.withOpacity(isVoiceActive ? 0.35 : 0.10),
        primaryColor.withOpacity(isVoiceActive ? 0.10 : 0.02),
        Colors.transparent,
      ],
      stops: const [0.0, 0.5, 1.0],
    );

    final corePaint = Paint()
      ..shader = coreGradient.createShader(
        Rect.fromCircle(center: center, radius: coreRadius),
      );
    canvas.drawCircle(center, coreRadius, corePaint);

    // 3. Multi-Harmonic Waves:
    // - When SILENT (voicePower == 0): Calm, elegant laser baseline line
    // - When SPEAKING (voicePower > 0): 5 harmonic sine waves explode matching voice
    const int waveCount = 5;
    for (int i = 0; i < waveCount; i++) {
      final speed = time * (1.2 + i * 0.2);

      // Amplitude: resting baseline when silent (1.5px), expanding up to 45px when voice is heard
      final baseAmp = (height * 0.03) + (i * 0.5);
      final voiceAmp = ((height * 0.28) + (i * 5.0)) * voicePower;
      final amplitude = isVoiceActive ? (baseAmp + voiceAmp) : baseAmp * (0.8 + 0.2 * math.sin(time + i));

      final frequency = (3.0 + i * 0.7) / width * 2 * math.pi;

      final path = Path();
      bool isFirst = true;

      for (double x = 0; x <= width; x += 3) {
        final nx = (x - center.dx) / (width / 2);
        // Smoothstep edge fade
        final edgeMask = math.max(0.0, 1.0 - (nx.abs() * nx.abs()));
        final y = center.dy + math.sin(x * frequency + speed + (i * 0.8)) * amplitude * edgeMask;

        if (isFirst) {
          path.moveTo(x, y);
          isFirst = false;
        } else {
          path.lineTo(x, y);
        }
      }

      final alpha = isVoiceActive
          ? (0.95 - (i * 0.12)).clamp(0.2, 0.95)
          : (i == 0 ? 0.6 : (0.25 - i * 0.04)).clamp(0.05, 0.6);

      final glowPaint = Paint()
        ..color = primaryColor.withOpacity(alpha * (isVoiceActive ? 0.6 : 0.2))
        ..style = PaintingStyle.stroke
        ..strokeWidth = (i == 0 ? 3.0 : 1.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, (isVoiceActive ? (i == 0 ? 4.0 : 2.0) : 1.0));

      final linePaint = Paint()
        ..color = (i == 0 && isVoiceActive ? Colors.white : primaryColor).withOpacity(alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (i == 0 ? 2.0 : 1.0);

      canvas.drawPath(path, glowPaint);
      canvas.drawPath(path, linePaint);
    }

    // 4. Center Core Dot
    final ringPaint = Paint()
      ..color = primaryColor.withOpacity(isVoiceActive ? 0.8 : 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, 9 * pulseScale, ringPaint);

    final dotPaint = Paint()
      ..color = isVoiceActive ? Colors.white : primaryColor.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, isVoiceActive ? 3.5 : 2.5, dotPaint);

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
        oldDelegate.voicePower != voicePower ||
        oldDelegate.isListening != isListening ||
        oldDelegate.isSpeaking != isSpeaking ||
        oldDelegate.primaryColor != primaryColor;
  }
}
