import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/models.dart';
import '../../../../core/services/cache_service.dart';
import '../../../../core/services/bbox_fetch_manager.dart';
import '../../data/map_repository.dart';

/// Estado dos filtros de incidentes
class IncidentFiltersState {
  final Set<IncidentType> selectedTypes;
  final Set<IncidentSeverity> selectedSeverities;

  const IncidentFiltersState({
    this.selectedTypes = const {},
    this.selectedSeverities = const {},
  });

  /// Se não há filtros ativos, mostra todos
  bool get hasActiveFilters =>
      selectedTypes.isNotEmpty || selectedSeverities.isNotEmpty;

  /// Número de filtros ativos
  int get activeFilterCount => selectedTypes.length + selectedSeverities.length;

  /// Verifica se um incidente passa pelos filtros
  bool matchesFilters(Incident incident) {
    // Se não há filtros, mostra todos
    if (!hasActiveFilters) return true;

    // Verifica tipo
    if (selectedTypes.isNotEmpty && !selectedTypes.contains(incident.type)) {
      return false;
    }

    // Verifica severidade
    if (selectedSeverities.isNotEmpty &&
        !selectedSeverities.contains(incident.severity)) {
      return false;
    }

    return true;
  }

  IncidentFiltersState copyWith({
    Set<IncidentType>? selectedTypes,
    Set<IncidentSeverity>? selectedSeverities,
  }) {
    return IncidentFiltersState(
      selectedTypes: selectedTypes ?? this.selectedTypes,
      selectedSeverities: selectedSeverities ?? this.selectedSeverities,
    );
  }
}

/// Tipo de highlight no mapa
enum MapHighlightType {
  point,   // Marker pulsante
  polygon, // Contorno de polígono animado
  bounds,  // Área retangular
}

/// Estado de highlight temporário no mapa
class MapHighlightState {
  final MapHighlightType type;
  final LatLng? point;
  final List<LatLng>? polygon;
  final fm.LatLngBounds? bounds;
  final Color color;
  final double zoom;
  final DateTime createdAt;
  final Duration duration;

  const MapHighlightState({
    required this.type,
    this.point,
    this.polygon,
    this.bounds,
    this.color = const Color(0xFFFF5722),
    this.zoom = 15.0,
    required this.createdAt,
    this.duration = const Duration(seconds: 15),
  });

  /// Verifica se o highlight expirou
  bool get isExpired {
    return DateTime.now().difference(createdAt) > duration;
  }

  /// Tempo restante em segundos
  int get remainingSeconds {
    final remaining = duration.inSeconds - DateTime.now().difference(createdAt).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Calcula o centro do highlight
  LatLng? get center {
    if (point != null) return point;
    if (bounds != null) return bounds!.center;
    if (polygon != null && polygon!.isNotEmpty) {
      double sumLat = 0, sumLng = 0;
      for (final p in polygon!) {
        sumLat += p.latitude;
        sumLng += p.longitude;
      }
      return LatLng(sumLat / polygon!.length, sumLng / polygon!.length);
    }
    return null;
  }

  /// Calcula bounds do polígono
  fm.LatLngBounds? get polygonBounds {
    if (polygon == null || polygon!.isEmpty) return null;
    double minLat = polygon!.first.latitude;
    double maxLat = polygon!.first.latitude;
    double minLng = polygon!.first.longitude;
    double maxLng = polygon!.first.longitude;

    for (final p in polygon!) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }

    return fm.LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
  }
}

/// Comando de foco para o mapa (usado via callback)
class MapFocusCommand {
  final LatLng? center;
  final fm.LatLngBounds? bounds;
  final double? zoom;
  final double padding;

  const MapFocusCommand({
    this.center,
    this.bounds,
    this.zoom,
    this.padding = 50.0,
  });
}

/// Tema do mapa base
enum MapTheme {
  dark,
  light,
}

/// Estado das camadas do mapa
class MapLayersState {
  final bool radarEnabled;
  final bool rainGaugesEnabled;
  final bool sirensEnabled;
  final bool incidentsEnabled;
  final bool rainHeatmapEnabled;
  final bool camerasEnabled;
  final MapTheme mapTheme;

  const MapLayersState({
    this.radarEnabled = true,
    this.rainGaugesEnabled = true,
    this.sirensEnabled = true,
    this.incidentsEnabled = true,
    this.rainHeatmapEnabled = false,
    this.camerasEnabled = true,
    this.mapTheme = MapTheme.dark,
  });

  /// URL do tile layer baseado no tema
  String get tileLayerUrl {
    switch (mapTheme) {
      case MapTheme.dark:
        return 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
      case MapTheme.light:
        return 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';
    }
  }

  /// Cor de fundo do mapa baseada no tema
  Color get backgroundColor {
    switch (mapTheme) {
      case MapTheme.dark:
        return const Color(0xFF1a1a2e);
      case MapTheme.light:
        return const Color(0xFFf5f5f5);
    }
  }

  MapLayersState copyWith({
    bool? radarEnabled,
    bool? rainGaugesEnabled,
    bool? sirensEnabled,
    bool? incidentsEnabled,
    bool? rainHeatmapEnabled,
    bool? camerasEnabled,
    MapTheme? mapTheme,
  }) {
    return MapLayersState(
      radarEnabled: radarEnabled ?? this.radarEnabled,
      rainGaugesEnabled: rainGaugesEnabled ?? this.rainGaugesEnabled,
      sirensEnabled: sirensEnabled ?? this.sirensEnabled,
      incidentsEnabled: incidentsEnabled ?? this.incidentsEnabled,
      rainHeatmapEnabled: rainHeatmapEnabled ?? this.rainHeatmapEnabled,
      camerasEnabled: camerasEnabled ?? this.camerasEnabled,
      mapTheme: mapTheme ?? this.mapTheme,
    );
  }
}

/// Estado completo do mapa
class MapState {
  final LatLng? userLocation;
  final bool isLoadingLocation;
  final bool hasLocationPermission;
  final RadarResponse? radar;
  final RainGaugeResponse? rainGauges;
  final SirensResponse? sirens;
  final IncidentResponse? incidents;
  final Weather? weather;
  final AlertaRioForecast? alertaRioForecast;
  final bool isLoading;
  final String? error;
  final MapLayersState layers;
  final IncidentFiltersState incidentFilters;

  // Estado da animação do radar
  final int radarFrameIndex;
  final bool isRadarAnimationPlaying;
  final bool isRadarLiveMode;

  // Estado do cache
  final int? dataAgeMinutes;
  final DateTime? lastUpdated;

  // Estado de highlight/foco
  final MapHighlightState? highlight;
  final MapFocusCommand? pendingFocusCommand;

  const MapState({
    this.userLocation,
    this.isLoadingLocation = false,
    this.hasLocationPermission = false,
    this.radar,
    this.rainGauges,
    this.sirens,
    this.incidents,
    this.weather,
    this.alertaRioForecast,
    this.isLoading = false,
    this.error,
    this.layers = const MapLayersState(),
    this.incidentFilters = const IncidentFiltersState(),
    this.radarFrameIndex = 0,
    this.isRadarAnimationPlaying = false,
    this.isRadarLiveMode = true,
    this.dataAgeMinutes,
    this.lastUpdated,
    this.highlight,
    this.pendingFocusCommand,
  });

  /// Verifica se algum dado está stale (do cache)
  bool get hasStaleData {
    return (weather?.isStale ?? false) ||
        (radar?.isStale ?? false) ||
        (incidents?.isStale ?? false) ||
        (rainGauges?.isStale ?? false) ||
        (sirens?.isStale ?? false);
  }

  /// Retorna o snapshot do radar atual baseado no índice
  RadarSnapshot? get currentRadarSnapshot {
    if (radar == null) return null;
    final snapshots = radar!.allSnapshots;
    if (snapshots.isEmpty) return null;
    return snapshots[radarFrameIndex.clamp(0, snapshots.length - 1)];
  }

  /// Retorna incidentes filtrados
  List<Incident> get filteredIncidents {
    if (incidents == null) return [];
    return incidents!.incidents
        .where((i) => incidentFilters.matchesFilters(i))
        .toList();
  }

  /// Verifica se há highlight ativo e não expirado
  bool get hasActiveHighlight => highlight != null && !highlight!.isExpired;

  MapState copyWith({
    LatLng? userLocation,
    bool? isLoadingLocation,
    bool? hasLocationPermission,
    RadarResponse? radar,
    RainGaugeResponse? rainGauges,
    SirensResponse? sirens,
    IncidentResponse? incidents,
    Weather? weather,
    AlertaRioForecast? alertaRioForecast,
    bool? isLoading,
    String? error,
    MapLayersState? layers,
    IncidentFiltersState? incidentFilters,
    int? radarFrameIndex,
    bool? isRadarAnimationPlaying,
    bool? isRadarLiveMode,
    int? dataAgeMinutes,
    DateTime? lastUpdated,
    MapHighlightState? highlight,
    MapFocusCommand? pendingFocusCommand,
    bool clearHighlight = false,
    bool clearFocusCommand = false,
  }) {
    return MapState(
      userLocation: userLocation ?? this.userLocation,
      isLoadingLocation: isLoadingLocation ?? this.isLoadingLocation,
      hasLocationPermission: hasLocationPermission ?? this.hasLocationPermission,
      radar: radar ?? this.radar,
      rainGauges: rainGauges ?? this.rainGauges,
      sirens: sirens ?? this.sirens,
      incidents: incidents ?? this.incidents,
      weather: weather ?? this.weather,
      alertaRioForecast: alertaRioForecast ?? this.alertaRioForecast,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      layers: layers ?? this.layers,
      incidentFilters: incidentFilters ?? this.incidentFilters,
      radarFrameIndex: radarFrameIndex ?? this.radarFrameIndex,
      isRadarAnimationPlaying: isRadarAnimationPlaying ?? this.isRadarAnimationPlaying,
      isRadarLiveMode: isRadarLiveMode ?? this.isRadarLiveMode,
      dataAgeMinutes: dataAgeMinutes ?? this.dataAgeMinutes,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      highlight: clearHighlight ? null : (highlight ?? this.highlight),
      pendingFocusCommand: clearFocusCommand ? null : (pendingFocusCommand ?? this.pendingFocusCommand),
    );
  }
}

/// Controller do mapa
class MapController extends StateNotifier<MapState> {
  final MapRepository _repository;
  Timer? _refreshTimer;
  Timer? _radarAnimationTimer;
  Timer? _radarLiveTimer;
  Timer? _highlightTimer;

  // Gerenciador de fetch por bbox com debounce e cache
  late final BboxFetchManager _bboxFetchManager;

  // Configuração da animação do radar
  static const Duration radarFrameDelay = Duration(milliseconds: 400);

  // Intervalo de atualização do radar ao vivo (2 minutos)
  static const Duration radarLiveUpdateInterval = Duration(minutes: 2);

  // Duração padrão do highlight
  static const Duration defaultHighlightDuration = Duration(seconds: 15);

  MapController(this._repository) : super(const MapState()) {
    _initBboxFetchManager();
    _init();
  }

  /// Inicializa o gerenciador de fetch por bbox
  void _initBboxFetchManager() {
    _bboxFetchManager = BboxFetchManager(
      config: const BboxFetchConfig(
        debounceMs: 400,
        bboxChangeThreshold: 0.20,
        zoomChangeThreshold: 0.5,
        minZoomIncidents: 10.0,
        minZoomRainGauges: 9.0,
        maxCacheEntries: 5,
        cacheValiditySec: 300,
      ),
    );

    // Registra callback para incidentes
    _bboxFetchManager.registerFetchCallback<IncidentResponse>(
      BboxLayerType.incidents,
      (bbox) => _repository.getIncidentsByBbox(
        north: bbox.north,
        south: bbox.south,
        east: bbox.east,
        west: bbox.west,
      ),
      (data, fromCache) {
        if (mounted) {
          state = state.copyWith(incidents: data);
          if (kDebugMode) {
            print('[MapController] Incidentes atualizados: ${data.incidents.length} (cache: $fromCache)');
          }
        }
      },
    );

    // Registra callback para pluviômetros
    _bboxFetchManager.registerFetchCallback<RainGaugeResponse>(
      BboxLayerType.rainGauges,
      (bbox) => _repository.getRainGaugesByBbox(
        north: bbox.north,
        south: bbox.south,
        east: bbox.east,
        west: bbox.west,
      ),
      (data, fromCache) {
        if (mounted) {
          state = state.copyWith(rainGauges: data);
          if (kDebugMode) {
            print('[MapController] Pluviômetros atualizados: ${data.stations.length} (cache: $fromCache)');
          }
        }
      },
    );
  }

  void _init() {
    // Carrega dados do cache primeiro para exibição imediata
    _loadCachedDataFirst();

    // Depois atualiza da rede
    loadAllData();

    // Inicia refresh automático a cada 60 segundos
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 60),
      (_) => loadAllData(silent: true),
    );

    // Inicia modo ao vivo do radar (atualiza a cada 2 minutos)
    _startRadarLiveMode();
  }

  /// Inicia o modo ao vivo do radar
  void _startRadarLiveMode() {
    _radarLiveTimer?.cancel();
    _radarLiveTimer = Timer.periodic(radarLiveUpdateInterval, (_) {
      if (state.isRadarLiveMode && state.layers.radarEnabled) {
        _refreshRadarOnly();
      }
    });
  }

  /// Atualiza apenas os dados do radar
  Future<void> _refreshRadarOnly() async {
    try {
      final newRadar = await _repository.getRadarLatest();
      if (mounted) {
        final radarSnapshots = newRadar.allSnapshots;
        state = state.copyWith(
          radar: newRadar,
          // Se em modo ao vivo, sempre vai para o frame mais recente
          radarFrameIndex: state.isRadarLiveMode
              ? radarSnapshots.length - 1
              : state.radarFrameIndex.clamp(0, radarSnapshots.length - 1),
        );
        if (kDebugMode) {
          print('[MapController] Radar atualizado ao vivo: ${radarSnapshots.length} frames');
        }
      }
    } catch (e) {
      if (kDebugMode) print('[MapController] Erro ao atualizar radar ao vivo: $e');
    }
  }

  /// Carrega dados do cache para exibição imediata
  Future<void> _loadCachedDataFirst() async {
    try {
      // Tenta carregar radar do cache
      final cachedRadar = await _repository.getCachedFirst<RadarResponse>(
        CacheKeys.radar,
        (data) => RadarResponse.fromJson(data['data'] ?? data),
      );

      // Tenta carregar rain gauges do cache
      final cachedRainGauges = await _repository.getCachedFirst<RainGaugeResponse>(
        CacheKeys.rainGauges,
        (data) {
          final stations = data['data'] ?? data['stations'] ?? [];
          return RainGaugeResponse(
            stations: (stations as List).map((e) => RainGauge.fromJson(e)).toList(),
            summary: data['summary'] != null
                ? RainGaugeSummary.fromJson(data['summary'])
                : null,
            isStale: true,
          );
        },
      );

      // Tenta carregar incidentes do cache
      final cachedIncidents = await _repository.getCachedFirst<IncidentResponse>(
        CacheKeys.incidents,
        (data) {
          final incidents = data['data'] ?? data['incidents'] ?? [];
          return IncidentResponse(
            incidents: (incidents as List).map((e) => Incident.fromJson(e)).toList(),
            summary: data['summary'] != null
                ? IncidentSummary.fromJson(data['summary'])
                : null,
            isStale: true,
          );
        },
      );

      // Tenta carregar weather do cache (formato Alerta Rio)
      final cachedWeather = await _repository.getCachedFirst<Weather>(
        CacheKeys.weather,
        (response) {
          final data = response['data'] ?? response;

          // Extrai temperatura média das zonas (formato Alerta Rio)
          double temperature = 25.0;
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
          final items = data['items'] as List?;
          if (items != null && items.isNotEmpty) {
            final currentPeriod = items[0] as Map<String, dynamic>;
            condition = currentPeriod['condition'] as String?;
            conditionIcon = currentPeriod['condition_icon'] as String?;
          }

          return Weather(
            temperature: temperature,
            feelsLike: temperature,
            humidity: 0,
            pressure: 0,
            windSpeed: 15,
            windDirection: 0,
            visibility: null,
            uvIndex: null,
            condition: condition,
            conditionIcon: conditionIcon,
            timestamp: data['updated_at'] != null
                ? DateTime.tryParse(data['updated_at'] as String)
                : null,
            isStale: true,
          );
        },
      );

      // Atualiza estado se houver dados em cache
      if (cachedRadar != null ||
          cachedRainGauges != null ||
          cachedIncidents != null ||
          cachedWeather != null) {
        final radarSnapshots = cachedRadar?.allSnapshots ?? [];

        state = state.copyWith(
          radar: cachedRadar,
          rainGauges: cachedRainGauges,
          incidents: cachedIncidents,
          weather: cachedWeather,
          dataAgeMinutes: _repository.getMaxCacheAgeMinutes(),
          radarFrameIndex: radarSnapshots.isNotEmpty ? radarSnapshots.length - 1 : 0,
        );

        if (kDebugMode) print('Dados carregados do cache');
      }
    } catch (e) {
      if (kDebugMode) print('Erro ao carregar cache: $e');
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _radarAnimationTimer?.cancel();
    _radarLiveTimer?.cancel();
    _highlightTimer?.cancel();
    _bboxFetchManager.dispose();
    super.dispose();
  }

  // ============== Controle de Fetch por Bbox ==============

  /// Chamado quando a posição/zoom do mapa muda
  /// Deve ser chamado pelo MapScreen no onPositionChanged
  void onMapPositionChanged({
    required double north,
    required double south,
    required double east,
    required double west,
    required double zoom,
  }) {
    final bbox = BboxState.fromBounds(
      north: north,
      south: south,
      east: east,
      west: west,
      zoom: zoom,
    );

    // Solicita fetch para camadas habilitadas
    if (state.layers.incidentsEnabled) {
      _bboxFetchManager.requestFetch(BboxLayerType.incidents, bbox);
    }

    if (state.layers.rainGaugesEnabled) {
      _bboxFetchManager.requestFetch(BboxLayerType.rainGauges, bbox);
    }
  }

  /// Força atualização imediata das camadas por bbox
  Future<void> forceRefreshBboxLayers({
    required double north,
    required double south,
    required double east,
    required double west,
    required double zoom,
  }) async {
    final bbox = BboxState.fromBounds(
      north: north,
      south: south,
      east: east,
      west: west,
      zoom: zoom,
    );

    final futures = <Future<void>>[];

    if (state.layers.incidentsEnabled) {
      futures.add(_bboxFetchManager.forceFetch(BboxLayerType.incidents, bbox));
    }

    if (state.layers.rainGaugesEnabled) {
      futures.add(_bboxFetchManager.forceFetch(BboxLayerType.rainGauges, bbox));
    }

    await Future.wait(futures);
  }

  /// Limpa cache in-memory de bbox (útil ao forçar refresh)
  void clearBboxCache() {
    _bboxFetchManager.clearAllCache();
  }

  /// Obtém métricas do BboxFetchManager
  BboxFetchMetrics getBboxFetchMetrics() {
    return _bboxFetchManager.getMetrics();
  }

  /// Reseta métricas do BboxFetchManager
  void resetBboxFetchMetrics() {
    _bboxFetchManager.resetMetrics();
  }

  // ============== Controle de Foco e Highlight ==============

  /// Foca em um ponto com highlight pulsante
  void focusOnPoint(
    LatLng point, {
    double zoom = 15.0,
    Color color = const Color(0xFFFF5722),
    Duration duration = const Duration(seconds: 15),
  }) {
    _highlightTimer?.cancel();

    final highlight = MapHighlightState(
      type: MapHighlightType.point,
      point: point,
      color: color,
      zoom: zoom,
      createdAt: DateTime.now(),
      duration: duration,
    );

    final focusCommand = MapFocusCommand(
      center: point,
      zoom: zoom,
    );

    state = state.copyWith(
      highlight: highlight,
      pendingFocusCommand: focusCommand,
    );

    _startHighlightExpiration(duration);
  }

  /// Foca em bounds com padding
  void focusOnBounds(
    fm.LatLngBounds bounds, {
    double padding = 50.0,
    Color color = const Color(0xFFFF5722),
    Duration duration = const Duration(seconds: 15),
  }) {
    _highlightTimer?.cancel();

    final highlight = MapHighlightState(
      type: MapHighlightType.bounds,
      bounds: bounds,
      color: color,
      createdAt: DateTime.now(),
      duration: duration,
    );

    final focusCommand = MapFocusCommand(
      bounds: bounds,
      padding: padding,
    );

    state = state.copyWith(
      highlight: highlight,
      pendingFocusCommand: focusCommand,
    );

    _startHighlightExpiration(duration);
  }

  /// Foca em polígono (GeoJSON ou lista de pontos)
  void focusOnPolygon(
    List<LatLng> polygonPoints, {
    double padding = 50.0,
    Color color = const Color(0xFFFF5722),
    Duration duration = const Duration(seconds: 20),
  }) {
    if (polygonPoints.isEmpty) return;

    _highlightTimer?.cancel();

    final highlight = MapHighlightState(
      type: MapHighlightType.polygon,
      polygon: polygonPoints,
      color: color,
      createdAt: DateTime.now(),
      duration: duration,
    );

    final bounds = highlight.polygonBounds;
    final focusCommand = MapFocusCommand(
      bounds: bounds,
      padding: padding,
    );

    state = state.copyWith(
      highlight: highlight,
      pendingFocusCommand: focusCommand,
    );

    _startHighlightExpiration(duration);
  }

  /// Foca em polígono a partir de GeoJSON
  void focusOnGeoJsonPolygon(
    Map<String, dynamic> geometry, {
    double padding = 50.0,
    Color color = const Color(0xFFFF5722),
    Duration duration = const Duration(seconds: 20),
  }) {
    final polygonPoints = _extractPolygonFromGeoJson(geometry);
    if (polygonPoints != null && polygonPoints.isNotEmpty) {
      focusOnPolygon(
        polygonPoints,
        padding: padding,
        color: color,
        duration: duration,
      );
    }
  }

  /// Extrai coordenadas de polígono de GeoJSON
  List<LatLng>? _extractPolygonFromGeoJson(Map<String, dynamic>? geometry) {
    if (geometry == null) return null;

    try {
      final type = geometry['type'];
      if (type == 'Polygon') {
        final coords = geometry['coordinates'] as List;
        if (coords.isNotEmpty) {
          final ring = coords[0] as List;
          return ring.map((c) {
            final coord = c as List;
            return LatLng(coord[1].toDouble(), coord[0].toDouble());
          }).toList();
        }
      } else if (type == 'MultiPolygon') {
        final coords = geometry['coordinates'] as List;
        if (coords.isNotEmpty) {
          final polygon = coords[0] as List;
          if (polygon.isNotEmpty) {
            final ring = polygon[0] as List;
            return ring.map((c) {
              final coord = c as List;
              return LatLng(coord[1].toDouble(), coord[0].toDouble());
            }).toList();
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Erro ao extrair polígono de GeoJSON: $e');
    }
    return null;
  }

  /// Limpa o highlight ativo
  void clearHighlight() {
    _highlightTimer?.cancel();
    state = state.copyWith(clearHighlight: true);
  }

  /// Confirma que o comando de foco foi processado pelo mapa
  void acknowledgeFocusCommand() {
    state = state.copyWith(clearFocusCommand: true);
  }

  /// Inicia timer para expirar o highlight
  void _startHighlightExpiration(Duration duration) {
    _highlightTimer = Timer(duration, () {
      if (mounted) {
        state = state.copyWith(clearHighlight: true);
      }
    });
  }

  /// Carrega todos os dados do mapa
  Future<void> loadAllData({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      // Carrega dados em paralelo
      final results = await Future.wait([
        _repository.getRadarLatest().catchError((e) {
          if (kDebugMode) print('Erro ao carregar radar: $e');
          return state.radar ?? RadarResponse(
            current: RadarSnapshot(
              id: '',
              url: '',
              timestamp: DateTime.now(),
              boundingBox: RadarBoundingBox(north: -21.5, south: -23.5, east: -42.0, west: -44.5),
            ),
            previous: [],
          );
        }),
        _repository.getRainGauges().catchError((e) {
          if (kDebugMode) print('Erro ao carregar pluviômetros: $e');
          return state.rainGauges ?? RainGaugeResponse(stations: []);
        }),
        _repository.getSirens().catchError((e) {
          if (kDebugMode) print('Erro ao carregar sirenes: $e');
          return state.sirens ?? SirensResponse(sirens: []);
        }),
        _repository.getIncidents().catchError((e) {
          if (kDebugMode) print('Erro ao carregar incidentes: $e');
          return state.incidents ?? IncidentResponse(incidents: []);
        }),
        _repository.getWeatherNow().catchError((e) {
          if (kDebugMode) print('Erro ao carregar clima: $e');
          return state.weather;
        }),
      ]);

      final newRadar = results[0] as RadarResponse;
      final radarSnapshots = newRadar.allSnapshots;
      final newRainGauges = results[1] as RainGaugeResponse;
      final newSirens = results[2] as SirensResponse;
      final newIncidents = results[3] as IncidentResponse;
      final newWeather = results[4] as Weather?;

      // Carrega dados completos do Alerta Rio (usa cache já carregado)
      final newAlertaRioForecast = await _repository.getAlertaRioForecast();

      // Verifica se algum dado veio do cache (isStale)
      final isFromCache = newRadar.isStale ||
          newRainGauges.isStale ||
          newSirens.isStale ||
          newIncidents.isStale ||
          (newWeather?.isStale ?? false);

      state = state.copyWith(
        radar: newRadar,
        rainGauges: newRainGauges,
        sirens: newSirens,
        incidents: newIncidents,
        weather: newWeather,
        alertaRioForecast: newAlertaRioForecast,
        isLoading: false,
        // Mantém índice atual se animando, senão começa do primeiro frame
        radarFrameIndex: state.isRadarAnimationPlaying
            ? state.radarFrameIndex.clamp(0, radarSnapshots.length - 1)
            : 0,
        // Atualiza info de cache
        dataAgeMinutes: isFromCache ? _repository.getMaxCacheAgeMinutes() : 0,
        lastUpdated: isFromCache ? state.lastUpdated : DateTime.now(),
      );

      // Se modo ao vivo está ativo e não está animando, inicia animação
      if (state.isRadarLiveMode && !state.isRadarAnimationPlaying && radarSnapshots.length > 1) {
        _startLiveAnimation();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e is AppException ? e.message : 'Erro ao carregar dados',
        dataAgeMinutes: _repository.getMaxCacheAgeMinutes(),
      );
    }
  }

  /// Toggle camada de radar
  void toggleRadar() {
    state = state.copyWith(
      layers: state.layers.copyWith(radarEnabled: !state.layers.radarEnabled),
    );
  }

  /// Toggle camada de pluviômetros
  void toggleRainGauges() {
    state = state.copyWith(
      layers: state.layers.copyWith(rainGaugesEnabled: !state.layers.rainGaugesEnabled),
    );
  }

  /// Toggle camada de sirenes
  void toggleSirens() {
    state = state.copyWith(
      layers: state.layers.copyWith(sirensEnabled: !state.layers.sirensEnabled),
    );
  }

  /// Toggle camada de incidentes
  void toggleIncidents() {
    state = state.copyWith(
      layers: state.layers.copyWith(incidentsEnabled: !state.layers.incidentsEnabled),
    );
  }

  /// Toggle camada de heatmap de chuva
  void toggleRainHeatmap() {
    state = state.copyWith(
      layers: state.layers.copyWith(rainHeatmapEnabled: !state.layers.rainHeatmapEnabled),
    );
  }

  /// Toggle camada de câmeras
  void toggleCameras() {
    state = state.copyWith(
      layers: state.layers.copyWith(camerasEnabled: !state.layers.camerasEnabled),
    );
  }

  /// Alterna tema do mapa (dark/light)
  void toggleMapTheme() {
    final newTheme = state.layers.mapTheme == MapTheme.dark
        ? MapTheme.light
        : MapTheme.dark;
    state = state.copyWith(
      layers: state.layers.copyWith(mapTheme: newTheme),
    );
  }

  /// Define tema do mapa
  void setMapTheme(MapTheme theme) {
    state = state.copyWith(
      layers: state.layers.copyWith(mapTheme: theme),
    );
  }

  /// Obtém localização do usuário
  Future<void> getUserLocation() async {
    state = state.copyWith(isLoadingLocation: true);

    try {
      // Verifica se o serviço de localização está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          isLoadingLocation: false,
          hasLocationPermission: false,
        );
        return;
      }

      // Verifica permissões
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(
            isLoadingLocation: false,
            hasLocationPermission: false,
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          isLoadingLocation: false,
          hasLocationPermission: false,
        );
        return;
      }

      // Obtém posição
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      state = state.copyWith(
        userLocation: LatLng(position.latitude, position.longitude),
        isLoadingLocation: false,
        hasLocationPermission: true,
      );
    } catch (e) {
      if (kDebugMode) print('Erro ao obter localização: $e');
      state = state.copyWith(isLoadingLocation: false);
    }
  }

  /// Atualiza localização do usuário (chamado externamente)
  void updateUserLocation(LatLng location) {
    state = state.copyWith(
      userLocation: location,
      hasLocationPermission: true,
    );
  }

  /// Limpa erro
  void clearError() {
    state = state.copyWith(error: null);
  }

  // ============== Controle de Animação do Radar ==============

  /// Define o índice do frame do radar manualmente
  void setRadarFrameIndex(int index) {
    final snapshots = state.radar?.allSnapshots ?? [];
    if (snapshots.isEmpty) return;

    // Se o usuário muda manualmente para um frame que não é o mais recente,
    // desativa o modo ao vivo
    final isLatestFrame = index == snapshots.length - 1;

    state = state.copyWith(
      radarFrameIndex: index.clamp(0, snapshots.length - 1),
      isRadarLiveMode: isLatestFrame ? state.isRadarLiveMode : false,
    );
  }

  /// Alterna play/pause da animação do radar
  void toggleRadarAnimation() {
    if (state.isRadarAnimationPlaying) {
      stopRadarAnimation();
    } else {
      startRadarAnimation();
    }
  }

  /// Inicia a animação do radar (ativa modo ao vivo automaticamente)
  void startRadarAnimation() {
    final snapshots = state.radar?.allSnapshots ?? [];
    if (snapshots.length <= 1) return;

    _radarAnimationTimer?.cancel();

    // Ativa modo ao vivo quando inicia animação
    state = state.copyWith(
      isRadarAnimationPlaying: true,
      isRadarLiveMode: true,
    );

    _radarAnimationTimer = Timer.periodic(radarFrameDelay, (_) {
      final totalFrames = state.radar?.allSnapshots.length ?? 0;
      if (totalFrames <= 1) {
        stopRadarAnimation();
        return;
      }

      final nextIndex = (state.radarFrameIndex + 1) % totalFrames;
      state = state.copyWith(radarFrameIndex: nextIndex);
    });
  }

  /// Para a animação do radar (desativa modo ao vivo)
  void stopRadarAnimation() {
    _radarAnimationTimer?.cancel();
    _radarAnimationTimer = null;
    state = state.copyWith(
      isRadarAnimationPlaying: false,
      isRadarLiveMode: false,
    );
  }

  /// Reinicia o índice do radar para o frame mais recente
  void resetRadarToLatest() {
    final snapshots = state.radar?.allSnapshots ?? [];
    if (snapshots.isEmpty) return;

    stopRadarAnimation();
    state = state.copyWith(radarFrameIndex: snapshots.length - 1);
  }

  // ============== Controle de Modo Ao Vivo do Radar ==============

  /// Alterna o modo ao vivo do radar
  /// No modo ao vivo, a animação roda automaticamente em loop
  void toggleRadarLiveMode() {
    final newLiveMode = !state.isRadarLiveMode;

    if (newLiveMode) {
      // Ao ativar modo ao vivo, inicia animação em loop
      state = state.copyWith(isRadarLiveMode: true);
      // Força atualização imediata dos dados
      _refreshRadarOnly();
      // Inicia animação automaticamente
      _startLiveAnimation();
    } else {
      // Ao desativar, para a animação
      stopRadarAnimation();
      state = state.copyWith(isRadarLiveMode: false);
    }
  }

  /// Inicia animação no modo ao vivo (loop contínuo)
  void _startLiveAnimation() {
    final snapshots = state.radar?.allSnapshots ?? [];
    if (snapshots.length <= 1) return;

    _radarAnimationTimer?.cancel();

    state = state.copyWith(isRadarAnimationPlaying: true);

    _radarAnimationTimer = Timer.periodic(radarFrameDelay, (_) {
      final totalFrames = state.radar?.allSnapshots.length ?? 0;
      if (totalFrames <= 1) return;

      final nextIndex = (state.radarFrameIndex + 1) % totalFrames;
      state = state.copyWith(radarFrameIndex: nextIndex);
    });
  }

  /// Ativa o modo ao vivo do radar
  void enableRadarLiveMode() {
    if (!state.isRadarLiveMode) {
      toggleRadarLiveMode();
    }
  }

  /// Desativa o modo ao vivo do radar
  void disableRadarLiveMode() {
    if (state.isRadarLiveMode) {
      stopRadarAnimation();
      state = state.copyWith(isRadarLiveMode: false);
    }
  }

  // ============== Controle de Filtros de Incidentes ==============

  /// Toggle filtro de tipo de incidente
  void toggleIncidentTypeFilter(IncidentType type) {
    final currentTypes = Set<IncidentType>.from(state.incidentFilters.selectedTypes);
    if (currentTypes.contains(type)) {
      currentTypes.remove(type);
    } else {
      currentTypes.add(type);
    }
    state = state.copyWith(
      incidentFilters: state.incidentFilters.copyWith(selectedTypes: currentTypes),
    );
  }

  /// Toggle filtro de severidade
  void toggleIncidentSeverityFilter(IncidentSeverity severity) {
    final currentSeverities = Set<IncidentSeverity>.from(state.incidentFilters.selectedSeverities);
    if (currentSeverities.contains(severity)) {
      currentSeverities.remove(severity);
    } else {
      currentSeverities.add(severity);
    }
    state = state.copyWith(
      incidentFilters: state.incidentFilters.copyWith(selectedSeverities: currentSeverities),
    );
  }

  /// Limpa todos os filtros
  void clearIncidentFilters() {
    state = state.copyWith(
      incidentFilters: const IncidentFiltersState(),
    );
  }

  /// Define filtros de tipos
  void setIncidentTypeFilters(Set<IncidentType> types) {
    state = state.copyWith(
      incidentFilters: state.incidentFilters.copyWith(selectedTypes: types),
    );
  }

  /// Define filtros de severidades
  void setIncidentSeverityFilters(Set<IncidentSeverity> severities) {
    state = state.copyWith(
      incidentFilters: state.incidentFilters.copyWith(selectedSeverities: severities),
    );
  }
}

/// Provider do controller do mapa
final mapControllerProvider = StateNotifierProvider<MapController, MapState>((ref) {
  final repository = ref.watch(mapRepositoryProvider);
  return MapController(repository);
});

/// Provider para a localização atual do usuário
final userLocationProvider = Provider<LatLng?>((ref) {
  return ref.watch(mapControllerProvider).userLocation;
});

/// Provider para verificar se tem permissão de localização
final hasLocationPermissionProvider = Provider<bool>((ref) {
  return ref.watch(mapControllerProvider).hasLocationPermission;
});

/// Provider para o estado de highlight ativo
final mapHighlightProvider = Provider<MapHighlightState?>((ref) {
  return ref.watch(mapControllerProvider).highlight;
});

/// Provider para comandos de foco pendentes
final mapFocusCommandProvider = Provider<MapFocusCommand?>((ref) {
  return ref.watch(mapControllerProvider).pendingFocusCommand;
});
