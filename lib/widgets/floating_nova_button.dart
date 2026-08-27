import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../features/nova/nova_assistant_screen.dart';
import '../features/pro/pro_plan_provider.dart';
import '../features/pro/pro_upgrade_screen.dart';
import '../theme/app_colors.dart';
import 'alien_icons.dart';

final floatingNovaButtonEnabledProvider = StateProvider<bool>((ref) => true);

class GlobalFloatingNovaButton extends ConsumerStatefulWidget {
  const GlobalFloatingNovaButton({super.key});

  @override
  ConsumerState<GlobalFloatingNovaButton> createState() => _GlobalFloatingNovaButtonState();
}

class _GlobalFloatingNovaButtonState extends ConsumerState<GlobalFloatingNovaButton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  Offset _position = const Offset(20, 520);
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onTap() {
    HapticFeedback.mediumImpact();

    final proState = ref.read(proPlanProvider);
    final context = this.context;

    if (!proState.isPro && (proState.geminiApiKey == null || proState.geminiApiKey!.isEmpty)) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProUpgradeScreen()),
      );
      return;
    }

    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const NovaAssistantScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 0.15);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;
          final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = ref.watch(floatingNovaButtonEnabledProvider);
    if (!isEnabled) return const SizedBox.shrink();

    final colors = AppColors.of(context);
    final screenSize = MediaQuery.of(context).size;

    // Default position positioning if uninitialized
    if (_position == const Offset(20, 520) && screenSize.width > 100) {
      _position = Offset(screenSize.width - 74, screenSize.height - 180);
    }

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanStart: (_) {
          setState(() {
            _isDragging = true;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            final newX = (_position.dx + details.delta.dx).clamp(10.0, screenSize.width - 70.0);
            final newY = (_position.dy + details.delta.dy).clamp(60.0, screenSize.height - 120.0);
            _position = Offset(newX, newY);
          });
        },
        onPanEnd: (_) {
          setState(() {
            _isDragging = false;
            // Dock gracefully to left or right edge
            final mid = screenSize.width / 2;
            final targetX = _position.dx < mid ? 12.0 : screenSize.width - 68.0;
            _position = Offset(targetX, _position.dy);
          });
        },
        onTap: _onTap,
        child: Material(
          type: MaterialType.transparency,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final glowAlpha = _isDragging ? 0.6 : (0.25 + 0.35 * _pulseController.value);
              return Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF0D1117),
                  border: Border.all(
                    color: const Color(0xFF00FF66),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00FF66).withOpacity(glowAlpha),
                      blurRadius: 14 * (_isDragging ? 1.4 : _pulseController.value + 0.5),
                      spreadRadius: 1.5,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.6),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer radar pulse circle
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF00FF66).withOpacity(0.4),
                          width: 0.8,
                        ),
                      ),
                    ),
                    // Central Alien Emblem
                    const AlienEmblem(
                      size: 24,
                      hasGlow: true,
                    ),
                    // Mini "NOVA" badge at bottom
                    Positioned(
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FF66),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'NOVA',
                          style: GoogleFonts.orbitron(
                            fontSize: 6.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
