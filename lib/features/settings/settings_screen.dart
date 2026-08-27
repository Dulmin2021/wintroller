import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_providers.dart';
import '../../services/language_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/floating_nova_button.dart';
import '../feedback/contact_us_screen.dart';
import '../language/language_selection_screen.dart';
import '../nova/nova_assistant_screen.dart';
import '../onboarding/onboarding_screen.dart';
import '../pro/plan_selection_screen.dart';
import '../pro/pro_plan_provider.dart';
import '../pro/pro_upgrade_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final themeStyle = ref.watch(themeStyleProvider);
    final haptics = ref.watch(hapticsProvider);
    final autoReconnect = ref.watch(autoReconnectProvider);
    final activeDevice = ref.watch(activeDeviceProvider);
    final ws = ref.watch(webSocketServiceProvider);
    final proState = ref.watch(proPlanProvider);
    final currentLocale = ref.watch(languageProvider);
    final langCode = currentLocale.languageCode;

    final currentLangObj = supportedLanguages.firstWhere(
      (l) => l.code == langCode,
      orElse: () => supportedLanguages.first,
    );

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        title: Text(
          AppStrings.get('settings', langCode),
          style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Preference Section: Nova AI & Pro Plan
            Text(
              'NOVA AI & PRO PLAN',
              style: GoogleFonts.orbitron(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: colors.primary,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: proState.isPro ? colors.primary : const Color(0xFFFFD600).withOpacity(0.6),
                  width: 1.2,
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.psychology_rounded, color: colors.primary, size: 22),
                    ),
                    title: Row(
                      children: [
                        Text(
                          'Nova Virtual Co-Pilot',
                          style: TextStyle(fontWeight: FontWeight.w700, color: colors.onSurface),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: colors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: colors.primary, width: 0.8),
                          ),
                          child: Text(
                            'PRO',
                            style: GoogleFonts.orbitron(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: colors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      proState.isPro
                          ? 'Active (Powered by Gemini API)'
                          : 'Automated PC voice & text controls',
                      style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded, color: colors.primary),
                    onTap: () {
                      if (!proState.isPro && (proState.geminiApiKey == null || proState.geminiApiKey!.isEmpty)) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PlanSelectionScreen()),
                        );
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const NovaAssistantScreen()),
                        );
                      }
                    },
                  ),
                  Divider(color: colors.outlineVariant, height: 1),
                  ListTile(
                    leading: Icon(
                      proState.isPro ? Icons.verified_rounded : Icons.star_border_rounded,
                      color: proState.isPro ? colors.primary : const Color(0xFFFFD600),
                    ),
                    title: Text(
                      'Wintroller Plan Tier',
                      style: TextStyle(fontWeight: FontWeight.w600, color: colors.onSurface),
                    ),
                    subtitle: Text(
                      proState.isPro ? 'Pro Member (\$0.99/mo Active)' : 'Free Tier (Basic Controls Only)',
                      style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                    ),
                    trailing: TextButton(
                      child: Text(
                        proState.isPro ? 'Manage' : 'Upgrade',
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PlanSelectionScreen()),
                        );
                      },
                    ),
                  ),
                  Divider(color: colors.outlineVariant, height: 1),
                  SwitchListTile(
                    secondary: Icon(Icons.touch_app_rounded, color: colors.primary),
                    title: Text(
                      'Floating Nova AI Button',
                      style: TextStyle(fontWeight: FontWeight.w600, color: colors.onSurface),
                    ),
                    subtitle: Text(
                      'Floating draggable orb on all screens to wake Nova instantly',
                      style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                    ),
                    value: ref.watch(floatingNovaButtonEnabledProvider),
                    activeColor: colors.primary,
                    onChanged: (val) {
                      ref.read(floatingNovaButtonEnabledProvider.notifier).state = val;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Preference Section: Language & Localization
            Text(
              'LANGUAGE & REGION',
              style: GoogleFonts.orbitron(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: colors.primary,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.outlineVariant, width: 0.8),
              ),
              child: ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.surfaceContainerHighest,
                  ),
                  alignment: Alignment.center,
                  child: Text(currentLangObj.flagEmoji, style: const TextStyle(fontSize: 18)),
                ),
                title: Text(
                  currentLangObj.nativeName,
                  style: TextStyle(fontWeight: FontWeight.w700, color: colors.onSurface),
                ),
                subtitle: Text(
                  '${currentLangObj.name} (${currentLangObj.country})',
                  style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Change',
                      style: TextStyle(color: colors.primary, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, color: colors.primary),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Preference Section: Appearance
            Text(
              'Appearance & Theme Style',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.primary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: colors.outlineVariant, width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.palette_rounded, color: colors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Select Visual Interface',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 1. Alienware Sci-Fi Cyberpunk HUD (Pro Locked for Free tier)
                  _ThemeStyleOptionCard(
                    title: 'Alienware Sci-Fi HUD',
                    subtitle: 'Alien Remote Interface (Neon Green & Matrix HUD)',
                    bgColor: const Color(0xFF040D06),
                    accentColor: const Color(0xFF00FF66),
                    isSelected: themeStyle == AppThemeStyle.alienHud,
                    isProLocked: !proState.isPro,
                    onTap: () {
                      if (!proState.isPro) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF131B2E),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: Row(
                              children: [
                                const Icon(Icons.lock_rounded, color: Color(0xFFADC6FF)),
                                const SizedBox(width: 8),
                                Text(
                                  'Pro Feature',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: const Color(0xFFDAE2FD)),
                                ),
                              ],
                            ),
                            content: Text(
                              AppStrings.get('pro_only_theme', langCode),
                              style: GoogleFonts.inter(color: const Color(0xFFC2C6D6)),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel', style: TextStyle(color: Color(0xFF8C909F))),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFADC6FF),
                                  foregroundColor: const Color(0xFF002E6A),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const PlanSelectionScreen()),
                                  );
                                },
                                child: const Text('View Pro Plans'),
                              ),
                            ],
                          ),
                        );
                      } else {
                        ref.read(themeStyleProvider.notifier).setThemeStyle(AppThemeStyle.alienHud);
                      }
                    },
                  ),
                  const SizedBox(height: 10),

                  // 2. Stitch Cyber & 3. Midnight Slate in 2 columns
                  Row(
                    children: [
                      Expanded(
                        child: _ThemeStyleOptionCard(
                          title: 'Stitch Cyber',
                          subtitle: 'Proton Remote',
                          bgColor: const Color(0xFF0B1326),
                          accentColor: const Color(0xFF4D8EFF),
                          isSelected: themeStyle == AppThemeStyle.stitchCyber,
                          onTap: () {
                            ref
                                .read(themeStyleProvider.notifier)
                                .setThemeStyle(AppThemeStyle.stitchCyber);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ThemeStyleOptionCard(
                          title: 'Midnight Slate',
                          subtitle: 'Charcoal Cyan',
                          bgColor: const Color(0xFF0F172A),
                          accentColor: const Color(0xFF38BDF8),
                          isSelected: themeStyle == AppThemeStyle.midnight,
                          onTap: () {
                            ref
                                .read(themeStyleProvider.notifier)
                                .setThemeStyle(AppThemeStyle.midnight);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: colors.outlineVariant, height: 1),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.brightness_6_rounded, color: colors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Mode',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('System'),
                          icon: Icon(Icons.brightness_auto_rounded, size: 18),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Light'),
                          icon: Icon(Icons.light_mode_rounded, size: 18),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                          icon: Icon(Icons.dark_mode_rounded, size: 18),
                        ),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (modes) {
                        ref.read(themeModeProvider.notifier).setThemeMode(modes.first);
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Preference Section: Controls & Connection
            Text(
              'Controls & Connection',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.primary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.outlineVariant, width: 0.8),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: Icon(Icons.vibration_rounded, color: colors.tertiary),
                    title: Text(
                      'Haptic Feedback',
                      style: TextStyle(fontWeight: FontWeight.w600, color: colors.onSurface),
                    ),
                    subtitle: Text(
                      'Vibrate on trackpad tap and button presses',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                    value: haptics,
                    activeColor: colors.tertiary,
                    onChanged: (_) => ref.read(hapticsProvider.notifier).toggle(),
                  ),
                  Divider(color: colors.outlineVariant, height: 1),
                  SwitchListTile(
                    secondary: Icon(Icons.sync_rounded, color: colors.primaryContainer),
                    title: Text(
                      'Auto-Reconnect',
                      style: TextStyle(fontWeight: FontWeight.w600, color: colors.onSurface),
                    ),
                    subtitle: Text(
                      'Automatically reconnect when PC is detected on Wi-Fi',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                    value: autoReconnect,
                    activeColor: colors.primaryContainer,
                    onChanged: (_) => ref.read(autoReconnectProvider.notifier).toggle(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Active Device & Disconnect
            if (activeDevice != null) ...[
              Text(
                'Active Connection',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.primary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.outlineVariant, width: 0.8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.desktop_windows_rounded, color: colors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeDevice.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: colors.onSurface,
                                ),
                              ),
                              Text(
                                '${activeDevice.ip}:${activeDevice.port}',
                                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.error,
                          side: BorderSide(color: colors.error),
                        ),
                        icon: const Icon(Icons.link_off_rounded),
                        label: const Text('Disconnect PC'),
                        onPressed: () {
                          ws.disconnect();
                          ref.read(activeDeviceProvider.notifier).state = null;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Disconnected from PC')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Help, Support & Feedback
            Text(
              'Support & Feedback',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.primary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: colors.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.outlineVariant, width: 0.8),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.feedback_outlined, color: colors.primary),
                    title: Text(
                      AppStrings.get('contact_support', langCode),
                      style: TextStyle(fontWeight: FontWeight.w600, color: colors.onSurface),
                    ),
                    subtitle: Text(
                      'Report a bug or submit feature suggestions',
                      style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ContactUsScreen()),
                      );
                    },
                  ),
                  Divider(color: colors.outlineVariant, height: 1),
                  ListTile(
                    leading: Icon(Icons.help_outline_rounded, color: colors.secondary),
                    title: Text(
                      'Replay Onboarding Guide',
                      style: TextStyle(fontWeight: FontWeight.w600, color: colors.onSurface),
                    ),
                    trailing: Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                      );
                    },
                  ),
                  Divider(color: colors.outlineVariant, height: 1),
                  ListTile(
                    leading: Icon(Icons.info_outline_rounded, color: colors.secondary),
                    title: Text(
                      'Version',
                      style: TextStyle(fontWeight: FontWeight.w600, color: colors.onSurface),
                    ),
                    trailing: Text(
                      '1.0.0 (Play Store Edition)',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _ThemeStyleOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color bgColor;
  final Color accentColor;
  final bool isSelected;
  final bool isProLocked;
  final VoidCallback onTap;

  const _ThemeStyleOptionCard({
    required this.title,
    required this.subtitle,
    required this.bgColor,
    required this.accentColor,
    required this.isSelected,
    this.isProLocked = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? accentColor : colors.outlineVariant.withOpacity(0.6),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: accentColor.withOpacity(0.6),
                                blurRadius: 6,
                              )
                            ]
                          : null,
                    ),
                  ),
                  if (isProLocked)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFADC6FF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFADC6FF), width: 0.6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_rounded, color: Color(0xFFADC6FF), size: 10),
                          const SizedBox(width: 2),
                          Text(
                            'PRO',
                            style: GoogleFonts.orbitron(fontSize: 8, fontWeight: FontWeight.w900, color: const Color(0xFFADC6FF)),
                          ),
                        ],
                      ),
                    )
                  else if (isSelected)
                    Icon(Icons.check_circle_rounded, color: accentColor, size: 18),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
