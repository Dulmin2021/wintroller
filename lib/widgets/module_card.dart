import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_providers.dart';
import '../theme/app_colors.dart';
import 'alien_icons.dart';
import 'hud_frame.dart';

class ModuleCard extends ConsumerWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;
  final String? badgeText;

  const ModuleCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    this.badgeText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final themeStyle = ref.watch(themeStyleProvider);

    if (themeStyle == AppThemeStyle.alienHud) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: colors.primary.withOpacity(0.2),
          child: HudFrame(
            chamferSize: 16,
            borderColor: colors.primary,
            backgroundColor: colors.surfaceContainer,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Stack(
              children: [
                if (badgeText != null)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        border: Border.all(color: colors.primary.withOpacity(0.6), width: 0.8),
                        borderRadius: BorderRadius.circular(4),
                        color: colors.primary.withOpacity(0.12),
                      ),
                      child: Text(
                        badgeText!,
                        style: GoogleFonts.orbitron(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: colors.primary,
                        ),
                      ),
                    ),
                  ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    HudRadarCircle(
                      size: 58,
                      color: colors.primary,
                      child: Icon(
                        icon,
                        color: colors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title.toUpperCase(),
                      style: GoogleFonts.orbitron(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: colors.primary,
                        letterSpacing: 0.6,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.rajdhani(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurfaceVariant,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        splashColor: accentColor.withOpacity(0.12),
        highlightColor: accentColor.withOpacity(0.08),
        child: Ink(
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colors.outlineVariant.withOpacity(0.7),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        icon,
                        color: accentColor,
                        size: 26,
                      ),
                    ),
                    if (badgeText != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badgeText!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
