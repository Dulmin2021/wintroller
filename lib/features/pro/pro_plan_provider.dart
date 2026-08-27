import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ProPlanTier {
  free,
  proMonthly,
  proLifetime,
}

class ProPlanState {
  final bool isPro;
  final ProPlanTier tier;
  final String? geminiApiKey;
  final bool isApiKeyValid;
  final DateTime? proSince;

  const ProPlanState({
    this.isPro = false,
    this.tier = ProPlanTier.free,
    this.geminiApiKey,
    this.isApiKeyValid = false,
    this.proSince,
  });

  ProPlanState copyWith({
    bool? isPro,
    ProPlanTier? tier,
    String? geminiApiKey,
    bool? isApiKeyValid,
    DateTime? proSince,
  }) {
    return ProPlanState(
      isPro: isPro ?? this.isPro,
      tier: tier ?? this.tier,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      isApiKeyValid: isApiKeyValid ?? this.isApiKeyValid,
      proSince: proSince ?? this.proSince,
    );
  }
}

class ProPlanNotifier extends StateNotifier<ProPlanState> {
  final FlutterSecureStorage _storage;
  final SharedPreferences? _prefs;

  static const _keyIsPro = 'wintroller_is_pro';
  static const _keyTier = 'wintroller_pro_tier';
  static const _keyGeminiApiKey = 'wintroller_gemini_api_key';

  ProPlanNotifier(this._storage, this._prefs) : super(const ProPlanState()) {
    _loadState();
  }

  Future<void> _loadState() async {
    try {
      final isPro = _prefs?.getBool(_keyIsPro) ?? false;
      final tierName = _prefs?.getString(_keyTier) ?? ProPlanTier.free.name;
      final tier = ProPlanTier.values.firstWhere(
        (t) => t.name == tierName,
        orElse: () => ProPlanTier.free,
      );
      final apiKey = await _storage.read(key: _keyGeminiApiKey);

      state = ProPlanState(
        isPro: isPro || (apiKey != null && apiKey.trim().isNotEmpty),
        tier: isPro ? tier : (apiKey != null && apiKey.trim().isNotEmpty ? ProPlanTier.proLifetime : ProPlanTier.free),
        geminiApiKey: apiKey,
        isApiKeyValid: apiKey != null && apiKey.trim().length > 15,
      );
    } catch (_) {}
  }

  Future<void> setProStatus(bool isPro, {ProPlanTier tier = ProPlanTier.proLifetime}) async {
    await _prefs?.setBool(_keyIsPro, isPro);
    await _prefs?.setString(_keyTier, tier.name);
    state = state.copyWith(
      isPro: isPro,
      tier: isPro ? tier : ProPlanTier.free,
      proSince: isPro ? DateTime.now() : null,
    );
  }

  Future<void> setGeminiApiKey(String apiKey) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) {
      await _storage.delete(key: _keyGeminiApiKey);
      state = state.copyWith(
        geminiApiKey: null,
        isApiKeyValid: false,
      );
    } else {
      await _storage.write(key: _keyGeminiApiKey, value: cleanKey);
      state = state.copyWith(
        geminiApiKey: cleanKey,
        isApiKeyValid: cleanKey.length > 15,
        isPro: true, // Providing own API key unlocks Nova Assistant
        tier: state.tier == ProPlanTier.free ? ProPlanTier.proLifetime : state.tier,
      );
    }
  }

  Future<void> clearApiKey() async {
    await _storage.delete(key: _keyGeminiApiKey);
    state = state.copyWith(geminiApiKey: null, isApiKeyValid: false);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final proPlanProvider = StateNotifierProvider<ProPlanNotifier, ProPlanState>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return ProPlanNotifier(storage, prefs);
});
