import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/device_models.dart';
import '../models/system_models.dart';
import '../models/file_models.dart';
import '../services/storage_service.dart';
import '../services/discovery_service.dart';
import '../services/websocket_service.dart';
import '../services/pcremote_repository.dart';

// Storage Provider (must be overridden in main with initialized instance)
final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('storageServiceProvider must be initialized');
});

// Discovery Provider
final discoveryServiceProvider = Provider<DiscoveryService>((ref) {
  final service = DiscoveryService();
  ref.onDispose(() => service.dispose());
  return service;
});

// WebSocket Provider
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  final storage = ref.watch(storageServiceProvider);
  service.setAutoReconnect(storage.getAutoReconnect());
  ref.onDispose(() => service.dispose());
  return service;
});

// Repository Provider
final pcRemoteRepositoryProvider = Provider<PCRemoteRepository>((ref) {
  final wsService = ref.watch(webSocketServiceProvider);
  final repo = PCRemoteRepository(wsService);
  ref.onDispose(() => repo.dispose());
  return repo;
});

// Streams
final connectionStatusProvider = StreamProvider<ConnectionStatus>((ref) {
  final repo = ref.watch(pcRemoteRepositoryProvider);
  return repo.connectionStatusStream;
});

final systemInfoProvider = StreamProvider<HostSystemInfo>((ref) {
  final repo = ref.watch(pcRemoteRepositoryProvider);
  return repo.systemInfoStream;
});

final transferProgressProvider = StreamProvider<TransferProgress>((ref) {
  final repo = ref.watch(pcRemoteRepositoryProvider);
  return repo.transferProgressStream;
});

// Paired Devices Notifier
class PairedDevicesNotifier extends StateNotifier<List<PairedDevice>> {
  final StorageService _storage;
  final WebSocketService _wsService;

  PairedDevicesNotifier(this._storage, this._wsService)
      : super(_storage.getPairedDevices());

  Future<void> addDevice(PairedDevice device) async {
    await _storage.addOrUpdateDevice(device);
    state = _storage.getPairedDevices();
  }

  Future<void> removeDevice(String deviceId) async {
    await _storage.removeDevice(deviceId);
    state = _storage.getPairedDevices();
  }

  Future<void> setDefaultDevice(String deviceId) async {
    await _storage.setDefaultDeviceId(deviceId);
    state = [
      for (final d in state)
        d.copyWith(isDefault: d.id == deviceId)
    ];
  }

  Future<void> connectToDevice(PairedDevice device) async {
    await _storage.addOrUpdateDevice(
      device.copyWith(lastConnected: DateTime.now()),
    );
    state = _storage.getPairedDevices();
    await _wsService.connect(device);
  }
}

final pairedDevicesProvider =
    StateNotifierProvider<PairedDevicesNotifier, List<PairedDevice>>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final wsService = ref.watch(webSocketServiceProvider);
  return PairedDevicesNotifier(storage, wsService);
});

// Active Device Provider
final activeDeviceProvider = StateProvider<PairedDevice?>((ref) {
  final wsService = ref.watch(webSocketServiceProvider);
  return wsService.activeDevice;
});

// Settings Notifiers
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final StorageService _storage;

  ThemeModeNotifier(this._storage) : super(_loadMode(_storage.getThemeMode()));

  static ThemeMode _loadMode(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      case 'dark':
      default:
        return ThemeMode.dark;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _storage.setThemeMode(mode.name);
  }
}

enum AppThemeStyle {
  stitchCyber,
  midnight,
}

class ThemeStyleNotifier extends StateNotifier<AppThemeStyle> {
  final StorageService _storage;

  ThemeStyleNotifier(this._storage) : super(_loadStyle(_storage.getThemeStyle()));

  static AppThemeStyle _loadStyle(String style) {
    switch (style) {
      case 'midnight':
        return AppThemeStyle.midnight;
      case 'stitch_cyber':
      default:
        return AppThemeStyle.stitchCyber;
    }
  }

  Future<void> setThemeStyle(AppThemeStyle style) async {
    state = style;
    await _storage.setThemeStyle(style == AppThemeStyle.midnight ? 'midnight' : 'stitch_cyber');
  }
}

final themeStyleProvider =
    StateNotifierProvider<ThemeStyleNotifier, AppThemeStyle>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ThemeStyleNotifier(storage);
});

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return ThemeModeNotifier(storage);
});

class HapticsNotifier extends StateNotifier<bool> {
  final StorageService _storage;

  HapticsNotifier(this._storage) : super(_storage.getHapticsEnabled());

  Future<void> toggle() async {
    state = !state;
    await _storage.setHapticsEnabled(state);
  }
}

final hapticsProvider = StateNotifierProvider<HapticsNotifier, bool>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return HapticsNotifier(storage);
});

class AutoReconnectNotifier extends StateNotifier<bool> {
  final StorageService _storage;
  final WebSocketService _wsService;

  AutoReconnectNotifier(this._storage, this._wsService)
      : super(_storage.getAutoReconnect());

  Future<void> toggle() async {
    state = !state;
    await _storage.setAutoReconnect(state);
    _wsService.setAutoReconnect(state);
  }
}

final autoReconnectProvider =
    StateNotifierProvider<AutoReconnectNotifier, bool>((ref) {
  final storage = ref.watch(storageServiceProvider);
  final ws = ref.watch(webSocketServiceProvider);
  return AutoReconnectNotifier(storage, ws);
});
