import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

/// Configuração do gerenciador de fetch por bbox
class BboxFetchConfig {
  /// Tempo de debounce em ms (padrão: 400ms)
  final int debounceMs;

  /// Percentual mínimo de mudança no bbox para refetch (padrão: 20%)
  final double bboxChangeThreshold;

  /// Mudança mínima de zoom para refetch (padrão: 0.5)
  final double zoomChangeThreshold;

  /// Zoom mínimo para carregar incidentes (padrão: 10)
  final double minZoomIncidents;

  /// Zoom mínimo para carregar pluviômetros (padrão: 9)
  final double minZoomRainGauges;

  /// Máximo de entradas no cache in-memory (padrão: 5)
  final int maxCacheEntries;

  /// Tempo máximo de validade do cache in-memory em segundos (padrão: 300s = 5min)
  final int cacheValiditySec;

  const BboxFetchConfig({
    this.debounceMs = 400,
    this.bboxChangeThreshold = 0.20,
    this.zoomChangeThreshold = 0.5,
    this.minZoomIncidents = 10.0,
    this.minZoomRainGauges = 9.0,
    this.maxCacheEntries = 5,
    this.cacheValiditySec = 300,
  });
}

/// Representa um bbox com zoom
class BboxState {
  final double north;
  final double south;
  final double east;
  final double west;
  final double zoom;
  final DateTime timestamp;

  const BboxState({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
    required this.zoom,
    required this.timestamp,
  });

  factory BboxState.fromBounds({
    required double north,
    required double south,
    required double east,
    required double west,
    required double zoom,
  }) {
    return BboxState(
      north: north,
      south: south,
      east: east,
      west: west,
      zoom: zoom,
      timestamp: DateTime.now(),
    );
  }

  /// Calcula a área do bbox
  double get area {
    final width = (east - west).abs();
    final height = (north - south).abs();
    return width * height;
  }

  /// Centro do bbox
  LatLng get center => LatLng(
        (north + south) / 2,
        (east + west) / 2,
      );

  /// Chave única para cache baseada em bbox discretizado
  String get cacheKey {
    // Discretiza para reduzir variações pequenas
    final nRound = (north * 100).round() / 100;
    final sRound = (south * 100).round() / 100;
    final eRound = (east * 100).round() / 100;
    final wRound = (west * 100).round() / 100;
    final zRound = zoom.round();
    return '$nRound,$sRound,$eRound,$wRound,$zRound';
  }

  /// Calcula percentual de mudança em relação a outro bbox
  double calculateChange(BboxState other) {
    // Calcula mudança em cada dimensão
    final deltaWidth = ((east - west) - (other.east - other.west)).abs();
    final deltaHeight = ((north - south) - (other.north - other.south)).abs();

    final avgWidth = ((east - west) + (other.east - other.west)) / 2;
    final avgHeight = ((north - south) + (other.north - other.south)) / 2;

    final widthChange = avgWidth > 0 ? deltaWidth / avgWidth : 0.0;
    final heightChange = avgHeight > 0 ? deltaHeight / avgHeight : 0.0;

    // Também considera deslocamento do centro
    final centerDeltaLat = (center.latitude - other.center.latitude).abs();
    final centerDeltaLng = (center.longitude - other.center.longitude).abs();

    final latExtent = ((north - south) + (other.north - other.south)) / 2;
    final lngExtent = ((east - west) + (other.east - other.west)) / 2;

    final centerShiftLat = latExtent > 0 ? centerDeltaLat / latExtent : 0.0;
    final centerShiftLng = lngExtent > 0 ? centerDeltaLng / lngExtent : 0.0;

    // Retorna a maior mudança
    return [widthChange, heightChange, centerShiftLat, centerShiftLng]
        .reduce((a, b) => a > b ? a : b);
  }

  /// Verifica se outro bbox está contido neste
  bool contains(BboxState other) {
    return other.north <= north &&
        other.south >= south &&
        other.east <= east &&
        other.west >= west;
  }

  @override
  String toString() =>
      'BboxState(n:${north.toStringAsFixed(4)}, s:${south.toStringAsFixed(4)}, '
      'e:${east.toStringAsFixed(4)}, w:${west.toStringAsFixed(4)}, z:${zoom.toStringAsFixed(1)})';
}

/// Entrada no cache in-memory
class BboxCacheEntry<T> {
  final T data;
  final BboxState bbox;
  final DateTime fetchedAt;
  final int itemCount;

  BboxCacheEntry({
    required this.data,
    required this.bbox,
    required this.fetchedAt,
    this.itemCount = 0,
  });

  bool isValid(int maxAgeSec) {
    return DateTime.now().difference(fetchedAt).inSeconds < maxAgeSec;
  }

  int get ageSeconds => DateTime.now().difference(fetchedAt).inSeconds;
}

/// Métricas de fetch
class BboxFetchMetrics {
  int totalFetchRequests = 0;
  int actualFetches = 0;
  int debounceSkips = 0;
  int thresholdSkips = 0;
  int cacheHits = 0;
  int zoomSkips = 0;
  DateTime? lastFetchTime;
  DateTime? lastRequestTime;

  void reset() {
    totalFetchRequests = 0;
    actualFetches = 0;
    debounceSkips = 0;
    thresholdSkips = 0;
    cacheHits = 0;
    zoomSkips = 0;
    lastFetchTime = null;
    lastRequestTime = null;
  }

  double get hitRate =>
      totalFetchRequests > 0 ? cacheHits / totalFetchRequests : 0;

  double get skipRate => totalFetchRequests > 0
      ? (debounceSkips + thresholdSkips + zoomSkips) / totalFetchRequests
      : 0;

  void logStats() {
    if (kDebugMode) {
      print('[BboxFetchMetrics] '
          'Total: $totalFetchRequests, '
          'Fetched: $actualFetches, '
          'CacheHits: $cacheHits, '
          'Debounced: $debounceSkips, '
          'ThresholdSkip: $thresholdSkips, '
          'ZoomSkip: $zoomSkips, '
          'HitRate: ${(hitRate * 100).toStringAsFixed(1)}%, '
          'SkipRate: ${(skipRate * 100).toStringAsFixed(1)}%');
    }
  }
}

/// Tipo de layer para fetch
enum BboxLayerType {
  incidents,
  rainGauges,
}

/// Gerenciador de fetches por bbox com debounce e cache
class BboxFetchManager {
  final BboxFetchConfig config;
  final BboxFetchMetrics metrics = BboxFetchMetrics();

  // Estado atual por layer
  final Map<BboxLayerType, BboxState?> _lastFetchedBbox = {};
  final Map<BboxLayerType, Timer?> _debounceTimers = {};
  final Map<BboxLayerType, Completer<void>?> _pendingFetches = {};

  // Cache in-memory por layer (LRU)
  final Map<BboxLayerType, LinkedHashMap<String, BboxCacheEntry>> _memoryCache =
      {};

  // Callbacks de fetch
  final Map<BboxLayerType, Future<dynamic> Function(BboxState bbox)>
      _fetchCallbacks = {};

  // Callbacks de resultado
  final Map<BboxLayerType, void Function(dynamic data, bool fromCache)>
      _resultCallbacks = {};

  BboxFetchManager({this.config = const BboxFetchConfig()}) {
    // Inicializa caches vazios
    for (final layer in BboxLayerType.values) {
      _memoryCache[layer] = LinkedHashMap();
    }
  }

  /// Registra callback de fetch para uma layer
  void registerFetchCallback<T>(
    BboxLayerType layer,
    Future<T> Function(BboxState bbox) fetchFn,
    void Function(T data, bool fromCache) onResult,
  ) {
    _fetchCallbacks[layer] = fetchFn;
    _resultCallbacks[layer] = (data, fromCache) => onResult(data as T, fromCache);
  }

  /// Solicita fetch para um novo bbox (com debounce)
  void requestFetch(BboxLayerType layer, BboxState newBbox) {
    metrics.totalFetchRequests++;
    metrics.lastRequestTime = DateTime.now();

    // Verifica zoom mínimo
    final minZoom = layer == BboxLayerType.incidents
        ? config.minZoomIncidents
        : config.minZoomRainGauges;

    if (newBbox.zoom < minZoom) {
      metrics.zoomSkips++;
      if (kDebugMode) {
        print('[BboxFetch] ${layer.name}: Zoom ${newBbox.zoom.toStringAsFixed(1)} < min $minZoom, skipping');
      }
      return;
    }

    // Verifica se mudança é significativa
    final lastBbox = _lastFetchedBbox[layer];
    if (lastBbox != null) {
      final change = newBbox.calculateChange(lastBbox);
      final zoomChange = (newBbox.zoom - lastBbox.zoom).abs();

      if (change < config.bboxChangeThreshold &&
          zoomChange < config.zoomChangeThreshold) {
        metrics.thresholdSkips++;
        if (kDebugMode) {
          print('[BboxFetch] ${layer.name}: Change ${(change * 100).toStringAsFixed(1)}% '
              '< threshold ${(config.bboxChangeThreshold * 100).toStringAsFixed(0)}%, skipping');
        }
        return;
      }
    }

    // Cancela timer anterior
    _debounceTimers[layer]?.cancel();

    // Verifica cache in-memory primeiro
    final cacheEntry = _getFromCache(layer, newBbox);
    if (cacheEntry != null) {
      metrics.cacheHits++;
      if (kDebugMode) {
        print('[BboxFetch] ${layer.name}: Cache HIT (age: ${cacheEntry.ageSeconds}s, items: ${cacheEntry.itemCount})');
      }
      _resultCallbacks[layer]?.call(cacheEntry.data, true);
      return;
    }

    // Inicia debounce
    _debounceTimers[layer] = Timer(
      Duration(milliseconds: config.debounceMs),
      () => _executeFetch(layer, newBbox),
    );

    if (kDebugMode) {
      print('[BboxFetch] ${layer.name}: Debouncing fetch (${config.debounceMs}ms)...');
    }
  }

  /// Força fetch imediato (sem debounce)
  Future<void> forceFetch(BboxLayerType layer, BboxState bbox) async {
    _debounceTimers[layer]?.cancel();
    await _executeFetch(layer, bbox);
  }

  /// Executa o fetch real
  Future<void> _executeFetch(BboxLayerType layer, BboxState bbox) async {
    final fetchFn = _fetchCallbacks[layer];
    if (fetchFn == null) {
      if (kDebugMode) print('[BboxFetch] ${layer.name}: No fetch callback registered');
      return;
    }

    // Evita fetches duplicados
    if (_pendingFetches[layer] != null) {
      if (kDebugMode) print('[BboxFetch] ${layer.name}: Fetch already in progress');
      metrics.debounceSkips++;
      return;
    }

    final completer = Completer<void>();
    _pendingFetches[layer] = completer;

    try {
      metrics.actualFetches++;
      metrics.lastFetchTime = DateTime.now();

      if (kDebugMode) {
        print('[BboxFetch] ${layer.name}: Fetching... '
            '(z:${bbox.zoom.toStringAsFixed(1)}, '
            'area:${bbox.area.toStringAsFixed(4)})');
      }

      final startTime = DateTime.now();
      final data = await fetchFn(bbox);
      final elapsed = DateTime.now().difference(startTime).inMilliseconds;

      // Conta itens para métricas
      int itemCount = 0;
      if (data is List) {
        itemCount = data.length;
      } else if (data != null) {
        // Tenta extrair contagem de diferentes tipos de response
        try {
          if (data is Map && data.containsKey('length')) {
            itemCount = data['length'] as int;
          }
        } catch (_) {}
      }

      // Salva no cache
      _addToCache(layer, bbox, data, itemCount);

      // Atualiza último bbox
      _lastFetchedBbox[layer] = bbox;

      // Notifica resultado
      _resultCallbacks[layer]?.call(data, false);

      if (kDebugMode) {
        print('[BboxFetch] ${layer.name}: Fetched $itemCount items in ${elapsed}ms');
        metrics.logStats();
      }
    } catch (e) {
      if (kDebugMode) print('[BboxFetch] ${layer.name}: Fetch error: $e');
    } finally {
      _pendingFetches[layer] = null;
      completer.complete();
    }
  }

  /// Busca no cache in-memory
  BboxCacheEntry? _getFromCache(BboxLayerType layer, BboxState bbox) {
    final cache = _memoryCache[layer]!;

    // Primeiro tenta match exato
    final exactKey = bbox.cacheKey;
    if (cache.containsKey(exactKey)) {
      final entry = cache[exactKey]!;
      if (entry.isValid(config.cacheValiditySec)) {
        // Move para o final (LRU)
        cache.remove(exactKey);
        cache[exactKey] = entry;
        return entry;
      } else {
        // Remove entrada expirada
        cache.remove(exactKey);
      }
    }

    // Busca bbox que contenha o atual
    for (final entry in cache.entries.toList()) {
      if (entry.value.isValid(config.cacheValiditySec) &&
          entry.value.bbox.contains(bbox)) {
        // Move para o final (LRU)
        cache.remove(entry.key);
        cache[entry.key] = entry.value;
        return entry.value;
      }
    }

    return null;
  }

  /// Adiciona ao cache in-memory
  void _addToCache(
    BboxLayerType layer,
    BboxState bbox,
    dynamic data,
    int itemCount,
  ) {
    final cache = _memoryCache[layer]!;
    final key = bbox.cacheKey;

    // Remove entradas antigas se cache estiver cheio
    while (cache.length >= config.maxCacheEntries) {
      cache.remove(cache.keys.first);
    }

    cache[key] = BboxCacheEntry(
      data: data,
      bbox: bbox,
      fetchedAt: DateTime.now(),
      itemCount: itemCount,
    );
  }

  /// Limpa cache de uma layer
  void clearCache(BboxLayerType layer) {
    _memoryCache[layer]?.clear();
    _lastFetchedBbox[layer] = null;
  }

  /// Limpa todo o cache
  void clearAllCache() {
    for (final layer in BboxLayerType.values) {
      clearCache(layer);
    }
  }

  /// Cancela todos os timers pendentes
  void cancelAll() {
    for (final timer in _debounceTimers.values) {
      timer?.cancel();
    }
    _debounceTimers.clear();
  }

  /// Obtém métricas atuais
  BboxFetchMetrics getMetrics() => metrics;

  /// Reseta métricas
  void resetMetrics() => metrics.reset();

  /// Dispose
  void dispose() {
    cancelAll();
    clearAllCache();
  }
}

/// Provider do gerenciador de bbox fetch
final bboxFetchManagerProvider = Provider<BboxFetchManager>((ref) {
  final manager = BboxFetchManager();
  ref.onDispose(() => manager.dispose());
  return manager;
});

/// Provider de configuração customizável
final bboxFetchConfigProvider = Provider<BboxFetchConfig>((ref) {
  return const BboxFetchConfig();
});
