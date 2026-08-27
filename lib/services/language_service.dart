import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import 'storage_service.dart';

class AppLanguage {
  final String code;
  final String name;
  final String nativeName;
  final String country;
  final String flagEmoji;

  const AppLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.country,
    required this.flagEmoji,
  });
}

const List<AppLanguage> supportedLanguages = [
  AppLanguage(code: 'en', name: 'English', nativeName: 'English', country: 'United States', flagEmoji: '🇺🇸'),
  AppLanguage(code: 'es', name: 'Spanish', nativeName: 'Español', country: 'Spain / Latin America', flagEmoji: '🇪🇸'),
  AppLanguage(code: 'fr', name: 'French', nativeName: 'Français', country: 'France', flagEmoji: '🇫🇷'),
  AppLanguage(code: 'de', name: 'German', nativeName: 'Deutsch', country: 'Germany', flagEmoji: '🇩🇪'),
  AppLanguage(code: 'it', name: 'Italian', nativeName: 'Italiano', country: 'Italy', flagEmoji: '🇮🇹'),
  AppLanguage(code: 'ja', name: 'Japanese', nativeName: '日本語', country: 'Japan', flagEmoji: '🇯🇵'),
  AppLanguage(code: 'ko', name: 'Korean', nativeName: '한국어', country: 'South Korea', flagEmoji: '🇰🇷'),
  AppLanguage(code: 'zh', name: 'Chinese (Simplified)', nativeName: '简体中文', country: 'China', flagEmoji: '🇨🇳'),
  AppLanguage(code: 'hi', name: 'Hindi', nativeName: 'हिन्दी', country: 'India', flagEmoji: '🇮🇳'),
  AppLanguage(code: 'pt', name: 'Portuguese', nativeName: 'Português', country: 'Brazil / Portugal', flagEmoji: '🇧🇷'),
  AppLanguage(code: 'ru', name: 'Russian', nativeName: 'Русский', country: 'Russia', flagEmoji: '🇷🇺'),
  AppLanguage(code: 'ar', name: 'Arabic', nativeName: 'العربية', country: 'Arab World', flagEmoji: '🇸🇦'),
];

class LanguageNotifier extends StateNotifier<Locale> {
  final StorageService _storage;

  LanguageNotifier(this._storage) : super(Locale(_storage.getLanguageCode())) {
    final savedCode = _storage.getLanguageCode();
    state = Locale(savedCode);
  }

  Future<void> setLanguage(String languageCode) async {
    await _storage.setLanguageCode(languageCode);
    state = Locale(languageCode);
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, Locale>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return LanguageNotifier(storage);
});
