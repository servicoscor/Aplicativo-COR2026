import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/models/models.dart';
import '../../../core/services/cache_service.dart';

/// Resultado de uma requisição com info de cache
class CachedResult<T> {
  final T data;
  final bool fromCache;
  final int? cacheAgeMinutes;

  CachedResult({
    required this.data,
    this.fromCache = false,
    this.cacheAgeMinutes,
  });
}

/// Repositório para dados do mapa com suporte a cache
class MapRepository {
  final ApiClient _apiClient;
  final CacheService _cacheService;

  MapRepository(this._apiClient, this._cacheService);

  /// Busca dados do radar (cache-first)
  Future<RadarResponse> getRadarLatest() async {
    const cacheKey = CacheKeys.radar;

    try {
      // Tenta buscar da rede
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/v1/weather/radar/latest',
      );

      // Parse response
      final data = _parseRadarResponse(response);

      // Salva no cache
      await _cacheService.set(cacheKey, response);

      return data;
    } catch (e) {
      if (kDebugMode) print('Erro ao buscar radar da rede: $e');

      // Tenta usar cache
      final cached = _cacheService.getData(cacheKey);
      if (cached != null) {
        if (kDebugMode) print('Usando cache do radar');
        final data = _parseRadarResponse(cached);
        return RadarResponse(
          current: data.current,
          previous: data.previous,
          metadata: data.metadata,
          isStale: true,
        );
      }

      rethrow;
    }
  }

  /// Busca pluviômetros (cache-first)
  Future<RainGaugeResponse> getRainGauges() async {
    const cacheKey = CacheKeys.rainGauges;

    try {
      // Tenta buscar da rede
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/v1/rain-gauges',
      );

      // Parse response
      final data = _parseRainGaugeResponse(response);

      // Salva no cache
      await _cacheService.set(cacheKey, response);

      return data;
    } catch (e) {
      if (kDebugMode) print('Erro ao buscar pluviômetros da rede: $e');

      // Tenta usar cache
      final cached = _cacheService.getData(cacheKey);
      if (cached != null) {
        if (kDebugMode) print('Usando cache dos pluviômetros');
        final data = _parseRainGaugeResponse(cached);
        return RainGaugeResponse(
          stations: data.stations,
          summary: data.summary,
          isStale: true,
        );
      }

      rethrow;
    }
  }

  /// Busca sirenes (cache-first)
  Future<SirensResponse> getSirens() async {
    const cacheKey = CacheKeys.sirens;

    try {
      // Tenta buscar da rede
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/v1/sirens',
      );

      // Parse response
      final data = _parseSirensResponse(response);

      // Salva no cache
      await _cacheService.set(cacheKey, response);

      return data;
    } catch (e) {
      if (kDebugMode) print('Erro ao buscar sirenes da rede: $e');

      // Tenta usar cache
      final cached = _cacheService.getData(cacheKey);
      if (cached != null) {
        if (kDebugMode) print('Usando cache das sirenes');
        final data = _parseSirensResponse(cached);
        return SirensResponse(
          sirens: data.sirens,
          summary: data.summary,
          dataTimestamp: data.dataTimestamp,
          isStale: true,
        );
      }

      rethrow;
    }
  }

  /// Busca incidentes (cache-first)
  Future<IncidentResponse> getIncidents({
    double? north,
    double? south,
    double? east,
    double? west,
    List<String>? types,
    DateTime? since,
  }) async {
    const cacheKey = CacheKeys.incidents;

    final queryParams = <String, dynamic>{};

    // Adiciona bbox se fornecido
    if (north != null && south != null && east != null && west != null) {
      queryParams['bbox'] = '$west,$south,$east,$north';
    }

    // Adiciona tipos se fornecido
    if (types != null && types.isNotEmpty) {
      queryParams['type'] = types.join(',');
    }

    // Adiciona since se fornecido
    if (since != null) {
      queryParams['since'] = since.toIso8601String();
    }

    try {
      // Tenta buscar da rede
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/v1/incidents',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      // Parse response
      final data = _parseIncidentResponse(response);

      // Salva no cache (apenas se não houver filtros)
      if (queryParams.isEmpty) {
        await _cacheService.set(cacheKey, response);
      }

      return data;
    } catch (e) {
      if (kDebugMode) print('Erro ao buscar incidentes da rede: $e');

      // Tenta usar cache
      final cached = _cacheService.getData(cacheKey);
      if (cached != null) {
        if (kDebugMode) print('Usando cache dos incidentes');
        final data = _parseIncidentResponse(cached);
        return IncidentResponse(
          incidents: data.incidents,
          summary: data.summary,
          isStale: true,
        );
      }

      rethrow;
    }
  }

  /// Busca clima atual do Alerta Rio (cache-first)
  Future<Weather> getWeatherNow() async {
    const cacheKey = CacheKeys.weather;

    try {
      // Tenta buscar da rede (Alerta Rio)
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/v1/alerta-rio/forecast/now',
      );

      // Parse response do Alerta Rio para Weather
      final data = _parseAlertaRioWeatherResponse(response);

      // Salva no cache
      await _cacheService.set(cacheKey, response);

      return data;
    } catch (e) {
      if (kDebugMode) print('Erro ao buscar clima da rede: $e');

      // Tenta usar cache
      final cached = _cacheService.getData(cacheKey);
      if (cached != null) {
        if (kDebugMode) print('Usando cache do clima');
        final data = _parseAlertaRioWeatherResponse(cached);
        return Weather(
          temperature: data.temperature,
          feelsLike: data.feelsLike,
          humidity: data.humidity,
          pressure: data.pressure,
          windSpeed: data.windSpeed,
          windDirection: data.windDirection,
          visibility: data.visibility,
          uvIndex: data.uvIndex,
          condition: data.condition,
          conditionIcon: data.conditionIcon,
          timestamp: data.timestamp,
          isStale: true,
        );
      }

      rethrow;
    }
  }

  /// Busca previsão completa do Alerta Rio (sempre retorna dados)
  Future<AlertaRioForecast> getAlertaRioForecast() async {
    const cacheKey = CacheKeys.weather;

    // Sempre tenta buscar da rede primeiro para ter dados atualizados
    try {
      if (kDebugMode) print('[AlertaRioForecast] Buscando da rede...');
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/v1/alerta-rio/forecast/now',
      );
      if (kDebugMode) {
        print('[AlertaRioForecast] Resposta da rede recebida');
      }
      await _cacheService.set(cacheKey, response);
      final forecast = AlertaRioForecast.fromJson(response);
      if (kDebugMode) {
        print('[AlertaRioForecast] Parseado da rede:');
        print('  - items: ${forecast.items.length}');
        print('  - temperatures: ${forecast.temperatures.length}');
        print('  - synoptic: ${forecast.synoptic != null}');
        print('  - tides: ${forecast.tides.length}');
      }
      return forecast;
    } catch (e) {
      if (kDebugMode) {
        print('[AlertaRioForecast] Erro ao buscar da rede: $e');
      }
    }

    // Fallback: tenta do cache
    final cached = _cacheService.getData(cacheKey);
    if (cached != null) {
      if (kDebugMode) {
        print('[AlertaRioForecast] Usando cache...');
      }
      try {
        final forecast = AlertaRioForecast.fromJson(cached);
        if (kDebugMode) {
          print('[AlertaRioForecast] Parseado do cache:');
          print('  - items: ${forecast.items.length}');
          print('  - temperatures: ${forecast.temperatures.length}');
        }
        return AlertaRioForecast(
          city: forecast.city,
          updatedAt: forecast.updatedAt,
          items: forecast.items,
          synoptic: forecast.synoptic,
          temperatures: forecast.temperatures,
          tides: forecast.tides,
          isStale: true,
        );
      } catch (e) {
        if (kDebugMode) {
          print('[AlertaRioForecast] Erro ao parsear cache: $e');
        }
      }
    }

    // Último fallback: retorna objeto vazio (nunca null)
    if (kDebugMode) {
      print('[AlertaRioForecast] Retornando objeto vazio');
    }
    return AlertaRioForecast(
      city: 'Rio de Janeiro',
      updatedAt: null,
      items: [],
      synoptic: null,
      temperatures: [],
      tides: [],
      isStale: true,
    );
  }

  /// Busca incidentes por bbox (sem cache, para uso com BboxFetchManager)
  Future<IncidentResponse> getIncidentsByBbox({
    required double north,
    required double south,
    required double east,
    required double west,
  }) async {
    final queryParams = <String, dynamic>{
      'bbox': '$west,$south,$east,$north',
    };

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/v1/incidents',
        queryParameters: queryParams,
      );
      return _parseIncidentResponse(response);
    } catch (e) {
      if (kDebugMode) print('Erro ao buscar incidentes por bbox: $e');
      rethrow;
    }
  }

  /// Busca pluviômetros por bbox (sem cache, para uso com BboxFetchManager)
  Future<RainGaugeResponse> getRainGaugesByBbox({
    required double north,
    required double south,
    required double east,
    required double west,
  }) async {
    final queryParams = <String, dynamic>{
      'bbox': '$west,$south,$east,$north',
    };

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/v1/rain-gauges',
        queryParameters: queryParams,
      );
      return _parseRainGaugeResponse(response);
    } catch (e) {
      if (kDebugMode) print('Erro ao buscar pluviômetros por bbox: $e');
      rethrow;
    }
  }

  /// Busca sirenes por bbox (sem cache, para uso com BboxFetchManager)
  Future<SirensResponse> getSirensByBbox({
    required double north,
    required double south,
    required double east,
    required double west,
  }) async {
    final queryParams = <String, dynamic>{
      'bbox': '$west,$south,$east,$north',
    };

    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/v1/sirens',
        queryParameters: queryParams,
      );
      return _parseSirensResponse(response);
    } catch (e) {
      if (kDebugMode) print('Erro ao buscar sirenes por bbox: $e');
      rethrow;
    }
  }

  /// Busca previsão (cache-first)
  Future<ForecastResponse> getForecast({int hours = 48}) async {
    const cacheKey = CacheKeys.forecast;

    try {
      // Tenta buscar da rede
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/v1/weather/forecast',
        queryParameters: {'hours': hours},
      );

      // Parse response
      final data = _parseForecastResponse(response);

      // Salva no cache
      await _cacheService.set(cacheKey, response);

      return data;
    } catch (e) {
      if (kDebugMode) print('Erro ao buscar previsão da rede: $e');

      // Tenta usar cache
      final cached = _cacheService.getData(cacheKey);
      if (cached != null) {
        if (kDebugMode) print('Usando cache da previsão');
        final data = _parseForecastResponse(cached);
        return ForecastResponse(
          hourly: data.hourly,
          isStale: true,
        );
      }

      rethrow;
    }
  }

  // ============== Cache-First Loading ==============

  /// Carrega dados do cache primeiro, depois atualiza da rede
  /// Retorna dados do cache imediatamente se disponível
  Future<T?> getCachedFirst<T>(
    String cacheKey,
    T Function(Map<String, dynamic>) parser,
  ) async {
    final cached = _cacheService.getData(cacheKey);
    if (cached != null) {
      return parser(cached);
    }
    return null;
  }

  /// Obtém idade do cache em minutos
  int? getCacheAgeMinutes(String key) {
    return _cacheService.getCacheAgeMinutes(key);
  }

  /// Obtém idade formatada do cache
  String? getCacheAgeFormatted(String key) {
    return _cacheService.getCacheAgeFormatted(key);
  }

  /// Verifica se cache está stale
  bool isCacheStale(String key) {
    return _cacheService.isStale(key);
  }

  /// Obtém idade máxima entre caches principais
  int? getMaxCacheAgeMinutes() {
    return _cacheService.getMaxCacheAgeMinutes();
  }

  // ============== Parsers ==============

  RadarResponse _parseRadarResponse(Map<String, dynamic> response) {
    // Passa a resposta completa para que fromJson tenha acesso a previous_snapshots e metadata
    return RadarResponse.fromJson(response);
  }

  RainGaugeResponse _parseRainGaugeResponse(Map<String, dynamic> response) {
    // Usa o factory method do modelo que já sabe lidar com diferentes formatos
    return RainGaugeResponse.fromJson(response);
  }

  SirensResponse _parseSirensResponse(Map<String, dynamic> response) {
    // Usa o factory method do modelo que já sabe lidar com diferentes formatos
    return SirensResponse.fromJson(response);
  }

  IncidentResponse _parseIncidentResponse(Map<String, dynamic> response) {
    final data = response['data'] ?? response;
    final incidents = data is List ? data : (data['incidents'] ?? data['items'] ?? []);
    final summary = response['summary'];

    return IncidentResponse(
      incidents: (incidents as List).map((e) => Incident.fromJson(e)).toList(),
      summary: summary != null ? IncidentSummary.fromJson(summary) : null,
    );
  }

  Weather _parseWeatherResponse(Map<String, dynamic> response) {
    final data = response['data'] ?? response;
    return Weather.fromJson(data);
  }

  /// Parser específico para resposta do Alerta Rio
  Weather _parseAlertaRioWeatherResponse(Map<String, dynamic> response) {
    final data = response['data'] ?? response;

    // Extrai temperatura média das zonas
    double temperature = 25.0; // Valor padrão
    final temperatures = data['temperatures'] as List?;
    if (temperatures != null && temperatures.isNotEmpty) {
      double sumTemp = 0;
      int count = 0;
      for (final zone in temperatures) {
        final min = (zone['temp_min'] as num?)?.toDouble() ?? 0;
        final max = (zone['temp_max'] as num?)?.toDouble() ?? 0;
        if (min > 0 || max > 0) {
          sumTemp += (min + max) / 2;
          count++;
        }
      }
      if (count > 0) {
        temperature = sumTemp / count;
      }
    }

    // Extrai condição do período atual
    String? condition;
    String? conditionIcon;
    String? precipitation;
    String? windDirectionStr;
    String? windSpeedStr;
    DateTime? timestamp;

    final items = data['items'] as List?;
    if (items != null && items.isNotEmpty) {
      // Pega o primeiro item (período atual)
      final currentPeriod = items[0] as Map<String, dynamic>;
      condition = currentPeriod['condition'] as String?;
      conditionIcon = currentPeriod['condition_icon'] as String?;
      precipitation = currentPeriod['precipitation'] as String?;
      windDirectionStr = currentPeriod['wind_direction'] as String?;
      windSpeedStr = currentPeriod['wind_speed'] as String?;
    }

    // Converte velocidade do vento descritiva para numérica (km/h aproximado)
    double windSpeed = _parseWindSpeedDescription(windSpeedStr);

    // Converte direção do vento para graus
    int windDirection = _parseWindDirection(windDirectionStr);

    // Extrai timestamp
    final updatedAt = data['updated_at'] as String?;
    if (updatedAt != null) {
      timestamp = DateTime.tryParse(updatedAt);
    }

    // Adiciona precipitação à condição se houver
    String displayCondition = condition ?? 'Desconhecido';
    if (precipitation != null && precipitation.isNotEmpty && precipitation != 'Sem chuva') {
      displayCondition = '$displayCondition - $precipitation';
    }

    return Weather(
      temperature: temperature,
      feelsLike: temperature, // Alerta Rio não fornece sensação térmica
      humidity: 0, // Alerta Rio não fornece umidade - será escondido no widget
      pressure: 0, // Alerta Rio não fornece pressão
      windSpeed: windSpeed,
      windDirection: windDirection,
      visibility: null,
      uvIndex: null, // Alerta Rio não fornece UV
      condition: displayCondition,
      conditionIcon: conditionIcon,
      timestamp: timestamp,
      isStale: response['stale'] ?? false,
    );
  }

  /// Converte descrição de velocidade do vento para km/h
  double _parseWindSpeedDescription(String? description) {
    if (description == null || description.isEmpty) return 0;

    final lower = description.toLowerCase();

    // Valores aproximados baseados na escala Beaufort adaptada
    if (lower.contains('calmo') || lower.contains('calm')) return 0;
    if (lower.contains('fraco a moderado')) return 15;
    if (lower.contains('fraco')) return 10;
    if (lower.contains('moderado a forte')) return 35;
    if (lower.contains('moderado')) return 25;
    if (lower.contains('forte')) return 45;
    if (lower.contains('muito forte')) return 60;

    return 15; // Valor padrão
  }

  /// Converte direção do vento para graus
  int _parseWindDirection(String? direction) {
    if (direction == null || direction.isEmpty) return 0;

    final upper = direction.toUpperCase().replaceAll(' ', '');

    // Mapeamento de direções compostas para graus
    const directionMap = {
      'N': 0,
      'NNE': 22,
      'N/NE': 22,
      'NE': 45,
      'ENE': 67,
      'E/NE': 67,
      'E': 90,
      'ESE': 112,
      'E/SE': 112,
      'SE': 135,
      'SSE': 157,
      'S/SE': 157,
      'S': 180,
      'SSW': 202,
      'S/SW': 202,
      'SW': 225,
      'WSW': 247,
      'W/SW': 247,
      'W': 270,
      'WNW': 292,
      'W/NW': 292,
      'NW': 315,
      'NNW': 337,
      'N/NW': 337,
    };

    return directionMap[upper] ?? 0;
  }

  ForecastResponse _parseForecastResponse(Map<String, dynamic> response) {
    final data = response['data'] ?? response;
    return ForecastResponse.fromJson(data);
  }
}

/// Provider do repositório
final mapRepositoryProvider = Provider<MapRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final cacheService = ref.watch(cacheServiceProvider);
  return MapRepository(apiClient, cacheService);
});
