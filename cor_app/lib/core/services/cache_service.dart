import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Chaves de cache
class CacheKeys {
  static const String weather = 'weather';
  static const String forecast = 'forecast';
  static const String radar = 'radar';
  static const String incidents = 'incidents';
  static const String rainGauges = 'rain_gauges';
  static const String sirens = 'sirens';
  static const String alertsInbox = 'alerts_inbox';

  /// Box name para dados de cache
  static const String cacheBox = 'cor_cache';

  /// Box name para metadados de cache
  static const String metadataBox = 'cor_cache_metadata';

  /// Todas as chaves de cache
  static const List<String> allKeys = [
    weather,
    forecast,
    radar,
    incidents,
    rainGauges,
    sirens,
    alertsInbox,
  ];
}

/// Configuracao de limites de staleness (em minutos)
class CacheConfig {
  /// Limites de "staleness" por tipo de dado (em minutos)
  static const Map<String, int> staleThresholds = {
    CacheKeys.weather: 5,
    CacheKeys.forecast: 15,
    CacheKeys.radar: 3,
    CacheKeys.incidents: 2,
    CacheKeys.rainGauges: 3,
    CacheKeys.sirens: 2,
    CacheKeys.alertsInbox: 5,
  };

  /// Limite apos o qual dados sao considerados "muito antigos" (em minutos)
  static const Map<String, int> outdatedThresholds = {
    CacheKeys.weather: 15,
    CacheKeys.forecast: 60,
    CacheKeys.radar: 10,
    CacheKeys.incidents: 10,
    CacheKeys.rainGauges: 10,
    CacheKeys.sirens: 10,
    CacheKeys.alertsInbox: 30,
  };

  /// Limite padrao de staleness
  static const int defaultStaleThreshold = 5;

  /// Limite padrao de outdated
  static const int defaultOutdatedThreshold = 15;
}

/// Metadata de bbox para cache
class CacheBbox {
  final double north;
  final double south;
  final double east;
  final double west;

  const CacheBbox({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });

  Map<String, dynamic> toJson() => {
        'north': north,
        'south': south,
        'east': east,
        'west': west,
      };

  factory CacheBbox.fromJson(Map<String, dynamic> json) {
    return CacheBbox(
      north: (json['north'] as num).toDouble(),
      south: (json['south'] as num).toDouble(),
      east: (json['east'] as num).toDouble(),
      west: (json['west'] as num).toDouble(),
    );
  }
}

/// Entrada de cache com timestamp e metadata
class CacheEntry {
  final String data;
  final DateTime cachedAt;
  final String? source;
  final CacheBbox? bbox;
  final String? etag;

  CacheEntry({
    required this.data,
    required this.cachedAt,
    this.source,
    this.bbox,
    this.etag,
  });

  /// Idade do cache em segundos
  int get ageSeconds => DateTime.now().difference(cachedAt).inSeconds;

  /// Idade do cache em minutos
  int get ageMinutes => DateTime.now().difference(cachedAt).inMinutes;

  /// Formata a idade para exibição
  String get ageFormatted {
    final minutes = ageMinutes;
    if (minutes < 1) return 'agora';
    if (minutes == 1) return 'há 1 min';
    if (minutes < 60) return 'há $minutes min';
    final hours = minutes ~/ 60;
    if (hours == 1) return 'há 1 hora';
    return 'há $hours horas';
  }

  /// Formata a idade de forma compacta (ex: "2m", "1h")
  String get ageCompact {
    final minutes = ageMinutes;
    if (minutes < 1) return '<1m';
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    return '${hours}h';
  }

  /// Verifica se o cache é considerado "stale" (antigo)
  bool isStale(int staleThresholdMinutes) {
    return ageMinutes >= staleThresholdMinutes;
  }

  /// Verifica se o cache é considerado "outdated" (muito antigo)
  bool isOutdated(int outdatedThresholdMinutes) {
    return ageMinutes >= outdatedThresholdMinutes;
  }

  Map<String, dynamic> toJson() => {
        'data': data,
        'cachedAt': cachedAt.toIso8601String(),
        if (source != null) 'source': source,
        if (bbox != null) 'bbox': bbox!.toJson(),
        if (etag != null) 'etag': etag,
      };

  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      data: json['data'] as String,
      cachedAt: DateTime.parse(json['cachedAt'] as String),
      source: json['source'] as String?,
      bbox: json['bbox'] != null
          ? CacheBbox.fromJson(json['bbox'] as Map<String, dynamic>)
          : null,
      etag: json['etag'] as String?,
    );
  }
}

/// Status completo de uma entrada de cache
class CacheStatus {
  final String key;
  final bool exists;
  final bool isStale;
  final bool isOutdated;
  final int? ageMinutes;
  final String? ageFormatted;
  final String? ageCompact;
  final DateTime? cachedAt;
  final String? source;

  const CacheStatus({
    required this.key,
    required this.exists,
    required this.isStale,
    required this.isOutdated,
    this.ageMinutes,
    this.ageFormatted,
    this.ageCompact,
    this.cachedAt,
    this.source,
  });

  /// Retorna texto para badge de idade
  String get ageBadgeText {
    if (!exists) return 'Sem dados';
    if (ageMinutes == null) return '';
    if (ageMinutes! < 1) return 'Agora';
    return ageCompact ?? '';
  }

  /// Cor para o badge de idade
  /// 0 = verde (fresco), 1 = amarelo (stale), 2 = vermelho (outdated)
  int get statusLevel {
    if (!exists || isOutdated) return 2;
    if (isStale) return 1;
    return 0;
  }
}

/// Serviço de cache local usando Hive
class CacheService {
  late Box<String> _cacheBox;
  late Box<String> _metadataBox;
  bool _isInitialized = false;

  /// Inicializa o Hive e abre os boxes
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Hive.initFlutter();
      _cacheBox = await Hive.openBox<String>(CacheKeys.cacheBox);
      _metadataBox = await Hive.openBox<String>(CacheKeys.metadataBox);
      _isInitialized = true;
      if (kDebugMode) print('CacheService inicializado');
    } catch (e) {
      if (kDebugMode) print('Erro ao inicializar CacheService: $e');
      rethrow;
    }
  }

  /// Verifica se o serviço está inicializado
  bool get isInitialized => _isInitialized;

  /// Salva dados no cache com metadata opcional
  Future<void> set(
    String key,
    Map<String, dynamic> data, {
    String? source,
    CacheBbox? bbox,
    String? etag,
  }) async {
    if (!_isInitialized) {
      if (kDebugMode) print('CacheService: tentando salvar sem inicializar');
      return;
    }

    try {
      final entry = CacheEntry(
        data: jsonEncode(data),
        cachedAt: DateTime.now(),
        source: source,
        bbox: bbox,
        etag: etag,
      );
      await _cacheBox.put(key, jsonEncode(entry.toJson()));
      if (kDebugMode) print('Cache salvo: $key');
    } catch (e) {
      if (kDebugMode) print('Erro ao salvar cache $key: $e');
    }
  }

  /// Obtém dados do cache
  CacheEntry? get(String key) {
    if (!_isInitialized) return null;

    try {
      final raw = _cacheBox.get(key);
      if (raw == null) return null;

      final json = jsonDecode(raw) as Map<String, dynamic>;
      return CacheEntry.fromJson(json);
    } catch (e) {
      if (kDebugMode) print('Erro ao ler cache $key: $e');
      return null;
    }
  }

  /// Obtém dados decodificados do cache
  Map<String, dynamic>? getData(String key) {
    final entry = get(key);
    if (entry == null) return null;

    try {
      return jsonDecode(entry.data) as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) print('Erro ao decodificar dados do cache $key: $e');
      return null;
    }
  }

  /// Verifica se há cache válido para uma chave
  bool hasValidCache(String key) {
    final entry = get(key);
    return entry != null;
  }

  /// Verifica se o cache está "stale" (antigo demais)
  bool isStale(String key) {
    final entry = get(key);
    if (entry == null) return true;

    final threshold = CacheConfig.staleThresholds[key] ??
        CacheConfig.defaultStaleThreshold;
    return entry.isStale(threshold);
  }

  /// Verifica se o cache está "outdated" (muito antigo - precisa avisar usuario)
  bool isOutdated(String key) {
    final entry = get(key);
    if (entry == null) return true;

    final threshold = CacheConfig.outdatedThresholds[key] ??
        CacheConfig.defaultOutdatedThreshold;
    return entry.isOutdated(threshold);
  }

  /// Retorna informacoes completas do status do cache
  CacheStatus getCacheStatus(String key) {
    final entry = get(key);
    if (entry == null) {
      return CacheStatus(
        key: key,
        exists: false,
        isStale: true,
        isOutdated: true,
        ageMinutes: null,
        ageFormatted: null,
        cachedAt: null,
      );
    }

    return CacheStatus(
      key: key,
      exists: true,
      isStale: isStale(key),
      isOutdated: isOutdated(key),
      ageMinutes: entry.ageMinutes,
      ageFormatted: entry.ageFormatted,
      ageCompact: entry.ageCompact,
      cachedAt: entry.cachedAt,
      source: entry.source,
    );
  }

  /// Obtém a idade do cache em minutos
  int? getCacheAgeMinutes(String key) {
    final entry = get(key);
    return entry?.ageMinutes;
  }

  /// Obtém a idade formatada do cache
  String? getCacheAgeFormatted(String key) {
    final entry = get(key);
    return entry?.ageFormatted;
  }

  /// Obtém o timestamp de quando foi cacheado
  DateTime? getCachedAt(String key) {
    final entry = get(key);
    return entry?.cachedAt;
  }

  /// Remove uma entrada do cache
  Future<void> remove(String key) async {
    if (!_isInitialized) return;
    await _cacheBox.delete(key);
  }

  /// Limpa todo o cache
  Future<void> clear() async {
    if (!_isInitialized) return;
    await _cacheBox.clear();
    await _metadataBox.clear();
    if (kDebugMode) print('Cache limpo');
  }

  /// Obtém todas as chaves do cache
  List<String> get keys {
    if (!_isInitialized) return [];
    return _cacheBox.keys.cast<String>().toList();
  }

  /// Fecha os boxes do Hive
  Future<void> close() async {
    if (!_isInitialized) return;
    await _cacheBox.close();
    await _metadataBox.close();
    _isInitialized = false;
  }

  /// Obtém a idade máxima do cache mais antigo entre os dados principais
  int? getMaxCacheAgeMinutes() {
    int? maxAge;
    for (final key in [
      CacheKeys.weather,
      CacheKeys.incidents,
      CacheKeys.rainGauges,
      CacheKeys.radar,
    ]) {
      final age = getCacheAgeMinutes(key);
      if (age != null && (maxAge == null || age > maxAge)) {
        maxAge = age;
      }
    }
    return maxAge;
  }

  /// Verifica se algum cache crítico está stale
  bool hasAnyStaleCriticalCache() {
    for (final key in [
      CacheKeys.incidents,
      CacheKeys.rainGauges,
    ]) {
      if (isStale(key)) return true;
    }
    return false;
  }
}

/// Provider para o CacheService
final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});

/// Provider para acompanhar inicialização do cache
final cacheInitializedProvider = FutureProvider<bool>((ref) async {
  final cacheService = ref.watch(cacheServiceProvider);
  await cacheService.initialize();
  return true;
});
