import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/system_models.dart';
import '../../providers/app_providers.dart';
import '../../services/websocket_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/connection_status_badge.dart';
import '../../widgets/module_card.dart';
import '../brightness/brightness_control_screen.dart';
import '../connection_error/connection_error_screen.dart';
import '../devices/device_management_screen.dart';
import '../files/file_manager_screen.dart';
import '../keyboard/keyboard_control_screen.dart';
import '../media/media_control_screen.dart';
import '../mouse/mouse_trackpad_screen.dart';
import '../power/power_control_screen.dart';
import '../settings/settings_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeDevice = ref.watch(activeDeviceProvider);
    final connectionStatus = ref.watch(connectionStatusProvider).value ?? ConnectionStatus.offline;
    final systemInfo = ref.watch(systemInfoProvider).value ?? const HostSystemInfo();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.computer_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'PCRemote',
              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
          ],
        ),
        actions: [
          ConnectionStatusBadge(
            status: connectionStatus,
            deviceName: activeDevice?.name,
            onTap: () {
              if (connectionStatus == ConnectionStatus.offline) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ConnectionErrorScreen()),
                );
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DeviceManagementScreen()),
                );
              }
            },
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Offline Alert Banner if disconnected
              if (connectionStatus == ConnectionStatus.offline ||
                  connectionStatus == ConnectionStatus.error) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.error.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off_rounded, color: AppColors.error, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PC is Offline',
                              style: TextStyle(
                                color: AppColors.onSurface,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              activeDevice != null
                                  ? 'Cannot reach ${activeDevice.name} (${activeDevice.ip})'
                                  : 'No active PC paired yet',
                              style: const TextStyle(
                                color: AppColors.onSurfaceVariant,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ConnectionErrorScreen(),
                            ),
                          );
                        },
                        child: const Text('Troubleshoot', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                ),
              ],

              // System Status Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.surfaceContainerHigh,
                      AppColors.surfaceContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.outlineVariant.withOpacity(0.8),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.desktop_windows_rounded,
                                color: AppColors.primary,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activeDevice?.name ?? systemInfo.hostname,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  activeDevice != null
                                      ? '${activeDevice.ip} • ${systemInfo.osVersion}'
                                      : systemInfo.osVersion,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.devices_rounded, color: AppColors.primary),
                          tooltip: 'Manage Devices',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const DeviceManagementScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Divider(color: AppColors.outlineVariant, height: 1),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _TelemetryItem(
                          icon: systemInfo.isCharging
                              ? Icons.battery_charging_full_rounded
                              : Icons.battery_std_rounded,
                          label: 'Battery',
                          value: '${systemInfo.batteryPercent}%',
                          color: systemInfo.batteryPercent > 20
                              ? AppColors.tertiary
                              : AppColors.error,
                        ),
                        _TelemetryItem(
                          icon: Icons.memory_rounded,
                          label: 'CPU Load',
                          value: '${systemInfo.cpuUsage.toStringAsFixed(0)}%',
                          color: AppColors.primary,
                        ),
                        _TelemetryItem(
                          icon: Icons.storage_rounded,
                          label: 'RAM Usage',
                          value: '${systemInfo.ramUsage.toStringAsFixed(0)}%',
                          color: AppColors.secondary,
                        ),
                        _TelemetryItem(
                          icon: systemInfo.isMuted
                              ? Icons.volume_off_rounded
                              : Icons.volume_up_rounded,
                          label: 'Volume',
                          value: systemInfo.isMuted ? 'Muted' : '${systemInfo.volume}%',
                          color: AppColors.mediaAccent,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Control Modules',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 14),

              // 6 Modules Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.05,
                children: [
                  ModuleCard(
                    title: 'Mouse & Trackpad',
                    subtitle: 'Gestures, clicks & scroll',
                    icon: Icons.touch_app_rounded,
                    accentColor: AppColors.mouseAccent,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MouseTrackpadScreen()),
                      );
                    },
                  ),
                  ModuleCard(
                    title: 'Keyboard',
                    subtitle: 'Typing & system shortcuts',
                    icon: Icons.keyboard_rounded,
                    accentColor: AppColors.keyboardAccent,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const KeyboardControlScreen()),
                      );
                    },
                  ),
                  ModuleCard(
                    title: 'Media Controls',
                    subtitle: 'Playback, volume & mic',
                    icon: Icons.play_circle_filled_rounded,
                    accentColor: AppColors.mediaAccent,
                    badgeText: systemInfo.isPlaying ? 'Playing' : null,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MediaControlScreen()),
                      );
                    },
                  ),
                  ModuleCard(
                    title: 'Power Options',
                    subtitle: 'Shutdown, restart, lock',
                    icon: Icons.power_settings_new_rounded,
                    accentColor: AppColors.powerAccent,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PowerControlScreen()),
                      );
                    },
                  ),
                  ModuleCard(
                    title: 'File Manager',
                    subtitle: 'Browse, download, upload',
                    icon: Icons.folder_shared_rounded,
                    accentColor: AppColors.filesAccent,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const FileManagerScreen()),
                      );
                    },
                  ),
                  ModuleCard(
                    title: 'Display Brightness',
                    subtitle: 'Adjust screen light level',
                    icon: Icons.brightness_6_rounded,
                    accentColor: AppColors.brightnessAccent,
                    badgeText: '${systemInfo.brightness}%',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const BrightnessControlScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _TelemetryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _TelemetryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
