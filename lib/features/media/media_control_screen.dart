import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/system_models.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_colors.dart';

class MediaControlScreen extends ConsumerStatefulWidget {
  const MediaControlScreen({super.key});

  @override
  ConsumerState<MediaControlScreen> createState() => _MediaControlScreenState();
}

class _MediaControlScreenState extends ConsumerState<MediaControlScreen> {
  double _currentVolume = 40;
  Timer? _volumeDebounceTimer;
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();
    final systemInfo = ref.read(systemInfoProvider).value;
    if (systemInfo != null) {
      _currentVolume = systemInfo.volume.toDouble();
    }
  }

  void _triggerHaptic() {
    final haptics = ref.read(hapticsProvider);
    if (haptics) {
      HapticFeedback.lightImpact();
    }
  }

  void _onVolumeSliderChanged(double val) {
    setState(() => _currentVolume = val);
    _volumeDebounceTimer?.cancel();
    _volumeDebounceTimer = Timer(const Duration(milliseconds: 80), () {
      final repo = ref.read(pcRemoteRepositoryProvider);
      // Send volume change (or custom volume level)
      // If server supports volume level, or repeated steps
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
    final repo = ref.watch(pcRemoteRepositoryProvider);
    final systemInfo = ref.watch(systemInfoProvider).value ?? const HostSystemInfo();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Media Controls'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Now Playing Artwork / Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      AppColors.surfaceContainerHigh,
                      AppColors.surfaceContainer,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.outlineVariant, width: 0.8),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        color: AppColors.mediaAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.mediaAccent.withOpacity(0.4),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.music_note_rounded,
                        size: 64,
                        color: AppColors.mediaAccent,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      systemInfo.activeMediaTitle ?? 'Now Playing on PC',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      systemInfo.activeMediaArtist ?? 'System Media Session',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Playback Controls Row (Previous, Play/Pause, Next)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Previous Track
                  IconButton.filledTonal(
                    iconSize: 32,
                    padding: const EdgeInsets.all(16),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceContainerHigh,
                      foregroundColor: AppColors.onSurface,
                    ),
                    icon: const Icon(Icons.skip_previous_rounded),
                    onPressed: () {
                      _triggerHaptic();
                      repo.mediaPrevious();
                    },
                  ),
                  const SizedBox(width: 24),

                  // Large Play / Pause button
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.mediaAccent,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.mediaAccent.withOpacity(0.35),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: IconButton(
                      iconSize: 40,
                      color: Colors.black,
                      icon: Icon(
                        systemInfo.isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                      onPressed: () {
                        _triggerHaptic();
                        repo.mediaPlayPause();
                      },
                    ),
                  ),
                  const SizedBox(width: 24),

                  // Next Track
                  IconButton.filledTonal(
                    iconSize: 32,
                    padding: const EdgeInsets.all(16),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surfaceContainerHigh,
                      foregroundColor: AppColors.onSurface,
                    ),
                    icon: const Icon(Icons.skip_next_rounded),
                    onPressed: () {
                      _triggerHaptic();
                      repo.mediaNext();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // Volume Controls Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.outlineVariant, width: 0.8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.volume_up_rounded, color: AppColors.mediaAccent),
                            SizedBox(width: 8),
                            Text(
                              'Master Volume',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${_currentVolume.toInt()}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.mediaAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        GestureDetector(
                          onTapDown: (_) => _startVolumeHold(isUp: false),
                          onTapUp: (_) => _stopVolumeHold(),
                          onTapCancel: () => _stopVolumeHold(),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.volume_down_rounded, size: 20),
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: _currentVolume,
                            min: 0,
                            max: 100,
                            activeColor: AppColors.mediaAccent,
                            inactiveColor: AppColors.surfaceContainerHighest,
                            onChanged: _onVolumeSliderChanged,
                          ),
                        ),
                        GestureDetector(
                          onTapDown: (_) => _startVolumeHold(isUp: true),
                          onTapUp: (_) => _stopVolumeHold(),
                          onTapCancel: () => _stopVolumeHold(),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerHigh,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.volume_up_rounded, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Mute & Mic Toggles
              Row(
                children: [
                  Expanded(
                    child: _MediaToggleCard(
                      title: systemInfo.isMuted ? 'Unmute Audio' : 'Mute Audio',
                      isActive: systemInfo.isMuted,
                      activeColor: AppColors.error,
                      icon: systemInfo.isMuted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      onTap: () {
                        _triggerHaptic();
                        if (systemInfo.isMuted) {
                          repo.mediaUnmute();
                        } else {
                          repo.mediaMute();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _MediaToggleCard(
                      title: systemInfo.isMicMuted ? 'Mic Muted' : 'Mic Live',
                      isActive: systemInfo.isMicMuted,
                      activeColor: AppColors.error,
                      icon: systemInfo.isMicMuted
                          ? Icons.mic_off_rounded
                          : Icons.mic_rounded,
                      onTap: () {
                        _triggerHaptic();
                        if (systemInfo.isMicMuted) {
                          repo.mediaMicOn();
                        } else {
                          repo.mediaMicOff();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaToggleCard extends StatelessWidget {
  final String title;
  final bool isActive;
  final Color activeColor;
  final IconData icon;
  final VoidCallback onTap;

  const _MediaToggleCard({
    required this.title,
    required this.isActive,
    required this.activeColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withOpacity(0.15) : AppColors.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive ? activeColor : AppColors.outlineVariant,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isActive ? activeColor : AppColors.onSurface,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isActive ? activeColor : AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
