import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_colors.dart';

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
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppColors.surfaceContainerHigh,
            title: const Text(
              'Trackpad Sensitivity',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.onSurface),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Speed Multiplier', style: TextStyle(color: AppColors.onSurfaceVariant)),
                    Text(
                      '${_sensitivity.toStringAsFixed(1)}x',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.mouseAccent,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _sensitivity,
                  min: 0.5,
                  max: 3.5,
                  activeColor: AppColors.mouseAccent,
                  inactiveColor: AppColors.surfaceContainerHighest,
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
                child: const Text('Done', style: TextStyle(color: AppColors.mouseAccent)),
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
    final repo = ref.watch(pcRemoteRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Trackpad'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Trackpad Sensitivity',
            onPressed: _showSensitivityDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Gesture hint header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _GestureHint(icon: Icons.touch_app_rounded, label: 'Tap: Left Click'),
                  _GestureHint(icon: Icons.touch_app_rounded, label: '2-Finger: Right Click'),
                  _GestureHint(icon: Icons.swap_vert_rounded, label: '2-Finger: Scroll'),
                ],
              ),
            ),

            // Fullscreen Touchpad Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Listener(
                  onPointerDown: _onPointerDown,
                  onPointerUp: _onPointerUp,
                  onPointerCancel: _onPointerCancel,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: _handlePanUpdate,
                    onTap: _handleTap,
                    onDoubleTap: _handleDoubleTap,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: _pointerCount > 0
                              ? AppColors.mouseAccent
                              : AppColors.outlineVariant,
                          width: _pointerCount > 0 ? 1.5 : 1,
                        ),
                        boxShadow: _pointerCount > 0
                            ? [
                                BoxShadow(
                                  color: AppColors.mouseAccent.withOpacity(0.12),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.gesture_rounded,
                                size: 54,
                                color: AppColors.onSurfaceVariant.withOpacity(0.3),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Slide finger to move mouse pointer',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.onSurfaceVariant.withOpacity(0.5),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Left & Right Click physical buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: SizedBox(
                height: 64,
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceContainerHigh,
                          foregroundColor: AppColors.onSurface,
                          elevation: 0,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.horizontal(
                              left: Radius.circular(20),
                            ),
                            side: BorderSide(color: AppColors.outlineVariant),
                          ),
                        ),
                        onPressed: () {
                          _triggerHaptic();
                          repo.sendMouseClick('left');
                        },
                        child: const Text(
                          'LEFT CLICK',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 4,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceContainerHigh,
                          foregroundColor: AppColors.onSurface,
                          elevation: 0,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.horizontal(
                              right: Radius.circular(20),
                            ),
                            side: BorderSide(color: AppColors.outlineVariant),
                          ),
                        ),
                        onPressed: () {
                          _triggerHaptic();
                          repo.sendMouseClick('right');
                        },
                        child: const Text(
                          'RIGHT CLICK',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
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

class _GestureHint extends StatelessWidget {
  final IconData icon;
  final String label;

  const _GestureHint({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.mouseAccent),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
