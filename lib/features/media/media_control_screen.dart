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
    final repo = ref.watch(pcRemoteRepositoryProvider);
    final systemInfo = ref.watch(systemInfoProvider).value ?? const HostSystemInfo();

    ref.listen(systemInfoProvider, (prev, next) {
      if (!_isUserDraggingVolume && next.value != null) {
        setState(() {
          _currentVolume = next.value!.volume.toDouble().clamp(0, 100);
        });
      }
    });

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
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.surfaceContainerHigh,
                      AppColors.surfaceContainer,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.outlineVariant.withOpacity(0.8),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            AppColors.mediaAccent.withOpacity(0.3),
                            AppColors.surfaceContainerLowest,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.mediaAccent.withOpacity(0.6),
                          width: 1.5,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.music_note_rounded,
                          size: 64,
                          color: AppColors.mediaAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      (systemInfo.activeMediaTitle != null && systemInfo.activeMediaTitle!.isNotEmpty)
                          ? systemInfo.activeMediaTitle!
                          : 'Desktop Audio',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      (systemInfo.activeMediaArtist != null && systemInfo.activeMediaArtist!.isNotEmpty)
                          ? systemInfo.activeMediaArtist!
                          : 'Windows Media Session',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Playback Transport Controls (Prev / Play-Pause / Next)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _PlaybackCircleButton(
                    icon: Icons.skip_previous_rounded,
                    size: 56,
                    iconSize: 30,
                    onPressed: () {
                      _triggerHaptic();
                      repo.mediaPrevious();
                    },
                  ),
                  const SizedBox(width: 24),
                  _PlaybackCircleButton(
                    icon: systemInfo.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 76,
                    iconSize: 42,
                    isPrimary: true,
                    onPressed: () {
                      _triggerHaptic();
                      repo.mediaPlayPause();
                    },
                  ),
                  const SizedBox(width: 24),
                  _PlaybackCircleButton(
                    icon: Icons.skip_next_rounded,
                    size: 56,
                    iconSize: 30,
                    onPressed: () {
                      _triggerHaptic();
                      repo.mediaNext();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

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
                            onChangeEnd: _onVolumeSliderChangeEnd,
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

class _PlaybackCircleButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _PlaybackCircleButton({
    required this.icon,
    required this.size,
    required this.iconSize,
    this.isPrimary = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isPrimary ? AppColors.mediaAccent : AppColors.surfaceContainerHigh,
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: AppColors.mediaAccent.withOpacity(0.4),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: IconButton(
        icon: Icon(icon),
        iconSize: iconSize,
        color: isPrimary ? Colors.black : AppColors.onSurface,
        onPressed: onPressed,
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
