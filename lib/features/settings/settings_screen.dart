import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_colors.dart';
import '../onboarding/onboarding_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final themeStyle = ref.watch(themeStyleProvider);
    final haptics = ref.watch(hapticsProvider);
    final autoReconnect = ref.watch(autoReconnectProvider);
    final activeDevice = ref.watch(activeDeviceProvider);
    final ws = ref.watch(webSocketServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Preference Section: Appearance
            const Text(
              'Appearance & Theme',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.outlineVariant, width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.palette_rounded, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Theme Style',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ThemeStyleOptionCard(
                          title: 'Stitch Cyber',
                          subtitle: 'Proton Remote',
                          bgColor: const Color(0xFF0B1326),
                          accentColor: AppColors.primaryContainer,
                          isSelected: themeStyle == AppThemeStyle.stitchCyber,
                          onTap: () {
                            ref
                                .read(themeStyleProvider.notifier)
                                .setThemeStyle(AppThemeStyle.stitchCyber);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
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
                  const Divider(color: AppColors.outlineVariant, height: 1),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.brightness_6_rounded, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Mode',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
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
                              return AppColors.primaryContainer.withOpacity(0.3);
                            }
                            return AppColors.surfaceContainerHigh;
                          },
                        ),
                        side: MaterialStateProperty.all(
                          const BorderSide(color: AppColors.outlineVariant, width: 0.8),
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
            const Text(
              'Controls & Connection',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.outlineVariant, width: 0.8),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.vibration_rounded, color: AppColors.tertiary),
                    title: const Text('Haptic Feedback', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Vibrate on trackpad tap and button presses'),
                    value: haptics,
                    activeColor: AppColors.tertiary,
                    onChanged: (_) => ref.read(hapticsProvider.notifier).toggle(),
                  ),
                  const Divider(color: AppColors.outlineVariant, height: 1),
                  SwitchListTile(
                    secondary: const Icon(Icons.sync_rounded, color: AppColors.primaryContainer),
                    title: const Text('Auto-Reconnect', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Automatically reconnect when PC is detected on Wi-Fi'),
                    value: autoReconnect,
                    activeColor: AppColors.primaryContainer,
                    onChanged: (_) => ref.read(autoReconnectProvider.notifier).toggle(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Active Device & Disconnect
            if (activeDevice != null) ...[
              const Text(
                'Active Connection',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.outlineVariant, width: 0.8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.desktop_windows_rounded, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                activeDevice.name,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '${activeDevice.ip}:${activeDevice.port}',
                                style: const TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12),
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
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
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
            const Text(
              'About Wintroller',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.outlineVariant, width: 0.8),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded, color: AppColors.secondary),
                    title: const Text('Version', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Text('1.0.0 (Build 1)', style: TextStyle(color: AppColors.onSurfaceVariant)),
                  ),
                  const Divider(color: AppColors.outlineVariant, height: 1),
                  ListTile(
                    leading: const Icon(Icons.help_outline_rounded, color: AppColors.secondary),
                    title: const Text('Replay Onboarding Guide', style: TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right_rounded),
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
              color: isSelected ? accentColor : AppColors.outlineVariant.withOpacity(0.6),
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
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle_rounded, color: accentColor, size: 18),
                ],
              ),
              const SizedBox(height: 12),
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
