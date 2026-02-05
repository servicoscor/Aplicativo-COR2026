import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/app_config.dart';

/// Modelo de bairro
class Neighborhood {
  final String name;
  final String displayName;

  Neighborhood({required this.name, required this.displayName});

  factory Neighborhood.fromJson(Map<String, dynamic> json) {
    return Neighborhood(
      name: json['name'] ?? '',
      displayName: json['display_name'] ?? json['name'] ?? '',
    );
  }
}

/// Repositório de subscriptions (bairros inscritos para alertas)
class SubscriptionsRepository {
  final ApiClient _apiClient;
  final SharedPreferences _prefs;

  static const _pushTokenKey = 'push_token';
  static const _syncWithFavoritesKey = 'sync_subscriptions_with_favorites';
  static const _subscriptionsKey = 'subscribed_neighborhoods_local';

  SubscriptionsRepository(this._apiClient, this._prefs);

  /// Obtém push token armazenado
  String? get pushToken => _prefs.getString(_pushTokenKey);

  /// Verifica se sincronização com favoritos está ativa
  bool get syncWithFavorites => _prefs.getBool(_syncWithFavoritesKey) ?? true;

  /// Define sincronização com favoritos
  Future<void> setSyncWithFavorites(bool value) async {
    await _prefs.setBool(_syncWithFavoritesKey, value);
  }

  /// Obtém subscriptions salvas localmente
  List<String> get localSubscriptions =>
      _prefs.getStringList(_subscriptionsKey) ?? [];

  /// Salva subscriptions localmente
  Future<void> setLocalSubscriptions(List<String> neighborhoods) async {
    await _prefs.setStringList(_subscriptionsKey, neighborhoods);
  }

  /// Busca lista de bairros do Rio de Janeiro
  Future<List<Neighborhood>> getNeighborhoods() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/v1/reference/neighborhoods',
      );

      final data = response['data'] as List? ?? [];
      return data.map((e) => Neighborhood.fromJson(e)).toList();
    } catch (e) {
      // Retorna lista vazia em caso de erro
      return [];
    }
  }

  /// Busca bairros inscritos do dispositivo
  Future<List<String>> getSubscriptions() async {
    final token = pushToken;
    if (token == null) {
      return localSubscriptions;
    }

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/v1/devices/subscriptions',
        headers: {'X-Push-Token': token},
      );

      final neighborhoods = response['subscribed_neighborhoods'] as List? ?? [];
      final remote = neighborhoods.cast<String>();
      if (remote.isEmpty && localSubscriptions.isNotEmpty) {
        return localSubscriptions;
      }
      return remote;
    } catch (e) {
      return localSubscriptions;
    }
  }

  /// Atualiza bairros inscritos do dispositivo
  Future<bool> updateSubscriptions(List<String> neighborhoods) async {
    final token = pushToken;
    await setLocalSubscriptions(neighborhoods);
    if (token == null) {
      return true;
    }

    try {
      await _apiClient.post<Map<String, dynamic>>(
        '/v1/devices/subscriptions',
        data: {'subscribed_neighborhoods': neighborhoods},
        headers: {'X-Push-Token': token},
      );
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Provider do repositório
final subscriptionsRepositoryProvider = Provider<SubscriptionsRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return SubscriptionsRepository(apiClient, prefs);
});
