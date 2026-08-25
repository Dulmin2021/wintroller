import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_dialog.dart';

class PowerControlScreen extends ConsumerStatefulWidget {
  const PowerControlScreen({super.key});

  @override
  ConsumerState<PowerControlScreen> createState() => _PowerControlScreenState();
}

class _PowerControlScreenState extends ConsumerState<PowerControlScreen> {
  bool _isBusy = false;

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
    final repo = ref.watch(pcRemoteRepositoryProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        title: Text(
          'Power Controls',
          style: TextStyle(color: colors.onSurface, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: colors.outlineVariant, width: 0.8),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.powerAccent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.power_settings_new_rounded,
                        color: colors.powerAccent,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'System Power Control',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Destructive actions like Shutdown and Restart will request confirmation.',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              Text(
                'Instant Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _PowerActionTile(
                      title: 'Lock Screen',
                      subtitle: 'Lock Windows workspace',
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PowerActionTile(
                      title: 'Sleep Mode',
                      subtitle: 'Enter low-power state',
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
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _PowerActionTile(
                      title: 'Hibernate',
                      subtitle: 'Save state & turn off',
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PowerActionTile(
                      title: 'Log Off',
                      subtitle: 'Sign out current user',
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
                ],
              ),

              const SizedBox(height: 28),
              Text(
                'Destructive Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colors.powerAccent,
                ),
              ),
              const SizedBox(height: 12),

              _DestructiveActionTile(
                title: 'Restart Computer',
                subtitle: 'Reboot Windows operating system',
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
                title: 'Shut Down Computer',
                subtitle: 'Turn off your PC completely',
                icon: Icons.power_settings_new_rounded,
                color: colors.powerAccent,
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
                  child: CircularProgressIndicator(color: colors.powerAccent),
                ),
              ],
            ],
          ),
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
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.outlineVariant, width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
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
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withOpacity(0.4), width: 1),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
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
