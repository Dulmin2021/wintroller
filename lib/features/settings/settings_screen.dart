import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_colors.dart';
import '../onboarding/onboarding_screen.dart';

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

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        title: Text(
          'Settings',
          style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
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

                  // 1. Alienware Sci-Fi Cyberpunk HUD (Flagship)
                  _ThemeStyleOptionCard(
                    title: 'Alienware Sci-Fi HUD',
                    subtitle: 'Alien Remote Interface (Neon Green & Matrix HUD)',
                    bgColor: const Color(0xFF040D06),
                    accentColor: const Color(0xFF00FF66),
                    isSelected: themeStyle == AppThemeStyle.alienHud,
                    onTap: () {
                      ref
                          .read(themeStyleProvider.notifier)
                          .setThemeStyle(AppThemeStyle.alienHud);
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
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.resolveWith<Color?>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.selected)) {
                              return colors.primaryContainer.withOpacity(0.25);
                            }
                            return colors.surfaceContainerHigh;
                          },
                        ),
                        side: MaterialStateProperty.all(
                          BorderSide(color: colors.outlineVariant, width: 0.8),
                        ),
                      ),
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                          icon: Icon(Icons.dark_mode_rounded, size: 18),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Light'),
                          icon: Icon(Icons.light_mode_rounded, size: 18),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('System'),
                          icon: Icon(Icons.settings_suggest_rounded, size: 18),
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

            // Help & About
            Text(
              'About Wintroller',
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
                    leading: Icon(Icons.info_outline_rounded, color: colors.secondary),
                    title: Text(
                      'Version',
                      style: TextStyle(fontWeight: FontWeight.w600, color: colors.onSurface),
                    ),
                    trailing: Text(
                      '1.0.0 (Build 1)',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
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
  final VoidCallback onTap;

  const _ThemeStyleOptionCard({
    required this.title,
    required this.subtitle,
    required this.bgColor,
    required this.accentColor,
    required this.isSelected,
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
                  if (isSelected)
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
