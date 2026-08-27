import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_providers.dart';
import '../../services/storage_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/alien_icons.dart';
import '../../widgets/hud_frame.dart';
import '../dashboard/dashboard_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../pairing/pairing_discover_screen.dart';
import 'pro_plan_provider.dart';

class ProUpgradeScreen extends ConsumerStatefulWidget {
  final bool isInitialOnboarding;

  const ProUpgradeScreen({
    super.key,
    this.isInitialOnboarding = false,
  });

  @override
  ConsumerState<ProUpgradeScreen> createState() => _ProUpgradeScreenState();
}

class _ProUpgradeScreenState extends ConsumerState<ProUpgradeScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  bool _isSavingKey = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    final currentKey = ref.read(proPlanProvider).geminiApiKey;
    if (currentKey != null) {
      _apiKeyController.text = currentKey;
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  void _navigateToControls() async {
    final storage = ref.read(storageServiceProvider);
    await storage.setPlanSelected(true);

    if (!mounted) return;

    if (widget.isInitialOnboarding) {
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
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _saveApiKey() async {
    setState(() {
      _isSavingKey = true;
      _statusMessage = null;
    });

    final key = _apiKeyController.text.trim();
    if (key.isEmpty) {
      await ref.read(proPlanProvider.notifier).clearApiKey();
      setState(() {
        _isSavingKey = false;
        _statusMessage = 'API Key cleared.';
      });
    } else if (key.length < 15) {
      setState(() {
        _isSavingKey = false;
        _statusMessage = 'Invalid API key format. Must be a valid Gemini API key.';
      });
    } else {
      await ref.read(proPlanProvider.notifier).setGeminiApiKey(key);
      await ref.read(proPlanProvider.notifier).setProStatus(true, tier: ProPlanTier.proMonthly);
      setState(() {
        _isSavingKey = false;
        _statusMessage = 'Gemini API Key saved! Nova Pro Assistant unlocked.';
      });
    }
  }

  void _activateProDemo() async {
    await ref.read(proPlanProvider.notifier).setProStatus(true, tier: ProPlanTier.proLifetime);
    final storage = ref.read(storageServiceProvider);
    await storage.setPlanSelected(true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Wintroller Pro Lifetime Activated! Full controls unlocked.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final proState = ref.watch(proPlanProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.primary, size: 20),
          onPressed: () {
            if (widget.isInitialOnboarding) {
              _navigateToControls();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Text(
          'WINTROLLER PRO',
          style: GoogleFonts.orbitron(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: colors.primary,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _navigateToControls,
            child: Text(
              'Skip to Controls',
              style: TextStyle(color: colors.primary, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pro Badge Header Radar
              HudFrame(
                chamferSize: 18,
                borderColor: colors.primary,
                backgroundColor: colors.surfaceContainer,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    HudRadarCircle(
                      size: 72,
                      color: colors.primary,
                      child: const AlienEmblem(size: 40, hasGlow: true),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      proState.isPro ? 'PRO STATUS: ACTIVE' : 'UPGRADE TO WINTROLLER PRO',
                      style: GoogleFonts.orbitron(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: colors.primary,
                        letterSpacing: 1.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      proState.isPro
                          ? 'All tactical cybernetic features and Nova AI assistant unlocked.'
                          : 'Unleash Nova AI Assistant powered by Google Gemini API & multi-step automation.',
                      style: GoogleFonts.rajdhani(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Feature Highlights List
              Text(
                'PRO TIER CAPABILITIES',
                style: GoogleFonts.orbitron(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: colors.primary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),

              _ProFeatureTile(
                icon: Icons.psychology_rounded,
                title: 'Nova AI Virtual Co-Pilot',
                desc: 'Voice & text AI assistant powered by Gemini for hands-free hardware, media, and power control.',
                accentColor: colors.primary,
              ),
              const SizedBox(height: 10),
              _ProFeatureTile(
                icon: Icons.bolt_rounded,
                title: 'Multi-Step Automated Routines',
                desc: 'One-command routines like "Night Mode" (Dims screen, mutes audio, and sleeps monitors).',
                accentColor: const Color(0xFFFFD600),
              ),
              const SizedBox(height: 10),
              _ProFeatureTile(
                icon: Icons.vpn_key_rounded,
                title: 'Custom Gemini API Key Support',
                desc: 'Plug in your own Google Gemini API key with zero rate-limit constraints.',
                accentColor: colors.secondary,
              ),

              const SizedBox(height: 24),

              // Gemini API Key Input Section
              Text(
                'GEMINI API KEY CONFIGURATION',
                style: GoogleFonts.orbitron(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: colors.primary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),

              HudFrame(
                chamferSize: 12,
                borderColor: colors.primary.withOpacity(0.5),
                backgroundColor: colors.surfaceContainer,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter your Google Gemini API Key below to unlock and power the Nova AI Virtual Assistant:',
                      style: GoogleFonts.rajdhani(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _apiKeyController,
                      obscureText: true,
                      style: GoogleFonts.shareTechMono(
                        fontSize: 13,
                        color: colors.primary,
                      ),
                      decoration: InputDecoration(
                        hintText: 'AIzaSy...',
                        hintStyle: TextStyle(color: colors.onSurfaceVariant.withOpacity(0.4)),
                        filled: true,
                        fillColor: colors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: colors.primary.withOpacity(0.4)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: colors.primary.withOpacity(0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: colors.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.clear_rounded, color: colors.onSurfaceVariant, size: 18),
                          onPressed: () => _apiKeyController.clear(),
                        ),
                      ),
                    ),
                    if (_statusMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _statusMessage!,
                        style: GoogleFonts.shareTechMono(
                          fontSize: 11,
                          color: _statusMessage!.contains('unlocked') || _statusMessage!.contains('saved')
                              ? colors.primary
                              : colors.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _isSavingKey
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                              )
                            : const Icon(Icons.save_rounded, color: Colors.black, size: 18),
                        label: Text(
                          _isSavingKey ? 'SAVING...' : 'SAVE & UNLOCK NOVA',
                          style: GoogleFonts.orbitron(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            letterSpacing: 1.0,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isSavingKey ? null : _saveApiKey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colors.primary.withOpacity(0.3), width: 0.8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lightbulb_outline_rounded, color: colors.primary, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Get a 100% free Gemini API key in 5 seconds from Google AI Studio: aistudio.google.com/apikey (Keys created in Google Cloud Console must have Generative Language API enabled).',
                              style: GoogleFonts.rajdhani(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: colors.onSurfaceVariant,
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

              // Developer / Instant Demo Unlock Button
              OutlinedButton.icon(
                icon: Icon(Icons.stars_rounded, color: colors.primary, size: 18),
                label: Text(
                  proState.isPro ? 'PRO LIFETIME UNLOCKED' : 'ACTIVATE PRO MODE (DEV / DEMO)',
                  style: GoogleFonts.orbitron(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: colors.primary,
                    letterSpacing: 1.0,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.primary.withOpacity(0.6), width: 1.2),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _activateProDemo,
              ),

              const SizedBox(height: 20),

              // Continue to Control Menu Primary Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.dashboard_rounded, color: Colors.black, size: 20),
                  label: Text(
                    'PROCEED TO CONTROL MENU',
                    style: GoogleFonts.orbitron(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      letterSpacing: 1.0,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    elevation: 8,
                    shadowColor: colors.primary.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _navigateToControls,
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProFeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;
  final Color accentColor;

  const _ProFeatureTile({
    required this.icon,
    required this.title,
    required this.desc,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 0.8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.orbitron(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: GoogleFonts.rajdhani(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
