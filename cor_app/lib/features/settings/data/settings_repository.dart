import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/models/models.dart';
import '../../../core/config/app_config.dart';

/// Repositório de configurações e diagnóstico
class SettingsRepository {
  final ApiClient _apiClient;
  final SharedPreferences _prefs;

  static const _pushTokenKey = 'push_token';
  static const _devTokenKey = 'dev_push_token';
  static const _deviceIdKey = 'device_id';
  static const _locationEnabledKey = 'location_enabled';
  static const _notificationsEnabledKey = 'notifications_enabled';
  static const _lastRegisterTimestampKey = 'last_register_timestamp';
  static const _lastRegisterSuccessKey = 'last_register_success';

  SettingsRepository(this._apiClient, this._prefs);

  // ============== Push Token ==============

  /// Obtém push token armazenado (ou token de desenvolvimento se não houver)
  String? get pushToken {
    final token = _prefs.getString(_pushTokenKey);
    if (token != null && token.isNotEmpty) return token;
    // Fallback para token de desenvolvimento
    return _prefs.getString(_devTokenKey);
  }

  /// Gera e salva token de desenvolvimento único para o dispositivo
  Future<String> getOrCreateDevToken() async {
    var devToken = _prefs.getString(_devTokenKey);
    if (devToken != null && devToken.isNotEmpty) return devToken;

    // Gera token único baseado no dispositivo
    final deviceInfo = DeviceInfoPlugin();
    String deviceId;

    if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      deviceId = iosInfo.identifierForVendor ?? DateTime.now().millisecondsSinceEpoch.toString();
    } else {
      final androidInfo = await deviceInfo.androidInfo;
      deviceId = androidInfo.id;
    }

    devToken = 'dev_${deviceId}_${DateTime.now().millisecondsSinceEpoch}';
    await _prefs.setString(_devTokenKey, devToken);

    if (kDebugMode) {
      print('🔧 Token de desenvolvimento criado: $devToken');
    }

    return devToken;
  }

  /// Salva push token
  Future<void> savePushToken(String token) async {
    await _prefs.setString(_pushTokenKey, token);
  }

  /// Obtém device ID armazenado
  String? get deviceId => _prefs.getString(_deviceIdKey);

  /// Salva device ID
  Future<void> saveDeviceId(String id) async {
    await _prefs.setString(_deviceIdKey, id);
  }

  // ============== Preferências ==============

  /// Verifica se localização está habilitada nas preferências
  bool get isLocationEnabled => _prefs.getBool(_locationEnabledKey) ?? true;

  /// Define preferência de localização
  Future<void> setLocationEnabled(bool enabled) async {
    await _prefs.setBool(_locationEnabledKey, enabled);
  }

  /// Verifica se notificações estão habilitadas nas preferências
  bool get areNotificationsEnabled => _prefs.getBool(_notificationsEnabledKey) ?? true;

  /// Define preferência de notificações
  Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(_notificationsEnabledKey, enabled);
  }

  // ============== Diagnóstico ==============

  /// Obtém timestamp do último register bem-sucedido
  DateTime? get lastRegisterTimestamp {
    final timestamp = _prefs.getInt(_lastRegisterTimestampKey);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  /// Salva timestamp do último register
  Future<void> _saveLastRegisterTimestamp(bool success) async {
    await _prefs.setInt(_lastRegisterTimestampKey, DateTime.now().millisecondsSinceEpoch);
    await _prefs.setBool(_lastRegisterSuccessKey, success);
  }

  /// Verifica se o último register foi bem-sucedido
  bool get lastRegisterSuccess => _prefs.getBool(_lastRegisterSuccessKey) ?? false;

  /// Verifica se possui FCM Token
  bool get hasFcmToken => pushToken != null && pushToken!.isNotEmpty;

  // ============== API ==============

  /// Verifica saúde da API
  Future<HealthResponse> checkHealth() async {
    final response = await _apiClient.get<Map<String, dynamic>>('/v1/health');
    return HealthResponse.fromJson(response);
  }

  /// Registra dispositivo no backend
  /// Retorna null se não houver pushToken válido
  Future<Device?> registerDevice({
    required String pushToken,
    List<String>? neighborhoods,
  }) async {
    // Validação: só registra se tiver token
    if (pushToken.isEmpty) {
      return null;
    }

    final platform = Platform.isIOS ? 'ios' : 'android';

    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/v1/devices/register',
        data: {
          'platform': platform,
          'push_token': pushToken,
          if (neighborhoods != null && neighborhoods.isNotEmpty)
            'neighborhoods': neighborhoods,
        },
      );

      // Salva timestamp de sucesso
      await _saveLastRegisterTimestamp(true);
      return Device.fromJson(response);
    } catch (e) {
      // Salva timestamp de falha
      await _saveLastRegisterTimestamp(false);
      rethrow;
    }
  }

  /// Atualiza localização do dispositivo
  Future<void> updateDeviceLocation({
    required double latitude,
    required double longitude,
  }) async {
    final token = pushToken;
    if (token == null) return;

    await _apiClient.post<Map<String, dynamic>>(
      '/v1/devices/location',
      data: {
        'lat': latitude,
        'lon': longitude,
      },
      headers: {'X-Push-Token': token},
    );
  }

  /// Obtém informações do dispositivo
  Future<Device?> getDeviceInfo() async {
    final token = pushToken;
    if (token == null) return null;

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/v1/devices/me',
        headers: {'X-Push-Token': token},
      );
      return Device.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}

/// Provider do repositório
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsRepository(apiClient, prefs);
});
