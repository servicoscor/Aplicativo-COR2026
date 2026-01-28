import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/models/alert_model.dart';
import '../../../core/config/app_config.dart';

/// Repositório de alertas
class AlertsRepository {
  final ApiClient _apiClient;
  final SharedPreferences _prefs;

  static const _pushTokenKey = 'push_token';

  AlertsRepository(this._apiClient, this._prefs);

  /// Obtém push token armazenado
  String? get pushToken => _prefs.getString(_pushTokenKey);

  /// Busca inbox de alertas do dispositivo
  Future<AlertInboxResponse> getInbox({
    double? latitude,
    double? longitude,
    String? severity,
    String? neighborhood,
    bool unreadOnly = false,
  }) async {
    final token = pushToken;
    if (token == null) {
      // Retorna lista vazia se não tiver token
      return AlertInboxResponse(alerts: [], total: 0);
    }

    final queryParams = <String, dynamic>{};
    if (latitude != null && longitude != null) {
      queryParams['lat'] = latitude.toString();
      queryParams['lon'] = longitude.toString();
    }
    if (severity != null) {
      queryParams['severity'] = severity;
    }
    if (neighborhood != null) {
      queryParams['neighborhood'] = neighborhood;
    }
    if (unreadOnly) {
      queryParams['unread_only'] = 'true';
    }

    final response = await _apiClient.get<Map<String, dynamic>>(
      '/v1/alerts/inbox',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
      headers: {'X-Push-Token': token},
    );

    return AlertInboxResponse.fromJson(response);
  }

  /// Marca um alerta como lido
  Future<bool> markAsRead(String alertId) async {
    final token = pushToken;
    if (token == null) {
      return false;
    }

    try {
      await _apiClient.post<Map<String, dynamic>>(
        '/v1/alerts/inbox/$alertId/read',
        headers: {'X-Push-Token': token},
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Busca detalhes de um alerta específico
  Future<Alert?> getAlert(String alertId) async {
    try {
      final token = pushToken;
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/v1/alerts/$alertId',
        headers: token != null ? {'X-Push-Token': token} : null,
      );
      return Alert.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}

/// Provider do repositório
final alertsRepositoryProvider = Provider<AlertsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return AlertsRepository(apiClient, prefs);
});
