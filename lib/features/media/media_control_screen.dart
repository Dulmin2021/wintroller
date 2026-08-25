import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/system_models.dart';
import '../../providers/app_providers.dart';
import '../../services/websocket_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/alien_icons.dart';
import '../../widgets/hud_frame.dart';
import '../devices/device_management_screen.dart';
import '../settings/settings_screen.dart';

class MediaControlScreen extends ConsumerStatefulWidget {
  const MediaControlScreen({super.key});

  @override
  ConsumerState<MediaControlScreen> createState() => _MediaControlScreenState();
}

class _MediaControlScreenState extends ConsumerState<MediaControlScreen> {
  double _currentVolume = 40;
  double _micGain = 50;
  bool _isUserDraggingVolume = false;
  Timer? _volumeDebounceTimer;
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();
    final systemInfo = ref.read(systemInfoProvider).value;
    if (systemInfo != null) {
      _currentVolume = systemInfo.volume.toDouble().clamp(0, 100);
    }
  }

  void _triggerHaptic() {
    final haptics = ref.read(hapticsProvider);
    if (haptics) {
      HapticFeedback.lightImpact();
    }
  }

  void _onVolumeSliderChanged(double val) {
    setState(() {
      _isUserDraggingVolume = true;
      _currentVolume = val;
    });
    _triggerHaptic();
    _volumeDebounceTimer?.cancel();
    _volumeDebounceTimer = Timer(const Duration(milliseconds: 30), () {
      final repo = ref.read(pcRemoteRepositoryProvider);
      repo.setVolume(val.toInt());
    });
  }

  void _onVolumeSliderChangeEnd(double val) {
    _volumeDebounceTimer?.cancel();
    final repo = ref.read(pcRemoteRepositoryProvider);
    repo.setVolume(val.toInt());
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _isUserDraggingVolume = false);
    });
  }

  void _startVolumeHold({required bool isUp}) {
    _triggerHaptic();
    final repo = ref.read(pcRemoteRepositoryProvider);
    if (isUp) {
      repo.mediaVolumeUp();
      setState(() => _currentVolume = (_currentVolume + 2).clamp(0, 100));
    } else {
      repo.mediaVolumeDown();
      setState(() => _currentVolume = (_currentVolume - 2).clamp(0, 100));
    }

    _holdTimer?.cancel();
    _holdTimer = Timer.periodic(const Duration(milliseconds: 150), (t) {
      _triggerHaptic();
      if (isUp) {
        repo.mediaVolumeUp();
        setState(() => _currentVolume = (_currentVolume + 2).clamp(0, 100));
      } else {
        repo.mediaVolumeDown();
        setState(() => _currentVolume = (_currentVolume - 2).clamp(0, 100));
      }
    });
  }

  void _stopVolumeHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  @override
  void dispose() {
    _volumeDebounceTimer?.cancel();
    _holdTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final themeStyle = ref.watch(themeStyleProvider);
    final isAlienHud = themeStyle == AppThemeStyle.alienHud;
    final repo = ref.watch(pcRemoteRepositoryProvider);
    final connectionStatus = ref.watch(connectionStatusProvider).value ?? ConnectionStatus.offline;
    final systemInfo = ref.watch(systemInfoProvider).value ?? const HostSystemInfo();

    ref.listen(systemInfoProvider, (prev, next) {
      if (!_isUserDraggingVolume && next.value != null) {
        setState(() {
          _currentVolume = next.value!.volume.toDouble().clamp(0, 100);
        });
      }
    });

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.onSurface, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 6),
                  if (isAlienHud) const AlienEmblem(size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WINTROLLER',
                          style: isAlienHud
                              ? GoogleFonts.orbitron(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: colors.primary,
                                  letterSpacing: 2.0,
                                )
                              : TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 18,
                                  color: colors.onSurface,
                                ),
                        ),
                        Text(
                          isAlienHud ? 'MEDIA_INTERFACE_V1.2' : 'Media Controller',
                          style: isAlienHud
                              ? GoogleFonts.orbitron(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  color: colors.primary.withOpacity(0.7),
                                  letterSpacing: 1.5,
                                )
                              : TextStyle(
                                  fontSize: 12,
                                  color: colors.onSurfaceVariant,
                                ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainer,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.primary, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: connectionStatus == ConnectionStatus.connected
                                ? colors.primary
                                : colors.error,
                            boxShadow: [
                              BoxShadow(color: colors.primary.withOpacity(0.8), blurRadius: 4),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          connectionStatus == ConnectionStatus.connected ? 'CONNECTED' : 'OFFLINE',
                          style: GoogleFonts.orbitron(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: connectionStatus == ConnectionStatus.connected
                                ? colors.primary
                                : colors.error,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Breadcrumb Path
            if (isAlienHud)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'SYS_ROOT  /  MODULES  /  MEDIA_CTRL',
                    style: GoogleFonts.shareTechMono(
                      fontSize: 11,
                      color: colors.onSurfaceVariant.withOpacity(0.7),
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Column(
                  children: [
                    // Card 1: MOD_03 // PLAYBACK
                    if (isAlienHud)
                      HudFrame(
                        chamferSize: 18,
                        borderColor: colors.primary,
                        backgroundColor: colors.surfaceContainer,
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child: Text(
                                'MOD_03  //  PLAYBACK',
                                style: GoogleFonts.shareTechMono(
                                  fontSize: 10,
                                  color: colors.onSurfaceVariant,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              (systemInfo.activeMediaTitle != null && systemInfo.activeMediaTitle!.isNotEmpty)
                                  ? systemInfo.activeMediaTitle!.toUpperCase()
                                  : 'DESKTOP AUDIO STREAM',
                              style: GoogleFonts.orbitron(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: colors.primary,
                                letterSpacing: 1.0,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              (systemInfo.activeMediaArtist != null && systemInfo.activeMediaArtist!.isNotEmpty)
                                  ? systemInfo.activeMediaArtist!.toUpperCase()
                                  : 'WINDOWS MEDIA SESSION',
                              style: GoogleFonts.rajdhani(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: colors.onSurfaceVariant,
                                letterSpacing: 0.8,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.music_note_rounded, color: colors.primary, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'AUDIO_STREAM',
                                  style: GoogleFonts.shareTechMono(
                                    fontSize: 10,
                                    color: colors.primary.withOpacity(0.8),
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // Holographic Radar HUD Play/Pause Target
                            GestureDetector(
                              onTap: () {
                                _triggerHaptic();
                                repo.mediaPlayPause();
                              },
                              child: HudRadarCircle(
                                size: 110,
                                color: colors.primary,
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colors.primary.withOpacity(0.15),
                                    border: Border.all(color: colors.primary, width: 1.5),
                                  ),
                                  child: Icon(
                                    systemInfo.isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: colors.primary,
                                    size: 38,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 22),

                            // Square Transport Buttons: |<<, [], >>|
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _SquareTransportButton(
                                  icon: Icons.skip_previous_rounded,
                                  onTap: () {
                                    _triggerHaptic();
                                    repo.mediaPrevious();
                                  },
                                ),
                                const SizedBox(width: 16),
                                _SquareTransportButton(
                                  icon: Icons.stop_rounded,
                                  onTap: () {
                                    _triggerHaptic();
                                    repo.mediaPlayPause();
                                  },
                                ),
                                const SizedBox(width: 16),
                                _SquareTransportButton(
                                  icon: Icons.skip_next_rounded,
                                  onTap: () {
                                    _triggerHaptic();
                                    repo.mediaNext();
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // Progress Scrubber Line
                            Row(
                              children: [
                                Text(
                                  '02:45',
                                  style: GoogleFonts.shareTechMono(
                                    fontSize: 11,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderThemeData(
                                      trackHeight: 2.5,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                      activeTrackColor: colors.primary,
                                      inactiveTrackColor: colors.outlineVariant,
                                      thumbColor: colors.primary,
                                    ),
                                    child: Slider(
                                      value: 0.45,
                                      onChanged: (_) {},
                                    ),
                                  ),
                                ),
                                Text(
                                  '-03:10',
                                  style: GoogleFonts.shareTechMono(
                                    fontSize: 11,
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainer,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: colors.outlineVariant, width: 0.8),
                        ),
                        child: Column(
                          children: [
                            Text(
                              (systemInfo.activeMediaTitle != null && systemInfo.activeMediaTitle!.isNotEmpty)
                                  ? systemInfo.activeMediaTitle!
                                  : 'Desktop Audio Stream',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: colors.onSurface),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              (systemInfo.activeMediaArtist != null && systemInfo.activeMediaArtist!.isNotEmpty)
                                  ? systemInfo.activeMediaArtist!
                                  : 'Windows Media Session',
                              style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.skip_previous_rounded, size: 36),
                                  onPressed: () {
                                    _triggerHaptic();
                                    repo.mediaPrevious();
                                  },
                                ),
                                const SizedBox(width: 16),
                                IconButton(
                                  icon: Icon(
                                    systemInfo.isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                                    size: 56,
                                    color: colors.primary,
                                  ),
                                  onPressed: () {
                                    _triggerHaptic();
                                    repo.mediaPlayPause();
                                  },
                                ),
                                const SizedBox(width: 16),
                                IconButton(
                                  icon: const Icon(Icons.skip_next_rounded, size: 36),
                                  onPressed: () {
                                    _triggerHaptic();
                                    repo.mediaNext();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 14),

                    // Card 2: LVL_CTRL // VOL
                    if (isAlienHud)
                      HudFrame(
                        chamferSize: 14,
                        borderColor: colors.primary,
                        backgroundColor: colors.surfaceContainer,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      systemInfo.isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                                      color: colors.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'MASTER_VOL',
                                      style: GoogleFonts.orbitron(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: colors.primary,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${_currentVolume.toInt()}%',
                                  style: GoogleFonts.orbitron(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: colors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 4,
                                activeTrackColor: colors.primary,
                                inactiveTrackColor: colors.outlineVariant,
                                thumbColor: colors.primary,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                              ),
                              child: Slider(
                                value: _currentVolume,
                                min: 0,
                                max: 100,
                                onChanged: _onVolumeSliderChanged,
                                onChangeEnd: _onVolumeSliderChangeEnd,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('MIN (0)', style: GoogleFonts.shareTechMono(fontSize: 10, color: colors.onSurfaceVariant)),
                                Text('MAX (100)', style: GoogleFonts.shareTechMono(fontSize: 10, color: colors.onSurfaceVariant)),
                              ],
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainer,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colors.outlineVariant, width: 0.8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Master Volume', style: TextStyle(fontWeight: FontWeight.w700)),
                                Text('${_currentVolume.toInt()}%', style: TextStyle(fontWeight: FontWeight.w800, color: colors.primary)),
                              ],
                            ),
                            Slider(
                              value: _currentVolume,
                              min: 0,
                              max: 100,
                              activeColor: colors.primary,
                              onChanged: _onVolumeSliderChanged,
                              onChangeEnd: _onVolumeSliderChangeEnd,
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 14),

                    // Card 3: LVL_CTRL // MIC
                    if (isAlienHud)
                      HudFrame(
                        chamferSize: 14,
                        borderColor: colors.primary,
                        backgroundColor: colors.surfaceContainer,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      systemInfo.isMicMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                                      color: colors.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'MIC_GAIN',
                                      style: GoogleFonts.orbitron(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: colors.primary,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${_micGain.toInt()}%',
                                  style: GoogleFonts.orbitron(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: colors.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 4,
                                activeTrackColor: colors.primary,
                                inactiveTrackColor: colors.outlineVariant,
                                thumbColor: colors.primary,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                              ),
                              child: Slider(
                                value: _micGain,
                                min: 0,
                                max: 100,
                                onChanged: (val) {
                                  _triggerHaptic();
                                  setState(() => _micGain = val);
                                },
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('MIN (0)', style: GoogleFonts.shareTechMono(fontSize: 10, color: colors.onSurfaceVariant)),
                                Text('MAX (100)', style: GoogleFonts.shareTechMono(fontSize: 10, color: colors.onSurfaceVariant)),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom Sci-Fi Cybernetic Dock
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
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      // Selected Play Active Core
                      GestureDetector(
                        onTap: () {
                          _triggerHaptic();
                          repo.mediaPlayPause();
                        },
                        child: HudRadarCircle(
                          size: 44,
                          color: colors.primary,
                          child: Icon(
                            systemInfo.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: colors.primary,
                            size: 26,
                          ),
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

class _SquareTransportButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SquareTransportButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: colors.primary.withOpacity(0.25),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: colors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.primary.withOpacity(0.6), width: 1),
          ),
          child: Icon(icon, color: colors.primary, size: 22),
        ),
      ),
    );
  }
}
