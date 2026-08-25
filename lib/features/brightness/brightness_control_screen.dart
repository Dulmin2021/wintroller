import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/system_models.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/alien_icons.dart';
import '../../widgets/hud_frame.dart';

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
    _triggerHaptic();
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
    final colors = AppColors.of(context);
    final themeStyle = ref.watch(themeStyleProvider);
    final isAlienHud = themeStyle == AppThemeStyle.alienHud;
    final repo = ref.watch(pcRemoteRepositoryProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
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
                          isAlienHud ? 'DISPLAY_CONTROLLER' : 'Brightness Level',
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
                ],
              ),
            ),

            if (isAlienHud)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '> SYS_CTRL  /  DISPLAY_BRIGHTNESS',
                    style: GoogleFonts.shareTechMono(
                      fontSize: 11,
                      color: colors.primary,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  children: [
                    // Main Radar Brightness Pod
                    isAlienHud
                        ? HudFrame(
                            chamferSize: 18,
                            borderColor: colors.primary,
                            backgroundColor: colors.surfaceContainer,
                            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                            child: Column(
                              children: [
                                HudRadarCircle(
                                  size: 130,
                                  color: colors.primary,
                                  child: Container(
                                    width: 74,
                                    height: 74,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: colors.primary.withOpacity(0.15),
                                    ),
                                    child: Icon(
                                      Icons.wb_sunny_rounded,
                                      color: colors.primary,
                                      size: 42,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  '${_brightness.toInt()}%',
                                  style: GoogleFonts.orbitron(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: colors.primary,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'DISPLAY_LUMEN_OUTPUT',
                                  style: GoogleFonts.shareTechMono(
                                    fontSize: 11,
                                    color: colors.onSurfaceVariant,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainer,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: colors.outlineVariant, width: 0.8),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.wb_sunny_rounded, size: 64, color: colors.brightnessAccent),
                                const SizedBox(height: 16),
                                Text(
                                  '${_brightness.toInt()}%',
                                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: colors.onSurface),
                                ),
                              ],
                            ),
                          ),

                    const SizedBox(height: 20),

                    // Slider Pod
                    isAlienHud
                        ? HudFrame(
                            chamferSize: 14,
                            borderColor: colors.primary,
                            backgroundColor: colors.surfaceContainer,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'DISP_BRIGHTNESS_CTRL',
                                  style: GoogleFonts.orbitron(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: colors.primary,
                                    letterSpacing: 1.0,
                                  ),
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
                                    value: _brightness,
                                    min: 0,
                                    max: 100,
                                    onChanged: _onSliderChanged,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('MIN (0%)', style: GoogleFonts.shareTechMono(fontSize: 10, color: colors.onSurfaceVariant)),
                                    Text('MAX (100%)', style: GoogleFonts.shareTechMono(fontSize: 10, color: colors.onSurfaceVariant)),
                                  ],
                                ),
                              ],
                            ),
                          )
                        : Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainer,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: colors.outlineVariant, width: 0.8),
                            ),
                            child: Slider(
                              value: _brightness,
                              min: 0,
                              max: 100,
                              activeColor: colors.brightnessAccent,
                              onChanged: _onSliderChanged,
                            ),
                          ),

                    const SizedBox(height: 20),

                    // Quick Presets
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        isAlienHud ? 'PRESET_OUTPUTS' : 'Quick Presets',
                        style: isAlienHud
                            ? GoogleFonts.orbitron(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: colors.primary,
                                letterSpacing: 1.2,
                              )
                            : TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.onSurface),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _AlienPresetTile(
                            label: '25% LOW',
                            isSelected: _brightness.toInt() == 25,
                            onTap: () {
                              repo.brightnessLow();
                              _setPreset(25);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _AlienPresetTile(
                            label: '50% MED',
                            isSelected: _brightness.toInt() == 50,
                            onTap: () => _setPreset(50),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _AlienPresetTile(
                            label: '75% HIGH',
                            isSelected: _brightness.toInt() == 75,
                            onTap: () => _setPreset(75),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _AlienPresetTile(
                            label: '100% MAX',
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
          ],
        ),
      ),
    );
  }
}

class _AlienPresetTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _AlienPresetTile({
    required this.label,
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
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colors.primary.withOpacity(0.2) : colors.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? colors.primary : colors.outlineVariant,
              width: isSelected ? 1.5 : 0.8,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.orbitron(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: isSelected ? colors.primary : colors.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
