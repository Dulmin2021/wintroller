import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../../services/language_service.dart';
import '../../services/storage_service.dart';
import '../dashboard/dashboard_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../pairing/pairing_discover_screen.dart';
import 'pro_plan_provider.dart';
import 'pro_upgrade_screen.dart';

class PlanSelectionScreen extends ConsumerStatefulWidget {
  final bool isInitialOnboarding;

  const PlanSelectionScreen({
    super.key,
    this.isInitialOnboarding = false,
  });

  @override
  ConsumerState<PlanSelectionScreen> createState() => _PlanSelectionScreenState();
}

class _PlanSelectionScreenState extends ConsumerState<PlanSelectionScreen> {
  void _onChooseFree() async {
    HapticFeedback.mediumImpact();
    final storage = ref.read(storageServiceProvider);
    await storage.setPlanSelected(true);

    if (!mounted) return;

    if (widget.isInitialOnboarding) {
      _navigateToNext();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _onChoosePro() async {
    HapticFeedback.mediumImpact();
    final storage = ref.read(storageServiceProvider);
    await storage.setPlanSelected(true);

    if (!mounted) return;

    // Open Pro upgrade / API key configuration
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProUpgradeScreen(isInitialOnboarding: widget.isInitialOnboarding),
      ),
    );
  }

  void _navigateToNext() {
    final storage = ref.read(storageServiceProvider);
    if (!storage.isOnboardingDone()) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
      return;
    }

    final devices = storage.getPairedDevices();
    if (devices.isNotEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PairingDiscoverScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final proState = ref.watch(proPlanProvider);
    final langCode = ref.watch(languageProvider).languageCode;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1326),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B1326),
        elevation: 0,
        leading: widget.isInitialOnboarding
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFFDAE2FD), size: 22),
                onPressed: () => Navigator.of(context).pop(),
              ),
        title: Text(
          'Wintroller',
          style: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: const Color(0xFFADC6FF),
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        actions: [
          if (widget.isInitialOnboarding)
            TextButton(
              onPressed: _onChooseFree,
              child: Text(
                'Skip',
                style: GoogleFonts.inter(color: const Color(0xFFADC6FF), fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              // Header Title
              Text(
                AppStrings.get('choose_plan', langCode),
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFDAE2FD),
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AppStrings.get('choose_plan_subtitle', langCode),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFFC2C6D6),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // 1. Pro Plan Card (Recommended)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF131B2E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFADC6FF), width: 2.0),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFADC6FF).withOpacity(0.18),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Recommended pill badge
                    Positioned(
                      top: -12,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFADC6FF),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFADC6FF).withOpacity(0.4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Text(
                            AppStrings.get('recommended', langCode),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF002E6A),
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                AppStrings.get('pro_plan', langCode),
                                style: GoogleFonts.inter(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFADC6FF),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.bolt_rounded, color: Color(0xFFADC6FF), size: 22),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                AppStrings.get('pro_price', langCode),
                                style: GoogleFonts.inter(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFDAE2FD),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppStrings.get('per_month', langCode),
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFFC2C6D6),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            AppStrings.get('pro_desc', langCode),
                            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFC2C6D6)),
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Color(0xFF2D3449)),
                          const SizedBox(height: 12),

                          // Pro Features list
                          _buildFeatureRow(Icons.check_circle_rounded, const Color(0xFFADC6FF), 'Access all basic controls (Mouse, Keyboard, Media)'),
                          _buildFeatureRow(Icons.smart_toy_rounded, const Color(0xFF4EDEA3), 'Nova AI Voice Assistant (Gemini Neural Engine)'),
                          _buildFeatureRow(Icons.graphic_eq_rounded, const Color(0xFF4EDEA3), '5-Harmonic Voice Wave HUD Visualizer'),
                          _buildFeatureRow(Icons.palette_rounded, const Color(0xFFADC6FF), 'Alien HUD Holographic Neon Theme'),
                          _buildFeatureRow(Icons.touch_app_rounded, const Color(0xFFADC6FF), 'Floating Draggable Nova AI Orb on all screens'),

                          const SizedBox(height: 20),

                          // Pro CTA Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFADC6FF),
                                foregroundColor: const Color(0xFF002E6A),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 8,
                                shadowColor: const Color(0xFFADC6FF).withOpacity(0.4),
                              ),
                              onPressed: _onChoosePro,
                              child: Text(
                                proState.isPro
                                    ? AppStrings.get('pro_active', langCode)
                                    : AppStrings.get('upgrade_to_pro', langCode),
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. Standard (Free) Plan Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF171F33).withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF2D3449), width: 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.get('standard_plan', langCode),
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFDAE2FD),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          AppStrings.get('standard_price', langCode),
                          style: GoogleFonts.inter(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFDAE2FD),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppStrings.get('forever', langCode),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF8C909F),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.get('standard_desc', langCode),
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF8C909F)),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFF2D3449)),
                    const SizedBox(height: 12),

                    // Free Features list
                    _buildFeatureRow(Icons.check_circle_rounded, const Color(0xFFADC6FF), 'Access all basic controls (Mouse, Keyboard, Media)'),
                    _buildFeatureRow(Icons.check_circle_rounded, const Color(0xFFADC6FF), 'Trackpad, Power Options & Brightness control'),
                    _buildFeatureRow(Icons.cancel_rounded, const Color(0xFF8C909F), 'No AI Assistant (Nova Assistant locked)', isNegative: true),
                    _buildFeatureRow(Icons.cancel_rounded, const Color(0xFF8C909F), 'No Alien HUD Theme (Default themes only)', isNegative: true),

                    const SizedBox(height: 20),

                    // Free CTA Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFDAE2FD),
                          side: const BorderSide(color: Color(0xFF8C909F)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _onChooseFree,
                        child: Text(
                          AppStrings.get('start_for_free', langCode),
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, Color color, String text, {bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isNegative ? const Color(0xFF8C909F) : const Color(0xFFDAE2FD),
                fontWeight: isNegative ? FontWeight.w400 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
