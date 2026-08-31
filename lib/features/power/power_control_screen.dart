import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/app_providers.dart';
import '../../services/biometric_service.dart';
import '../../services/storage_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/alien_icons.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/hud_frame.dart';

class PowerControlScreen extends ConsumerStatefulWidget {
  const PowerControlScreen({super.key});

  @override
  ConsumerState<PowerControlScreen> createState() => _PowerControlScreenState();
}

class _PowerControlScreenState extends ConsumerState<PowerControlScreen> {
  bool _isBusy = false;

  void _handleUnlockPc() async {
    final storage = ref.read(storageServiceProvider);
    final repo = ref.read(pcRemoteRepositoryProvider);
    final bio = ref.read(biometricServiceProvider);
    final colors = AppColors.of(context);

    final savedPin = await storage.getWindowsPin();

    if (savedPin == null || savedPin.isEmpty) {
      if (!mounted) return;
      final pinController = TextEditingController();
      bool saveForFuture = true;

      final enteredPin = await showDialog<String>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            backgroundColor: const Color(0xFF131B2E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.lock_open_rounded, color: Color(0xFF00FF66)),
                const SizedBox(width: 8),
                Text(
                  'Unlock Windows PC',
                  style: GoogleFonts.orbitron(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFFDAE2FD)),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter your Windows login PIN or password to remotely unlock the desktop lock screen:',
                  style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFFC2C6D6)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: pinController,
                  obscureText: true,
                  autofocus: true,
                  style: GoogleFonts.shareTechMono(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Enter Windows PIN / Password',
                    hintStyle: const TextStyle(color: Color(0xFF8C909F), fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF222A3D),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: saveForFuture,
                  title: Text(
                    'Save PIN securely for biometric unlock',
                    style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFDAE2FD)),
                  ),
                  activeColor: const Color(0xFF00FF66),
                  onChanged: (val) {
                    setDialogState(() => saveForFuture = val ?? true);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF8C909F))),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF66),
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  final pin = pinController.text.trim();
                  if (saveForFuture && pin.isNotEmpty) {
                    storage.setWindowsPin(pin);
                  }
                  Navigator.of(ctx).pop(pin);
                },
                child: const Text('Unlock PC', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
      );

      if (enteredPin == null || enteredPin.isEmpty) return;

      setState(() => _isBusy = true);
      final success = await repo.unlockPc(enteredPin);
      if (mounted) setState(() => _isBusy = false);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Remote unlock sequence executed!' : 'Failed to execute unlock sequence'),
          backgroundColor: success ? colors.tertiaryContainer : colors.errorContainer,
        ),
      );
    } else {
      // Prompt Biometric Authentication
      final authenticated = await bio.authenticate(
        localizedReason: 'Scan fingerprint or Face ID to unlock your Windows PC',
      );

      if (!authenticated) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric authentication cancelled or failed'),
            backgroundColor: Color(0xFF93000A),
          ),
        );
        return;
      }

      setState(() => _isBusy = true);
      final success = await repo.unlockPc(savedPin);
      if (mounted) setState(() => _isBusy = false);

      if (!mounted) return;
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.lock_open_rounded, color: Color(0xFF00FF66), size: 20),
              const SizedBox(width: 8),
              const Expanded(child: Text('PC Unlocked via Fingerprint!')),
            ],
          ),
          backgroundColor: const Color(0xFF131B2E),
        ),
      );
    }
  }

  void _executePowerAction({
    required String title,
    required String message,
    required String confirmLabel,
    required bool requiresConfirm,
    required Future<dynamic> Function() action,
  }) async {
    final colors = AppColors.of(context);

    if (requiresConfirm) {
      final confirmed = await AppDialog.showConfirmAction(
        context: context,
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        confirmColor: colors.powerAccent,
        icon: Icons.power_settings_new_rounded,
      );
      if (!confirmed) return;
    }

    setState(() => _isBusy = true);

    try {
      final response = await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.success
                ? '$title command dispatched successfully'
                : 'Failed: ${response.error ?? "Unknown error"}',
          ),
          backgroundColor: response.success
              ? colors.tertiaryContainer
              : colors.errorContainer,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: colors.errorContainer,
        ),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
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
                          isAlienHud ? 'POWER_INTERFACE_V1.0' : 'Power Management',
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
                    '> SYS_CTRL  /  POWER_MANAGEMENT',
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Radar Card
                    isAlienHud
                        ? HudFrame(
                            chamferSize: 16,
                            borderColor: colors.primary,
                            backgroundColor: colors.surfaceContainer,
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                HudRadarCircle(
                                  size: 64,
                                  color: colors.primary,
                                  child: Icon(
                                    Icons.power_settings_new_rounded,
                                    color: colors.primary,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'SYSTEM POWER PROTOCOLS',
                                        style: GoogleFonts.orbitron(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: colors.primary,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Instant execution & confirmation locks for destructive tasks.',
                                        style: GoogleFonts.rajdhani(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: colors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
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
                            child: Row(
                              children: [
                                Icon(Icons.power_settings_new_rounded, color: colors.powerAccent, size: 32),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'System Power Control',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ),

                    const SizedBox(height: 22),

                    Text(
                      isAlienHud ? 'INSTANT_EXEC_ACTIONS' : 'Instant Actions',
                      style: isAlienHud
                          ? GoogleFonts.orbitron(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: colors.primary,
                              letterSpacing: 1.2,
                            )
                          : TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.onSurface),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _PowerActionTile(
                            title: isAlienHud ? 'UNLOCK_PC_SESSION' : 'Unlock PC',
                            subtitle: 'Fingerprint & PIN login',
                            icon: Icons.fingerprint_rounded,
                            color: const Color(0xFF00FF66),
                            onTap: _handleUnlockPc,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PowerActionTile(
                            title: isAlienHud ? 'LOCK_WORKSPACE' : 'Lock Screen',
                            subtitle: 'Lock Windows user session',
                            icon: Icons.lock_outline_rounded,
                            color: colors.primary,
                            onTap: () => _executePowerAction(
                              title: 'Lock Screen',
                              message: 'Lock the active Windows user session?',
                              confirmLabel: 'Lock',
                              requiresConfirm: false,
                              action: () => repo.lock(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _PowerActionTile(
                            title: isAlienHud ? 'SLEEP_MODE' : 'Sleep Mode',
                            subtitle: 'Enter low-power suspend state',
                            icon: Icons.bedtime_outlined,
                            color: colors.secondary,
                            onTap: () => _executePowerAction(
                              title: 'Sleep Mode',
                              message: 'Put your computer into sleep state?',
                              confirmLabel: 'Sleep',
                              requiresConfirm: false,
                              action: () => repo.sleep(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PowerActionTile(
                            title: isAlienHud ? 'HIBERNATE_SYS' : 'Hibernate',
                            subtitle: 'Save RAM state to disk & off',
                            icon: Icons.mode_night_rounded,
                            color: colors.tertiary,
                            onTap: () => _executePowerAction(
                              title: 'Hibernate',
                              message: 'Save open documents and hibernate your PC?',
                              confirmLabel: 'Hibernate',
                              requiresConfirm: false,
                              action: () => repo.hibernate(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _PowerActionTile(
                            title: isAlienHud ? 'LOG_OFF_USER' : 'Log Off',
                            subtitle: 'Sign out active user session',
                            icon: Icons.logout_rounded,
                            color: colors.mediaAccent,
                            onTap: () => _executePowerAction(
                              title: 'Log Off',
                              message: 'Are you sure you want to sign out? Any unsaved work may be lost.',
                              confirmLabel: 'Sign Out',
                              requiresConfirm: true,
                              action: () => repo.logoff(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PowerActionTile(
                            title: isAlienHud ? 'DISPLAY_OFF' : 'Turn Display Off',
                            subtitle: 'Put monitor into power-saving off mode',
                            icon: Icons.tv_off_rounded,
                            color: colors.primary,
                            onTap: () => _executePowerAction(
                              title: 'Turn Display Off',
                              message: 'Turn off monitor power?',
                              confirmLabel: 'Display Off',
                              requiresConfirm: false,
                              action: () => repo.setDisplay(false),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _PowerActionTile(
                            title: isAlienHud ? 'DISPLAY_OFF' : 'Turn Display Off',
                            subtitle: 'Put monitor into power-saving off mode',
                            icon: Icons.tv_off_rounded,
                            color: colors.primary,
                            onTap: () => _executePowerAction(
                              title: 'Turn Display Off',
                              message: 'Turn off monitor power?',
                              confirmLabel: 'Display Off',
                              requiresConfirm: false,
                              action: () => repo.setDisplay(false),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _PowerActionTile(
                            title: isAlienHud ? 'DISPLAY_WAKE' : 'Wake Display',
                            subtitle: 'Wake up PC display monitor',
                            icon: Icons.tv_rounded,
                            color: colors.secondary,
                            onTap: () => _executePowerAction(
                              title: 'Wake Display',
                              message: 'Wake monitor display?',
                              confirmLabel: 'Wake',
                              requiresConfirm: false,
                              action: () => repo.setDisplay(true),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Text(
                      isAlienHud ? 'DESTRUCTIVE_OPERATIONS' : 'Destructive Actions',
                      style: isAlienHud
                          ? GoogleFonts.orbitron(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: colors.error,
                              letterSpacing: 1.2,
                            )
                          : TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.error),
                    ),
                    const SizedBox(height: 12),

                    _DestructiveActionTile(
                      title: isAlienHud ? 'RESTART_SYSTEM_REBOOT' : 'Restart Computer',
                      subtitle: 'Reboot Windows operating system immediately',
                      icon: Icons.restart_alt_rounded,
                      color: const Color(0xFFFF7043),
                      onTap: () => _executePowerAction(
                        title: 'Restart Computer',
                        message: 'This will close all open applications and reboot your PC immediately.',
                        confirmLabel: 'Restart Now',
                        requiresConfirm: true,
                        action: () => repo.restart(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    _DestructiveActionTile(
                      title: isAlienHud ? 'TERMINATE_POWER_SHUTDOWN' : 'Shut Down Computer',
                      subtitle: 'Power down PC hardware completely',
                      icon: Icons.power_settings_new_rounded,
                      color: colors.error,
                      onTap: () => _executePowerAction(
                        title: 'Shut Down Computer',
                        message: 'Are you sure you want to shut down your PC? All running programs will be stopped.',
                        confirmLabel: 'Shut Down',
                        requiresConfirm: true,
                        action: () => repo.shutdown(),
                      ),
                    ),

                    if (_isBusy) ...[
                      const SizedBox(height: 24),
                      Center(
                        child: CircularProgressIndicator(color: colors.primary),
                      ),
                    ],
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

class _PowerActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PowerActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: colors.primary.withOpacity(0.2),
        child: HudFrame(
          chamferSize: 12,
          borderColor: colors.primary.withOpacity(0.5),
          backgroundColor: colors.surfaceContainer,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colors.primary, size: 24),
              const SizedBox(height: 10),
              Text(
                title,
                style: GoogleFonts.orbitron(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: colors.primary,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.rajdhani(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DestructiveActionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DestructiveActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: color.withOpacity(0.2),
        child: HudFrame(
          chamferSize: 12,
          borderColor: color.withOpacity(0.8),
          backgroundColor: color.withOpacity(0.06),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.orbitron(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.rajdhani(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
