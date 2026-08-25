import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/device_models.dart';

class StorageService {
  static const String _keyDevices = 'paired_devices';
  static const String _keyDefaultDeviceId = 'default_device_id';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyHaptics = 'haptics_enabled';
  static const String _keyAutoReconnect = 'auto_reconnect';
  static const String _keyOnboardingDone = 'onboarding_completed';

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  StorageService(this._prefs, this._secureStorage);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    const secureStorage = FlutterSecureStorage();
    return StorageService(prefs, secureStorage);
  }

  // Devices
  List<PairedDevice> getPairedDevices() {
    final raw = _prefs.getString(_keyDevices);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = json.decode(raw) as List;
      return list.map((e) => PairedDevice.fromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> savePairedDevices(List<PairedDevice> devices) async {
    final raw = json.encode(devices.map((e) => e.toMap()).toList());
    await _prefs.setString(_keyDevices, raw);
  }

  Future<void> addOrUpdateDevice(PairedDevice device) async {
    final devices = getPairedDevices();
    final index = devices.indexWhere((d) => d.id == device.id || d.ip == device.ip);
    if (index >= 0) {
      devices[index] = device;
    } else {
      devices.add(device);
    }
    await savePairedDevices(devices);
    if (device.token != null) {
      await _secureStorage.write(key: 'token_${device.id}', value: device.token);
    }
  }

  Future<void> removeDevice(String deviceId) async {
    final devices = getPairedDevices().where((d) => d.id != deviceId).toList();
    await savePairedDevices(devices);
    await _secureStorage.delete(key: 'token_$deviceId');
    if (getDefaultDeviceId() == deviceId) {
      await _prefs.remove(_keyDefaultDeviceId);
    }
  }

  String? getDefaultDeviceId() => _prefs.getString(_keyDefaultDeviceId);

  Future<void> setDefaultDeviceId(String id) async {
    await _prefs.setString(_keyDefaultDeviceId, id);
  }

  Future<String?> getDeviceToken(String deviceId) async {
    return await _secureStorage.read(key: 'token_$deviceId');
  }

  static const String _keyThemeStyle = 'theme_style';

  // Preferences
  String getThemeMode() => _prefs.getString(_keyThemeMode) ?? 'dark';
  Future<void> setThemeMode(String mode) async => _prefs.setString(_keyThemeMode, mode);

  String getThemeStyle() => _prefs.getString(_keyThemeStyle) ?? 'stitch_cyber';
  Future<void> setThemeStyle(String style) async => _prefs.setString(_keyThemeStyle, style);

  bool getHapticsEnabled() => _prefs.getBool(_keyHaptics) ?? true;
  Future<void> setHapticsEnabled(bool enabled) async => _prefs.setBool(_keyHaptics, enabled);

  bool getAutoReconnect() => _prefs.getBool(_keyAutoReconnect) ?? true;
  Future<void> setAutoReconnect(bool enabled) async => _prefs.setBool(_keyAutoReconnect, enabled);

  bool isOnboardingDone() => _prefs.getBool(_keyOnboardingDone) ?? false;
  Future<void> setOnboardingDone(bool done) async => _prefs.setBool(_keyOnboardingDone, done);
}
