import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/hud_frame.dart';

class MouseTrackpadScreen extends ConsumerStatefulWidget {
  const MouseTrackpadScreen({super.key});

  @override
  ConsumerState<MouseTrackpadScreen> createState() =>
      _MouseTrackpadScreenState();
}

class _MouseTrackpadScreenState extends ConsumerState<MouseTrackpadScreen> {
  double _sensitivity = 1.6;
  int _pointerCount = 0;
  int _lastMoveTimeMs = 0;
  double _pendingDx = 0;
  double _pendingDy = 0;
  Timer? _flushTimer;

  void _triggerHaptic() {
    if (ref.read(hapticsProvider)) {
      HapticFeedback.lightImpact();
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    setState(() => _pointerCount++);
  }

  void _onPointerUp(PointerUpEvent event) {
    setState(() => _pointerCount = (_pointerCount - 1).clamp(0, 10));
  }

  void _onPointerCancel(PointerCancelEvent event) {
    setState(() => _pointerCount = (_pointerCount - 1).clamp(0, 10));
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    final repo = ref.read(pcRemoteRepositoryProvider);

    if (_pointerCount >= 2) {
      // Two-finger vertical scroll
      final dy = details.delta.dy * _sensitivity * 0.8;
      repo.sendMouseScroll(-dy);
      return;
    }

    // 1-finger mouse move: throttle to ~60Hz (every 16ms)
    _pendingDx += details.delta.dx * _sensitivity;
    _pendingDy += details.delta.dy * _sensitivity;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastMoveTimeMs >= 16) {
      _lastMoveTimeMs = now;
      repo.sendMouseMove(_pendingDx, _pendingDy);
      _pendingDx = 0;
      _pendingDy = 0;
    } else {
      _flushTimer?.cancel();
      _flushTimer = Timer(const Duration(milliseconds: 16), () {
        if (_pendingDx != 0 || _pendingDy != 0) {
          repo.sendMouseMove(_pendingDx, _pendingDy);
          _pendingDx = 0;
          _pendingDy = 0;
        }
      });
    }
  }

  void _handleTap() {
    _triggerHaptic();
    if (_pointerCount >= 2) {
      ref.read(pcRemoteRepositoryProvider).sendMouseClick('right');
    } else {
      ref.read(pcRemoteRepositoryProvider).sendMouseClick('left');
    }
  }

  void _handleDoubleTap() {
    _triggerHaptic();
    ref.read(pcRemoteRepositoryProvider).sendMouseClick('double');
  }

  void _showSensitivityDialog() {
    final colors = AppColors.of(context);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: colors.surfaceContainerHigh,
            title: Text(
              'Trackpad Sensitivity',
              style: TextStyle(fontWeight: FontWeight.w700, color: colors.onSurface),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Speed Multiplier', style: TextStyle(color: colors.onSurfaceVariant)),
                    Text(
                      '${_sensitivity.toStringAsFixed(1)}x',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _sensitivity,
                  min: 0.5,
                  max: 3.5,
                  activeColor: colors.primary,
                  inactiveColor: colors.surfaceContainerHighest,
                  onChanged: (val) {
                    setDialogState(() => _sensitivity = val);
                    setState(() => _sensitivity = val);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Done', style: TextStyle(color: colors.primary)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _flushTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final themeStyle = ref.watch(themeStyleProvider);
    final isAlienHud = themeStyle == AppThemeStyle.alienHud;
    final repo = ref.watch(pcRemoteRepositoryProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.onSurface, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WINTROLLER',
                          style: isAlienHud
                              ? GoogleFonts.orbitron(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: colors.primary,
                                  letterSpacing: 2.0,
                                )
                              : TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: colors.onSurface,
                                ),
                        ),
                        Text(
                          isAlienHud ? 'MOUSE & TRACKPAD' : 'Wireless Touchpad',
                          style: isAlienHud
                              ? GoogleFonts.orbitron(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: colors.primary.withOpacity(0.7),
                                  letterSpacing: 1.5,
                                )
                              : TextStyle(
                                  fontSize: 12,
                                  color: colors.onSurfaceVariant,
                                ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainer,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.primary, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.primary,
                            boxShadow: [
                              BoxShadow(color: colors.primary.withOpacity(0.8), blurRadius: 4),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ACTIVE',
                          style: GoogleFonts.orbitron(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: colors.primary,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.tune_rounded, color: colors.onSurface, size: 20),
                    tooltip: 'Sensitivity',
                    onPressed: _showSensitivityDialog,
                  ),
                ],
              ),
            ),

            // Main Touchpad Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Listener(
                  onPointerDown: _onPointerDown,
                  onPointerUp: _onPointerUp,
                  onPointerCancel: _onPointerCancel,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: _handlePanUpdate,
                    onTap: _handleTap,
                    onDoubleTap: _handleDoubleTap,
                    child: isAlienHud
                        ? HudFrame(
                            chamferSize: 18,
                            borderColor: colors.primary,
                            backgroundColor: colors.surfaceContainer,
                            padding: const EdgeInsets.all(12),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Dotted Matrix Background Custom Painter
                                CustomPaint(
                                  size: Size.infinite,
                                  painter: _DottedMatrixPainter(
                                    dotColor: colors.primary.withOpacity(0.18),
                                  ),
                                ),

                                // Top Pill Tag: GESTURE SURFACE
                                Positioned(
                                  top: 10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: colors.surfaceContainerLowest.withOpacity(0.8),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: colors.primary.withOpacity(0.35),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.touch_app_rounded, color: colors.primary, size: 14),
                                        const SizedBox(width: 6),
                                        Text(
                                          'GESTURE SURFACE',
                                          style: GoogleFonts.orbitron(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: colors.primary.withOpacity(0.9),
                                            letterSpacing: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Center Delicate Crosshair
                                Icon(
                                  Icons.add_rounded,
                                  size: 32,
                                  color: colors.primary.withOpacity(0.35),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: colors.surfaceContainer,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: _pointerCount > 0
                                    ? colors.primary
                                    : colors.outlineVariant,
                                width: _pointerCount > 0 ? 1.5 : 1,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.gesture_rounded,
                                    size: 54,
                                    color: colors.onSurfaceVariant.withOpacity(0.3),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Slide finger to move mouse pointer',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colors.onSurfaceVariant.withOpacity(0.5),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ),

            // Bottom L-CLICK and R-CLICK Pods
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                height: 72,
                child: Row(
                  children: [
                    // L-CLICK
                    Expanded(
                      child: isAlienHud
                          ? _AlienClickButton(
                              label: 'L-CLICK',
                              icon: Icons.mouse_rounded,
                              onTap: () {
                                _triggerHaptic();
                                repo.sendMouseClick('left');
                              },
                            )
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.surfaceContainerHigh,
                                foregroundColor: colors.onSurface,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: colors.outlineVariant),
                                ),
                              ),
                              onPressed: () {
                                _triggerHaptic();
                                repo.sendMouseClick('left');
                              },
                              child: const Text('LEFT CLICK', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                    ),
                    const SizedBox(width: 12),
                    // R-CLICK
                    Expanded(
                      child: isAlienHud
                          ? _AlienClickButton(
                              label: 'R-CLICK',
                              icon: Icons.cloud_outlined,
                              onTap: () {
                                _triggerHaptic();
                                repo.sendMouseClick('right');
                              },
                            )
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.surfaceContainerHigh,
                                foregroundColor: colors.onSurface,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: colors.outlineVariant),
                                ),
                              ),
                              onPressed: () {
                                _triggerHaptic();
                                repo.sendMouseClick('right');
                              },
                              child: const Text('RIGHT CLICK', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlienClickButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _AlienClickButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: colors.primary.withOpacity(0.2),
        child: HudFrame(
          chamferSize: 12,
          borderColor: colors.primary.withOpacity(0.7),
          backgroundColor: colors.surfaceContainer,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: colors.primary, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.orbitron(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: colors.primary,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DottedMatrixPainter extends CustomPainter {
  final Color dotColor;

  _DottedMatrixPainter({required this.dotColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    const spacing = 18.0;
    for (double x = 12; x < size.width - 12; x += spacing) {
      for (double y = 12; y < size.height - 12; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.9, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
