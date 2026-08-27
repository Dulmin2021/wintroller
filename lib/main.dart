import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/pairing/pairing_discover_screen.dart';
import 'providers/app_providers.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'widgets/floating_nova_button.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize persistent storage and secure storage
  final storageService = await StorageService.init();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
      ],
      child: const WintrollerApp(),
    ),
  );
}

class WintrollerApp extends ConsumerStatefulWidget {
  const WintrollerApp({super.key});

  @override
  ConsumerState<WintrollerApp> createState() => _WintrollerAppState();
}

class _WintrollerAppState extends ConsumerState<WintrollerApp> {
  late final Widget _initialHome;

  @override
  void initState() {
    super.initState();
    // Cache the initial home widget so MaterialApp does not replace the Navigator on theme rebuilds
    _initialHome = _getInitialHome();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoConnectIfAvailable();
    });
  }

  void _autoConnectIfAvailable() {
    final storage = ref.read(storageServiceProvider);
    if (!storage.getAutoReconnect()) return;

    final devices = storage.getPairedDevices();
    if (devices.isEmpty) return;

    final defaultId = storage.getDefaultDeviceId();
    final targetDevice = devices.firstWhere(
      (d) => d.id == defaultId || d.isDefault,
      orElse: () => devices.first,
    );

    ref.read(activeDeviceProvider.notifier).state = targetDevice;
    ref.read(pairedDevicesProvider.notifier).connectToDevice(targetDevice);
  }

  Widget _getInitialHome() {
    final storage = ref.read(storageServiceProvider);
    if (!storage.isOnboardingDone()) {
      return const OnboardingScreen();
    }

    final devices = storage.getPairedDevices();
    if (devices.isNotEmpty) {
      return const DashboardScreen();
    }

    return const PairingDiscoverScreen();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final themeStyle = ref.watch(themeStyleProvider);

    final ThemeData activeDarkTheme;
    switch (themeStyle) {
      case AppThemeStyle.alienHud:
        activeDarkTheme = AppTheme.alienHudTheme;
        break;
      case AppThemeStyle.stitchCyber:
        activeDarkTheme = AppTheme.stitchCyberTheme;
        break;
      case AppThemeStyle.midnight:
        activeDarkTheme = AppTheme.midnightTheme;
        break;
    }

    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'Wintroller',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: activeDarkTheme,
      themeMode: themeMode,
      home: _initialHome,
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            const GlobalFloatingNovaButton(),
          ],
        );
      },
    );
  }
}
