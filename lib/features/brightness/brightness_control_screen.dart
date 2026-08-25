import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/system_models.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_colors.dart';

class BrightnessControlScreen extends ConsumerStatefulWidget {
  const BrightnessControlScreen({super.key});

  @override
  ConsumerState<BrightnessControlScreen> createState() =>
      _BrightnessControlScreenState();
}

class _BrightnessControlScreenState
    extends ConsumerState<BrightnessControlScreen> {
  double _brightness = 75;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    final systemInfo = ref.read(systemInfoProvider).value;
    if (systemInfo != null) {
      _brightness = systemInfo.brightness.toDouble();
    }
  }

  void _triggerHaptic() {
    if (ref.read(hapticsProvider)) {
      HapticFeedback.selectionClick();
    }
  }

  void _onSliderChanged(double val) {
    setState(() => _brightness = val);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      ref.read(pcRemoteRepositoryProvider).setBrightness(_brightness.toInt());
    });
  }

  void _setPreset(int value) {
    _triggerHaptic();
    setState(() => _brightness = value.toDouble());
    ref.read(pcRemoteRepositoryProvider).setBrightness(value);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(pcRemoteRepositoryProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Brightness Controls'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Visual Indicator Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
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
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.brightnessAccent
                                .withOpacity((_brightness / 100).clamp(0.1, 0.4)),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.brightnessAccent
                                    .withOpacity((_brightness / 100).clamp(0.1, 0.5)),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          _brightness > 50
                              ? Icons.brightness_high_rounded
                              : _brightness > 20
                                  ? Icons.brightness_medium_rounded
                                  : Icons.brightness_low_rounded,
                          size: 72,
                          color: AppColors.brightnessAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      '${_brightness.toInt()}%',
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: AppColors.onSurface,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Display Output Level',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Slider Card
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
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Fine Adjustment',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Icon(Icons.tune_rounded, color: AppColors.onSurfaceVariant, size: 20),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.brightness_low_rounded,
                            color: AppColors.onSurfaceVariant, size: 22),
                        Expanded(
                          child: Slider(
                            value: _brightness,
                            min: 0,
                            max: 100,
                            activeColor: AppColors.brightnessAccent,
                            inactiveColor: AppColors.surfaceContainerHighest,
                            onChanged: _onSliderChanged,
                          ),
                        ),
                        const Icon(Icons.brightness_high_rounded,
                            color: AppColors.brightnessAccent, size: 22),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Quick Presets',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Preset Buttons
              Row(
                children: [
                  Expanded(
                    child: _PresetButton(
                      label: 'Low (25%)',
                      isSelected: _brightness.toInt() == 25,
                      onTap: () {
                        repo.brightnessLow();
                        _setPreset(25);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PresetButton(
                      label: 'Medium (50%)',
                      isSelected: _brightness.toInt() == 50,
                      onTap: () => _setPreset(50),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PresetButton(
                      label: 'High (100%)',
                      isSelected: _brightness.toInt() == 100,
                      onTap: () {
                        repo.brightnessHigh();
                        _setPreset(100);
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

class _PresetButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? AppColors.brightnessAccent.withOpacity(0.2)
            : AppColors.surfaceContainer,
        foregroundColor: isSelected
            ? AppColors.brightnessAccent
            : AppColors.onSurface,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? AppColors.brightnessAccent : AppColors.outlineVariant,
            width: 1,
          ),
        ),
        elevation: 0,
      ),
      onPressed: onTap,
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
      ),
    );
  }
}
