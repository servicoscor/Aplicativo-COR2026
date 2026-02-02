import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_config.dart';

class LocaleConfig {
  static const String _localeKey = 'app_locale';

  final SharedPreferences _prefs;

  LocaleConfig(this._prefs);

  Locale? get locale {
    final value = _prefs.getString(_localeKey);
    if (value == null || value.isEmpty) return null;
    return _parseLocale(value);
  }

  Future<void> setLocale(Locale locale) async {
    await _prefs.setString(_localeKey, _serializeLocale(locale));
  }

  Future<void> clearLocale() async {
    await _prefs.remove(_localeKey);
  }

  static String _serializeLocale(Locale locale) {
    final country = locale.countryCode;
    return country == null || country.isEmpty
        ? locale.languageCode
        : '${locale.languageCode}-$country';
  }

  static Locale? _parseLocale(String value) {
    final parts = value.split(RegExp(r'[-_]'));
    if (parts.isEmpty) return null;
    final language = parts[0];
    final country = parts.length > 1 ? parts[1] : null;
    return country == null || country.isEmpty ? Locale(language) : Locale(language, country);
  }
}

const List<Locale> supportedAppLocales = [
  Locale('pt', 'BR'),
  Locale('en'),
  Locale('es'),
  Locale('zh', 'CN'),
];

final localeConfigProvider = Provider<LocaleConfig>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleConfig(prefs);
});

class LocaleController extends StateNotifier<Locale> {
  final LocaleConfig _config;

  LocaleController(this._config) : super(_config.locale ?? const Locale('pt', 'BR')) {
    _config.setLocale(state);
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _config.setLocale(locale);
  }
}

final localeProvider = StateNotifierProvider<LocaleController, Locale>((ref) {
  final config = ref.watch(localeConfigProvider);
  return LocaleController(config);
});
