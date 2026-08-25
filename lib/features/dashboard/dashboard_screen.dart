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

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _wifiEnabled = true;
  bool _bluetoothEnabled = false;
  bool _displayOn = true;

  @override
  void initState() {
    super.initState();
    final systemInfo = ref.read(systemInfoProvider).value;
    if (systemInfo != null) {
      _wifiEnabled = systemInfo.isWifiOn;
      _bluetoothEnabled = systemInfo.isBluetoothOn;
      _displayOn = systemInfo.isDisplayOn;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final themeStyle = ref.watch(themeStyleProvider);
    final activeDevice = ref.watch(activeDeviceProvider);
    final connectionStatus = ref.watch(connectionStatusProvider).value ?? ConnectionStatus.offline;
    final systemInfo = ref.watch(systemInfoProvider).value ?? const HostSystemInfo();

    ref.listen(systemInfoProvider, (prev, next) {
      if (next.value != null) {
        setState(() {
          _wifiEnabled = next.value!.isWifiOn;
          _bluetoothEnabled = next.value!.isBluetoothOn;
          _displayOn = next.value!.isDisplayOn;
        });
      }
    });

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
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DeviceManagementScreen(),
                        ),
                      );
                    },
                    child: isAlienHud
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainer,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: connectionStatus == ConnectionStatus.connected
                                    ? colors.primary
                                    : colors.error,
                                width: 1.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (connectionStatus == ConnectionStatus.connected
                                          ? colors.primary
                                          : colors.error)
                                      .withOpacity(0.2),
                                  blurRadius: 8,
                                ),
                              ],
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
                                    boxShadow: [
                                      BoxShadow(
                                        color: connectionStatus == ConnectionStatus.connected
                                            ? colors.primary.withOpacity(0.8)
                                            : colors.error.withOpacity(0.8),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  connectionStatus == ConnectionStatus.connected
                                      ? 'CONNECTED'
                                      : 'OFFLINE',
                                  style: GoogleFonts.orbitron(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: connectionStatus == ConnectionStatus.connected
                                        ? colors.primary
                                        : colors.error,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: connectionStatus == ConnectionStatus.connected
                                  ? colors.tertiaryContainer.withOpacity(0.2)
                                  : colors.errorContainer.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: connectionStatus == ConnectionStatus.connected
                                    ? colors.tertiary
                                    : colors.error,
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              connectionStatus == ConnectionStatus.connected ? 'Online' : 'Offline',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: connectionStatus == ConnectionStatus.connected
                                    ? colors.tertiary
                                    : colors.error,
                              ),
                            ),
                          ),
                  ),

                  if (isAlienHud) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: HudRadarCircle(
                        size: 26,
                        color: colors.primary,
                        child: Icon(Icons.radar_rounded, color: colors.primary, size: 14),
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DeviceManagementScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Column(
                  children: [
                    // Host PC Card
                    if (isAlienHud)
                      HudFrame(
                        chamferSize: 18,
                        borderColor: colors.primary,
                        backgroundColor: colors.surfaceContainer,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                HudRadarCircle(
                                  size: 68,
                                  color: colors.primary,
                                  child: Icon(
                                    Icons.desktop_windows_rounded,
                                    color: colors.primary,
                                    size: 34,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        activeDevice != null
                                            ? activeDevice.name.toUpperCase()
                                            : systemInfo.hostname.toUpperCase(),
                                        style: GoogleFonts.orbitron(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          color: colors.primary,
                                          letterSpacing: 0.8,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        activeDevice != null ? activeDevice.ip : '192.168.1.X',
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

                            // Bottom Row: 4 Glowing Telemetry Pods (Icons + Percentage only)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _HudTelemetryPod(
                                  icon: systemInfo.isCharging
                                      ? Icons.battery_charging_full_rounded
                                      : Icons.battery_std_rounded,
                                  value: '${systemInfo.batteryPercent}%',
                                  color: colors.primary,
                                ),
                                _HudTelemetryPod(
                                  icon: Icons.memory_rounded,
                                  value: '${systemInfo.cpuUsage.toStringAsFixed(0)}%',
                                  color: colors.primary,
                                ),
                                _HudTelemetryPod(
                                  icon: Icons.developer_board_rounded,
                                  value: '${systemInfo.ramUsage.toStringAsFixed(0)}%',
                                  color: colors.primary,
                                ),
                                _HudTelemetryPod(
                                  icon: systemInfo.isMuted
                                      ? Icons.volume_off_rounded
                                      : Icons.volume_up_rounded,
                                  value: systemInfo.isMuted ? 'MUTE' : '${systemInfo.volume}%',
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
                                          color: colors.primaryContainer.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: Icon(
                                          Icons.desktop_windows_rounded,
                                          color: colors.primary,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              activeDevice != null
                                                  ? activeDevice.name
                                                  : systemInfo.hostname,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700,
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

                    const SizedBox(height: 16),

                    // Quick Hardware Toggles (Wi-Fi, Bluetooth, Display Power)
                    Row(
                      children: [
                        Expanded(
                          child: _HardwareToggleTile(
                            title: 'WI-FI',
                            isOn: _wifiEnabled,
                            icon: Icons.wifi_rounded,
                            onTap: () {
                              final newState = !_wifiEnabled;
                              setState(() => _wifiEnabled = newState);
                              ref.read(pcRemoteRepositoryProvider).setWifi(newState);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(newState ? 'Enabling PC Wi-Fi...' : 'Disabling PC Wi-Fi...'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _HardwareToggleTile(
                            title: 'BLUETOOTH',
                            isOn: _bluetoothEnabled,
                            icon: Icons.bluetooth_rounded,
                            onTap: () {
                              final newState = !_bluetoothEnabled;
                              setState(() => _bluetoothEnabled = newState);
                              ref.read(pcRemoteRepositoryProvider).setBluetooth(newState);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(newState ? 'Enabling PC Bluetooth...' : 'Disabling PC Bluetooth...'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _HardwareToggleTile(
                            title: 'DISPLAY',
                            isOn: _displayOn,
                            icon: Icons.monitor_rounded,
                            onTap: () {
                              final newState = !_displayOn;
                              setState(() => _displayOn = newState);
                              ref.read(pcRemoteRepositoryProvider).setDisplay(newState);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(newState ? 'Waking PC Display...' : 'Turning PC Display OFF...'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

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
                      childAspectRatio: isAlienHud ? 0.95 : 1.15,
                      children: [
                        ModuleCard(
                          title: isAlienHud ? 'MOUSE & TRACKPAD' : 'Trackpad',
                          subtitle: isAlienHud ? 'Gestures, clicks & scroll' : 'Multi-touch gesture control',
                          icon: Icons.mouse_rounded,
                          accentColor: colors.mouseAccent,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const MouseTrackpadScreen()),
                            );
                          },
                        ),
                        ModuleCard(
                          title: isAlienHud ? 'KEYBOARD' : 'Keyboard',
                          subtitle: isAlienHud ? 'Typing & shortcuts' : 'Full input & special keys',
                          icon: Icons.keyboard_rounded,
                          accentColor: colors.keyboardAccent,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const KeyboardControlScreen()),
                            );
                          },
                        ),
                        ModuleCard(
                          title: isAlienHud ? 'MEDIA CONTROLS' : 'Media',
                          subtitle: isAlienHud ? 'Playback, volume & mic' : 'Playback, volume & stream',
                          icon: Icons.play_arrow_rounded,
                          accentColor: colors.mediaAccent,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const MediaControlScreen()),
                            );
                          },
                        ),
                        ModuleCard(
                          title: isAlienHud ? 'POWER OPTIONS' : 'Power',
                          subtitle: isAlienHud ? 'Shutdown, restart, lock' : 'Sleep, restart & shutdown',
                          icon: Icons.power_settings_new_rounded,
                          accentColor: colors.powerAccent,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const PowerControlScreen()),
                            );
                          },
                        ),
                        ModuleCard(
                          title: isAlienHud ? 'FILE MANAGER' : 'Files',
                          subtitle: isAlienHud ? 'Explore & transfer files' : 'Browse PC drives & transfer',
                          icon: Icons.folder_rounded,
                          accentColor: colors.filesAccent,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const FileManagerScreen()),
                            );
                          },
                        ),
                        ModuleCard(
                          title: isAlienHud ? 'DISPLAY BRIGHTNESS' : 'Brightness',
                          subtitle: isAlienHud ? 'Display lumen control' : 'Display lumen output',
                          icon: Icons.wb_sunny_rounded,
                          accentColor: colors.brightnessAccent,
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

            // Bottom Sci-Fi Cybernetic HUD Navigation Dock
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
                      IconButton(
                        icon: HudRadarCircle(
                          size: 24,
                          color: colors.primary,
                          child: Icon(Icons.gps_fixed_rounded, color: colors.primary, size: 12),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const DeviceManagementScreen()),
                          );
                        },
                      ),
                      IconButton(
                        icon: const AlienEmblem(size: 22, hasGlow: false),
                        onPressed: () {},
                      ),
                      // Floating Giant Alien Core
                      GestureDetector(
                        onTap: () {
                          ref.read(pcRemoteRepositoryProvider).mediaPlayPause();
                        },
                        child: HudRadarCircle(
                          size: 46,
                          color: colors.primary,
                          child: const AlienEmblem(size: 28, hasGlow: true),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.bar_chart_rounded, color: colors.primary, size: 24),
                        onPressed: () {},
                      ),
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

class _HardwareToggleTile extends StatelessWidget {
  final String title;
  final bool isOn;
  final IconData icon;
  final VoidCallback onTap;

  const _HardwareToggleTile({
    required this.title,
    required this.isOn,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final themeStyle = colors.primary == const Color(0xFF00FF66);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isOn ? colors.primary.withOpacity(0.14) : colors.surfaceContainer,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isOn ? colors.primary : colors.outlineVariant.withOpacity(0.6),
              width: isOn ? 1.4 : 0.8,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isOn ? colors.primary : colors.onSurfaceVariant.withOpacity(0.6),
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: GoogleFonts.orbitron(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: isOn ? colors.primary : colors.onSurfaceVariant,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isOn ? '[ON]' : '[OFF]',
                style: GoogleFonts.shareTechMono(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: isOn ? colors.primary : colors.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HudTelemetryPod extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;

  const _HudTelemetryPod({
    required this.icon,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.orbitron(
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: 0.5,
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
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
