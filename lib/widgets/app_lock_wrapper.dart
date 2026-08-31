import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/app_providers.dart';
import '../services/biometric_service.dart';
import '../theme/app_colors.dart';
import 'alien_icons.dart';
import 'hud_frame.dart';

final appLockedStateProvider = StateProvider<bool>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return storage.isBiometricAppLockEnabled();
});

class AppLockWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const AppLockWrapper({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<AppLockWrapper> createState() => _AppLockWrapperState();
}

class _AppLockWrapperState extends ConsumerState<AppLockWrapper> with WidgetsBindingObserver {
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isLocked = ref.read(appLockedStateProvider);
      if (isLocked) {
        _triggerBiometricAuth();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final isLockEnabled = ref.read(storageServiceProvider).isBiometricAppLockEnabled();
      if (isLockEnabled) {
        ref.read(appLockedStateProvider.notifier).state = true;
      }
    } else if (state == AppLifecycleState.resumed) {
      final isLocked = ref.read(appLockedStateProvider);
      if (isLocked) {
        _triggerBiometricAuth();
      }
    }
  }

  Future<void> _triggerBiometricAuth() async {
    if (_isAuthenticating) return;
    setState(() => _isAuthenticating = true);

    final bio = ref.read(biometricServiceProvider);
    final success = await bio.authenticate(
      localizedReason: 'Scan fingerprint or Face ID to unlock Wintroller',
    );

    if (mounted) {
      setState(() => _isAuthenticating = false);
      if (success) {
        HapticFeedback.mediumImpact();
        ref.read(appLockedStateProvider.notifier).state = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = ref.watch(appLockedStateProvider);
    final colors = AppColors.of(context);

    if (!isLocked) {
      return widget.child;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF040D06),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing Cyber Shield
                HudRadarCircle(
                  size: 110,
                  color: const Color(0xFF00FF66),
                  child: const AlienEmblem(size: 60, hasGlow: true),
                ),
                const SizedBox(height: 30),

                Text(
                  'WINTROLLER SECURED',
                  style: GoogleFonts.orbitron(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF00FF66),
                    letterSpacing: 2.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                Text(
                  'Biometric authentication is active. Verify identity to access PC remote controls.',
                  style: GoogleFonts.rajdhani(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFDAE2FD).withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Unlock Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    icon: _isAuthenticating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Icon(Icons.fingerprint_rounded, color: Colors.black, size: 26),
                    label: Text(
                      _isAuthenticating ? 'AUTHENTICATING...' : 'UNLOCK WITH BIOMETRICS',
                      style: GoogleFonts.orbitron(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        letterSpacing: 1.2,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FF66),
                      elevation: 8,
                      shadowColor: const Color(0xFF00FF66).withOpacity(0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isAuthenticating ? null : _triggerBiometricAuth,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
