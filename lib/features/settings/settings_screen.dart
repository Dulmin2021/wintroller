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
              'Appearance',
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
                    leading: const Icon(Icons.dark_mode_rounded, color: AppColors.primary),
                    title: const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(themeMode.name.toUpperCase()),
                    trailing: DropdownButton<ThemeMode>(
                      value: themeMode,
                      dropdownColor: AppColors.surfaceContainerHigh,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                        DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                        DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                      ],
                      onChanged: (mode) {
                        if (mode != null) {
                          ref.read(themeModeProvider.notifier).setThemeMode(mode);
                        }
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
              'About PCRemote',
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
