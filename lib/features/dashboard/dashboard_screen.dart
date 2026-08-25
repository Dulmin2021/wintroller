import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/system_models.dart';
import '../../providers/app_providers.dart';
import '../../services/websocket_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/alien_icons.dart';
import '../../widgets/hud_frame.dart';
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
    final colors = AppColors.of(context);
    final themeStyle = ref.watch(themeStyleProvider);
    final activeDevice = ref.watch(activeDeviceProvider);
    final connectionStatus = ref.watch(connectionStatusProvider).value ?? ConnectionStatus.offline;
    final systemInfo = ref.watch(systemInfoProvider).value ?? const HostSystemInfo();

    final isAlienHud = themeStyle == AppThemeStyle.alienHud;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar / Alien Interface Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                children: [
                  // Alien Emblem Logo
                  if (isAlienHud) ...[
                    const AlienEmblem(size: 38),
                    const SizedBox(width: 12),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.computer_rounded,
                        color: colors.primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],

                  // App Title & Subhead
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WINTROLLER',
                          style: isAlienHud
                              ? GoogleFonts.orbitron(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w900,
                                  color: colors.primary,
                                  letterSpacing: 2.2,
                                )
                              : TextStyle(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                  fontSize: 20,
                                  color: colors.onSurface,
                                ),
                        ),
                        if (isAlienHud)
                          Text(
                            'ALIEN REMOTE INTERFACE',
                            style: GoogleFonts.orbitron(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              color: colors.primary.withOpacity(0.75),
                              letterSpacing: 1.8,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Connection Status Pill
                  GestureDetector(
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isAlienHud
                            ? colors.surfaceContainer
                            : (connectionStatus == ConnectionStatus.connected
                                ? colors.tertiary.withOpacity(0.15)
                                : colors.error.withOpacity(0.15)),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: connectionStatus == ConnectionStatus.connected
                              ? colors.primary
                              : colors.error,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: connectionStatus == ConnectionStatus.connected
                                  ? colors.primary
                                  : colors.error,
                              boxShadow: isAlienHud
                                  ? [
                                      BoxShadow(
                                        color: colors.primary.withOpacity(0.8),
                                        blurRadius: 6,
                                      )
                                    ]
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            connectionStatus == ConnectionStatus.connected
                                ? 'CONNECTED'
                                : 'OFFLINE',
                            style: isAlienHud
                                ? GoogleFonts.orbitron(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: connectionStatus == ConnectionStatus.connected
                                        ? colors.primary
                                        : colors.error,
                                    letterSpacing: 1.0,
                                  )
                                : TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: connectionStatus == ConnectionStatus.connected
                                        ? colors.primary
                                        : colors.error,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Radar Reticle / Settings Button
                  if (isAlienHud)
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const DeviceManagementScreen()),
                        );
                      },
                      child: HudRadarCircle(
                        size: 36,
                        color: colors.primary,
                        child: Icon(
                          Icons.radar_rounded,
                          color: colors.primary,
                          size: 18,
                        ),
                      ),
                    )
                  else
                    IconButton(
                      icon: Icon(Icons.settings_outlined, color: colors.onSurface),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        );
                      },
                    ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Offline Alert Banner if disconnected
                    if (connectionStatus == ConnectionStatus.offline ||
                        connectionStatus == ConnectionStatus.error) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.errorContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: colors.error.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.cloud_off_rounded, color: colors.error, size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'PC Connection Offline',
                                    style: TextStyle(
                                      color: colors.onSurface,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    activeDevice != null
                                        ? 'Cannot reach ${activeDevice.name} (${activeDevice.ip})'
                                        : 'No active PC paired yet',
                                    style: TextStyle(
                                      color: colors.onSurfaceVariant,
                                      fontSize: 11,
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
                              child: Text(
                                'Reconnect',
                                style: TextStyle(color: colors.error, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Host Status HUD Card
                    if (isAlienHud)
                      HudFrame(
                        chamferSize: 18,
                        borderColor: colors.primary,
                        backgroundColor: colors.surfaceContainer,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Top Row: PC Radar Monitor + Host info
                            Row(
                              children: [
                                HudRadarCircle(
                                  size: 68,
                                  color: colors.primary,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: colors.primary.withOpacity(0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.desktop_windows_rounded,
                                      color: colors.primary,
                                      size: 32,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        (activeDevice?.name ?? systemInfo.hostname).toUpperCase(),
                                        style: GoogleFonts.orbitron(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                          color: colors.primary,
                                          letterSpacing: 0.8,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        activeDevice != null
                                            ? activeDevice.ip
                                            : '192.168.1.X',
                                        style: GoogleFonts.shareTechMono(
                                          fontSize: 13,
                                          color: colors.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        systemInfo.osVersion,
                                        style: GoogleFonts.rajdhani(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: colors.onSurfaceVariant.withOpacity(0.8),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.devices_rounded, color: colors.primary, size: 22),
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

                            const SizedBox(height: 14),
                            Divider(color: colors.outlineVariant, height: 1),
                            const SizedBox(height: 14),

                            // Bottom Row: 4 Glowing Telemetry Pods
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _HudTelemetryPod(
                                  icon: systemInfo.isCharging
                                      ? Icons.battery_charging_full_rounded
                                      : Icons.battery_std_rounded,
                                  value: '${systemInfo.batteryPercent}%',
                                  label: 'BATTERY',
                                  color: colors.primary,
                                ),
                                _HudTelemetryPod(
                                  icon: Icons.memory_rounded,
                                  value: '${systemInfo.cpuUsage.toStringAsFixed(0)}%',
                                  label: 'CPU LOAD',
                                  color: colors.primary,
                                ),
                                _HudTelemetryPod(
                                  icon: Icons.developer_board_rounded,
                                  value: '${systemInfo.ramUsage.toStringAsFixed(0)}%',
                                  label: 'RAM USAGE',
                                  color: colors.primary,
                                ),
                                _HudTelemetryPod(
                                  icon: systemInfo.isMuted
                                      ? Icons.volume_off_rounded
                                      : Icons.volume_up_rounded,
                                  value: systemInfo.isMuted ? 'MUTE' : '${systemInfo.volume}%',
                                  label: 'VOLUME',
                                  color: systemInfo.volume > 80
                                      ? const Color(0xFFFFD600)
                                      : colors.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colors.surfaceContainerHigh,
                              colors.surfaceContainer,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: colors.outlineVariant.withOpacity(0.8),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: colors.primary.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          Icons.desktop_windows_rounded,
                                          color: colors.primary,
                                          size: 26,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              activeDevice?.name ?? systemInfo.hostname,
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                                color: colors.onSurface,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              activeDevice != null
                                                  ? '${activeDevice.ip} • ${systemInfo.osVersion}'
                                                  : systemInfo.osVersion,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: colors.onSurfaceVariant,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.devices_rounded, color: colors.primary),
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
                            Divider(color: colors.outlineVariant, height: 1),
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
                                      ? colors.tertiary
                                      : colors.error,
                                ),
                                _TelemetryItem(
                                  icon: Icons.memory_rounded,
                                  label: 'CPU Load',
                                  value: '${systemInfo.cpuUsage.toStringAsFixed(0)}%',
                                  color: colors.primary,
                                ),
                                _TelemetryItem(
                                  icon: Icons.storage_rounded,
                                  label: 'RAM Usage',
                                  value: '${systemInfo.ramUsage.toStringAsFixed(0)}%',
                                  color: colors.secondary,
                                ),
                                _TelemetryItem(
                                  icon: systemInfo.isMuted
                                      ? Icons.volume_off_rounded
                                      : Icons.volume_up_rounded,
                                  label: 'Volume',
                                  value: systemInfo.isMuted ? 'Muted' : '${systemInfo.volume}%',
                                  color: colors.mediaAccent,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 22),

                    // Section Title: CONTROL MODULES
                    Row(
                      children: [
                        if (isAlienHud) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          'CONTROL MODULES',
                          style: isAlienHud
                              ? GoogleFonts.orbitron(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: colors.primary,
                                  letterSpacing: 1.2,
                                )
                              : TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: colors.onSurface,
                                  letterSpacing: -0.3,
                                ),
                        ),
                        if (isAlienHud) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              height: 1.2,
                              color: colors.primary.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 6 Modules Grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: isAlienHud ? 1.02 : 1.05,
                      children: [
                        ModuleCard(
                          title: 'Mouse & Trackpad',
                          subtitle: 'Gestures, clicks & scroll',
                          icon: Icons.mouse_rounded,
                          accentColor: colors.mouseAccent,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const MouseTrackpadScreen()),
                            );
                          },
                        ),
                        ModuleCard(
                          title: 'Keyboard',
                          subtitle: 'Typing & shortcuts',
                          icon: Icons.keyboard_rounded,
                          accentColor: colors.keyboardAccent,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const KeyboardControlScreen()),
                            );
                          },
                        ),
                        ModuleCard(
                          title: 'Media Controls',
                          subtitle: 'Playback, volume & mic',
                          icon: Icons.play_arrow_rounded,
                          accentColor: colors.mediaAccent,
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
                          accentColor: colors.powerAccent,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const PowerControlScreen()),
                            );
                          },
                        ),
                        ModuleCard(
                          title: 'File Manager',
                          subtitle: 'Browse, download, upload',
                          icon: Icons.folder_open_rounded,
                          accentColor: colors.filesAccent,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const FileManagerScreen()),
                            );
                          },
                        ),
                        ModuleCard(
                          title: 'Display Brightness',
                          subtitle: 'Adjust screen light level',
                          icon: Icons.wb_sunny_outlined,
                          accentColor: colors.brightnessAccent,
                          badgeText: '${systemInfo.brightness}%',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const BrightnessControlScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Bottom Sci-Fi Cybernetic Dock Navigation
            if (isAlienHud)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: HudFrame(
                  chamferSize: 14,
                  borderColor: colors.primary,
                  backgroundColor: colors.surfaceContainer,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Target Reticle
                      IconButton(
                        icon: HudRadarCircle(
                          size: 26,
                          color: colors.primary,
                          child: Icon(Icons.gps_fixed_rounded, color: colors.primary, size: 14),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const DeviceManagementScreen()),
                          );
                        },
                      ),

                      // Mini Alien Emblem
                      IconButton(
                        icon: const AlienEmblem(size: 22, hasGlow: false),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Wintroller Alien Interface v1.0.0')),
                          );
                        },
                      ),

                      // Center Floating Giant Glowing Alien Core
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const DeviceManagementScreen()),
                          );
                        },
                        child: HudRadarCircle(
                          size: 48,
                          color: colors.primary,
                          child: const AlienEmblem(size: 30, hasGlow: true),
                        ),
                      ),

                      // Telemetry Stats
                      IconButton(
                        icon: Icon(Icons.bar_chart_rounded, color: colors.primary, size: 24),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'CPU: ${systemInfo.cpuUsage.toInt()}% | RAM: ${systemInfo.ramUsage.toInt()}% | Bat: ${systemInfo.batteryPercent}%',
                              ),
                            ),
                          );
                        },
                      ),

                      // Settings Gear
                      IconButton(
                        icon: Icon(Icons.settings_outlined, color: colors.primary, size: 24),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          );
                        },
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

class _HudTelemetryPod extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _HudTelemetryPod({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.orbitron(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.orbitron(
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            color: colors.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
      ],
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
    final colors = AppColors.of(context);

    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
