import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Configuração do app com BASE_URL configurável
class AppConfig {
  static const String _baseUrlKey = 'base_url';

  /// URL padrão baseada na plataforma
  static String get defaultBaseUrl {
    return 'http://187.111.99.18:8001/api';
  }

  final SharedPreferences _prefs;

  AppConfig(this._prefs);

  /// Obtém a BASE_URL configurada ou usa o padrão
  String get baseUrl {
    return _prefs.getString(_baseUrlKey) ?? defaultBaseUrl;
  }

  /// Define uma nova BASE_URL
  Future<void> setBaseUrl(String url) async {
    // Remove trailing slash se houver
    final cleanUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    await _prefs.setString(_baseUrlKey, cleanUrl);
  }

  /// Reseta para o valor padrão
  Future<void> resetBaseUrl() async {
    await _prefs.remove(_baseUrlKey);
  }

  /// Verifica se está usando URL customizada
  bool get isCustomUrl => _prefs.containsKey(_baseUrlKey);
}

/// Provider para SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences deve ser inicializado antes do app');
});

/// Provider para AppConfig
final appConfigProvider = Provider<AppConfig>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppConfig(prefs);
});

/// Provider reativo para BASE_URL (notifica mudanças)
final baseUrlProvider = StateProvider<String>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.baseUrl;
});
