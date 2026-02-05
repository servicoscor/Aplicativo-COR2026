import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/models.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/camera_service.dart';
import '../../../../core/services/status_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/map_controller.dart';
import '../../../alerts/presentation/controllers/alerts_controller.dart';
import '../widgets/incident_marker.dart';
import '../widgets/rain_gauge_marker.dart';
import '../widgets/siren_marker.dart';
import '../widgets/weather_widget.dart';
import '../widgets/weather_details_dropdown.dart';
import '../widgets/incident_bottom_sheet.dart';
import '../widgets/rain_gauge_bottom_sheet.dart';
import '../widgets/radar_timeline_control.dart';
import '../widgets/cluster_marker.dart';
import '../widgets/map_layers_bottom_sheet.dart';
import '../widgets/rain_heatmap_layer.dart';
import '../widgets/city_now_panel.dart';
import '../widgets/map_highlight_layer.dart';
import '../widgets/cor_operational_top_bar.dart';
import '../widgets/camera_marker.dart';
import 'camera_player_screen.dart';

/// Tela principal do mapa
class MapScreen extends ConsumerStatefulWidget {
  final LatLng? highlightArea;

  const MapScreen({super.key, this.highlightArea});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with SingleTickerProviderStateMixin {
  late final fm.MapController _mapController;
  late final AnimationController _carnavalPulseController;
  late final Animation<double> _carnavalPulse;
  bool _isWeatherExpanded = false;
  bool _hasCenteredOnUser = false;
<<<<<<< Updated upstream
  late final AnimationController _carnavalPulseController;
  late final Animation<double> _carnavalPulse;
  double _currentZoom = _defaultZoom;

  static const double _cameraMinZoom = 8.0;
  static const int _cameraDisableClusteringAtZoom = 16;
=======
>>>>>>> Stashed changes

  // Centro do Rio de Janeiro
  static const _rioCenter = LatLng(-22.9068, -43.1729);
  static const _defaultZoom = 11.0;
  static const _carnavalImagePath = 'assets/images/carnaval2026.jpg';
  static const _carnavalAppUrl =
      'https://play.google.com/store/apps/details?id=br.com.roadmaps.BlocosRio2025';

  @override
  void initState() {
    super.initState();
    _mapController = fm.MapController();
    _carnavalPulseController = AnimationController(
      vsync: this,
<<<<<<< Updated upstream
      duration: const Duration(milliseconds: 1400),
=======
      duration: const Duration(seconds: 2),
>>>>>>> Stashed changes
    )..repeat(reverse: true);
    _carnavalPulse = CurvedAnimation(
      parent: _carnavalPulseController,
      curve: Curves.easeInOut,
    );

    // Solicita localização ao iniciar e configura listeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mapControllerProvider.notifier).getUserLocation();
      _setupFocusCommandListener();
      _setupUserLocationListener();
      _triggerInitialBboxFetch();
      // Garante refresh do status ao abrir a tela do mapa
      ref.read(statusControllerProvider.notifier).refresh();
      // Carrega alertas para o painel "Meus Alertas"
      ref.read(alertsControllerProvider.notifier).loadAlerts();
    });
  }

  /// Dispara fetch inicial para o bbox visível
  void _triggerInitialBboxFetch() {
    // Aguarda o mapa estar pronto
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      final camera = _mapController.camera;
      final bounds = camera.visibleBounds;

      if ((camera.zoom - _currentZoom).abs() > 0.05) {
        setState(() {
          _currentZoom = camera.zoom;
        });
      }

      ref.read(mapControllerProvider.notifier).onMapPositionChanged(
        north: bounds.north,
        south: bounds.south,
        east: bounds.east,
        west: bounds.west,
        zoom: camera.zoom,
      );
    });
  }

  /// Configura listener para comandos de foco
  void _setupFocusCommandListener() {
    ref.listenManual(mapFocusCommandProvider, (previous, next) {
      if (next != null) {
        _handleFocusCommand(next);
      }
    });
  }

  void _setupUserLocationListener() {
    ref.listenManual<LatLng?>(userLocationProvider, (previous, next) {
      if (next == null) return;
      if (_hasCenteredOnUser) return;
      if (widget.highlightArea != null) return;

      _hasCenteredOnUser = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _mapController.move(next, 14);
      });
    });
  }

  /// Executa comando de foco no mapa
  void _handleFocusCommand(MapFocusCommand command) {
    if (command.bounds != null) {
      _mapController.fitCamera(
        fm.CameraFit.bounds(
          bounds: command.bounds!,
          padding: EdgeInsets.all(command.padding),
        ),
      );
    } else if (command.center != null) {
      _mapController.move(command.center!, command.zoom ?? 15.0);
    }

    // Confirma que o comando foi processado
    ref.read(mapControllerProvider.notifier).acknowledgeFocusCommand();
  }

  @override
  void dispose() {
    _mapController.dispose();
    _carnavalPulseController.dispose();
    super.dispose();
  }

  void _centerOnUser() {
    final userLocation = ref.read(userLocationProvider);
    if (userLocation != null) {
      _mapController.move(userLocation, 14);
    } else {
      // Solicita localização se não tiver
      ref.read(mapControllerProvider.notifier).getUserLocation();
    }
  }

  Future<void> _openCarnivalAppLink() async {
    final uri = Uri.parse(_carnavalAppUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.appLinkError)),
      );
    }
  }

  void _showCarnivalModal() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (context) {
        return Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(color: Colors.black.withOpacity(0.2)),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFFD54F),
                          Color(0xFFFF6B35),
                          Color(0xFFEF4444),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.xl - 2),
                        child: Material(
                          color: AppColors.surface,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Stack(
                                children: [
                                  InkWell(
                                    onTap: () async {
                                      Navigator.of(context).pop();
                                      await _openCarnivalAppLink();
                                    },
                                    child: Image.asset(
                                      _carnavalImagePath,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: AppColors.surface,
                                          padding: const EdgeInsets.all(24),
                                          alignment: Alignment.center,
                                          child: const Text(
                                            'Imagem do Carnaval nao encontrada.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(color: AppColors.textPrimary),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Material(
                                      color: Colors.black.withOpacity(0.6),
                                      shape: const CircleBorder(),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        onPressed: () => Navigator.of(context).pop(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                color: AppColors.surface,
                                child: Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.sparkles,
                                      color: AppColors.accent,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Toque no banner para instalar o app do Carnaval.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () async {
                                        Navigator.of(context).pop();
                                        await _openCarnivalAppLink();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.accent,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(AppRadius.md),
                                        ),
                                      ),
                                      child: Text(AppLocalizations.of(context)!.install),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCarnivalButton() {
    return AnimatedBuilder(
      animation: _carnavalPulse,
      builder: (context, child) {
        final glowOpacity = 0.35 + (0.35 * _carnavalPulse.value);
        final blur = 16.0 + (12.0 * _carnavalPulse.value);
        final spread = 1.0 + (3.0 * _carnavalPulse.value);
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(glowOpacity),
                blurRadius: blur,
                spreadRadius: spread,
              ),
            ],
          ),
          child: child,
        );
      },
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: Ink(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFD54F),
                Color(0xFFFF6B35),
                Color(0xFFEF4444),
              ],
            ),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _showCarnivalModal,
            child: const Center(
              child: Icon(
                LucideIcons.partyPopper,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _centerOnLocation(LatLng location) {
    _mapController.move(location, 15);
  }

  void _showIncidentDetails(Incident incident) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => IncidentBottomSheet(
        incident: incident,
        onViewOnMap: () {
          Navigator.pop(context);
          if (incident.location != null) {
            _mapController.move(incident.location!, 15);
          }
        },
      ),
    );
  }

  void _showRainGaugeDetails(RainGauge gauge) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => RainGaugeBottomSheet(
        gauge: gauge,
        onViewOnMap: () {
          Navigator.pop(context);
          _mapController.move(gauge.location, 15);
        },
      ),
    );
  }

  void _showSirenDetails(Siren siren) {
    // Mostra detalhes simples da sirene em um snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              siren.isTriggered ? LucideIcons.bellRing : LucideIcons.bell,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    siren.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '${siren.statusLabel}${siren.basin != null ? ' - ${siren.basin}' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: siren.isTriggered
            ? AppColors.emergency
            : (siren.isOperational ? AppColors.success : AppColors.textMuted),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showCarnavalModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF00E5FF), // azul elétrico
                        Color(0xFFFFC400), // dourado
                        Color(0xFFFF4081), // rosa vibrante
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.celebration,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  'Blocos do Rio 2026',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Baixe o app oficial e acompanhe os blocos em tempo real.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _launchExternalUrl(
                          'https://apps.apple.com/br/app/blocos-do-rio-2026/id6740534225',
                        ),
                        icon: const Icon(LucideIcons.apple),
                        label: const Text('App Store'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _launchExternalUrl(
                          'https://play.google.com/store/apps/details?id=br.com.roadmaps.BlocosRio2025&pcampaignid=web_share',
                        ),
                        icon: const Icon(LucideIcons.play),
                        label: const Text('Google Play'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.divider),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Agora não',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openCameraPlayer(Camera camera) {
    // Abre o player diretamente em fullscreen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CameraPlayerScreen(camera: camera),
      ),
    );
  }

  void _showLayersBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => const MapLayersBottomSheet(),
      ),
    );
  }

  void _zoomToCluster(List<fm.Marker> markers) {
    if (markers.isEmpty) return;

    // Calcula bounds do cluster
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final marker in markers) {
      if (marker.point.latitude < minLat) minLat = marker.point.latitude;
      if (marker.point.latitude > maxLat) maxLat = marker.point.latitude;
      if (marker.point.longitude < minLng) minLng = marker.point.longitude;
      if (marker.point.longitude > maxLng) maxLng = marker.point.longitude;
    }

    final bounds = fm.LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    _mapController.fitCamera(
      fm.CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mapControllerProvider);
    final controller = ref.read(mapControllerProvider.notifier);
    final alertsState = ref.watch(alertsControllerProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Mapa
          fm.FlutterMap(
            mapController: _mapController,
            options: fm.MapOptions(
              initialCenter: widget.highlightArea ?? _rioCenter,
              initialZoom: widget.highlightArea != null ? 13 : _defaultZoom,
              minZoom: 8,
              maxZoom: 18,
              backgroundColor: state.layers.backgroundColor,
              onPositionChanged: (camera, hasGesture) {
                // Notifica o controller sobre mudança de posição para fetch por bbox
                final bounds = camera.visibleBounds;
                ref.read(mapControllerProvider.notifier).onMapPositionChanged(
                  north: bounds.north,
                  south: bounds.south,
                  east: bounds.east,
                  west: bounds.west,
                  zoom: camera.zoom,
                );


                final nextZoom = camera.zoom;
                if ((nextZoom - _currentZoom).abs() > 0.05) {
                  setState(() {
                    _currentZoom = nextZoom;
                  });
                }
              },
            ),
            children: [
              // Camada de tiles (tema configurável)
              fm.TileLayer(
                urlTemplate: state.layers.tileLayerUrl,
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'br.rio.cor.app',
                maxZoom: 19,
              ),

              // Camada de radar (overlay de imagem animado)
              if (state.layers.radarEnabled && state.currentRadarSnapshot != null)
                _buildRadarLayer(state.currentRadarSnapshot!, state.radar!.current.boundingBox),

              // Camada de área destacada (se vier de alerta)
              if (widget.highlightArea != null)
                fm.CircleLayer(
                  circles: [
                    fm.CircleMarker(
                      point: widget.highlightArea!,
                      radius: 500,
                      color: AppColors.primary.withOpacity(0.2),
                      borderColor: AppColors.primary,
                      borderStrokeWidth: 2,
                      useRadiusInMeter: true,
                    ),
                  ],
                ),

              // Camada de heatmap de chuva (antes dos markers para ficar atrás)
              if (state.layers.rainHeatmapEnabled && state.rainGauges != null)
                RainHeatmapLayer(
                  stations: state.rainGauges!.stations,
                  use1HourAccumulated: false,
                ),

              // Camada de pluviômetros com clustering
              if (state.layers.rainGaugesEnabled && state.rainGauges != null)
                MarkerClusterLayerWidget(
                  options: MarkerClusterLayerOptions(
                    maxClusterRadius: 80,
                    size: const Size(44, 44),
                    markers: state.rainGauges!.stations.map((gauge) {
                      return fm.Marker(
                        point: gauge.location,
                        width: 40,
                        height: 40,
                        child: RainGaugeMarkerWidget(
                          gauge: gauge,
                          onTap: () => _showRainGaugeDetails(gauge),
                        ),
                      );
                    }).toList(),
                    builder: (context, markers) {
                      return GestureDetector(
                        onTap: () => _zoomToCluster(markers),
                        child: RainGaugeClusterMarker(count: markers.length),
                      );
                    },
                  ),
                ),

              // Camada de sirenes com clustering
              if (state.layers.sirensEnabled && state.sirens != null)
                MarkerClusterLayerWidget(
                  options: MarkerClusterLayerOptions(
                    maxClusterRadius: 80,
                    size: const Size(40, 40),
                    markers: state.sirens!.sirens.map((siren) {
                      return fm.Marker(
                        point: siren.location,
                        width: 36,
                        height: 36,
                        child: SirenMarkerWidget(
                          siren: siren,
                          onTap: () => _showSirenDetails(siren),
                        ),
                      );
                    }).toList(),
                    builder: (context, markers) {
                      return GestureDetector(
                        onTap: () => _zoomToCluster(markers),
                        child: SirenClusterMarker(count: markers.length),
                      );
                    },
                  ),
                ),

              // Camada de incidentes com clustering e filtros
              if (state.layers.incidentsEnabled && state.incidents != null)
                MarkerClusterLayerWidget(
                  options: MarkerClusterLayerOptions(
                    maxClusterRadius: 80,
                    size: const Size(50, 50),
                    markers: state.filteredIncidents
                        .where((i) => i.location != null)
                        .map((incident) {
                      return fm.Marker(
                        point: incident.location!,
                        width: 44,
                        height: 44,
                        child: IncidentMarkerWidget(
                          incident: incident,
                          onTap: () => _showIncidentDetails(incident),
                        ),
                      );
                    }).toList(),
                    builder: (context, markers) {
                      return GestureDetector(
                        onTap: () => _zoomToCluster(markers),
                        child: IncidentClusterMarker(count: markers.length),
                      );
                    },
                  ),
                ),

              // Camada de câmeras com clustering
              if (state.layers.camerasEnabled)
                Consumer(
                  builder: (context, ref, _) {
                    final cameras = ref.watch(camerasProvider);
                    if (cameras == null || cameras.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    if (_currentZoom < _cameraMinZoom) {
                      return const SizedBox.shrink();
                    }
                    return MarkerClusterLayerWidget(
                      options: MarkerClusterLayerOptions(
                        maxClusterRadius: 80,
<<<<<<< Updated upstream
                        disableClusteringAtZoom: _cameraDisableClusteringAtZoom,
=======
                        disableClusteringAtZoom: 17,
                        zoomToBoundsOnClick: true,
                        spiderfyOnMaxZoom: true,
>>>>>>> Stashed changes
                        size: const Size(48, 48),
                        markers: cameras.map((camera) {
                          return fm.Marker(
                            point: camera.location,
                            width: 36,
                            height: 36,
                            child: CameraMarkerWidget(
                              camera: camera,
                              onTap: () => _openCameraPlayer(camera),
                            ),
                          );
                        }).toList(),
                        builder: (context, markers) {
                          return GestureDetector(
                            onTap: () => _zoomToCluster(markers),
                            child: SimpleCameraClusterMarker(count: markers.length),
                          );
                        },
                      ),
                    );
                  },
                ),

              // Marcador da localização do usuário
              if (state.userLocation != null)
                fm.MarkerLayer(
                  markers: [
                    fm.Marker(
                      point: state.userLocation!,
                      width: 24,
                      height: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

              // Camada de highlight animado (sempre por cima)
              const MapHighlightLayer(),
            ],
          ),

          // Barra operacional do COR no topo
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: CorOperationalTopBar(),
          ),

          // Widget de clima (abaixo da barra operacional) - fullwidth
          if (state.weather != null && !_isWeatherExpanded)
            Positioned(
              top: MediaQuery.of(context).padding.top + 76,
              left: 0,
              right: 0,
              child: WeatherWidget(
                weather: state.weather!,
                isExpanded: _isWeatherExpanded,
                mapTheme: state.layers.mapTheme,
                onTap: () {
                  setState(() {
                    _isWeatherExpanded = !_isWeatherExpanded;
                  });
                },
              ),
            ),

          // Dropdown do Alerta Rio - fullwidth colado no header
          if (_isWeatherExpanded && state.weather != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 76,
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isWeatherExpanded = false;
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Weather widget no topo do dropdown
                      WeatherWidget(
                        weather: state.weather!,
                        isExpanded: true,
                        mapTheme: state.layers.mapTheme,
                        onTap: () {
                          setState(() {
                            _isWeatherExpanded = false;
                          });
                        },
                      ),
                      // Dropdown com detalhes (usa forecast vazio se null)
                      Expanded(
                        child: WeatherDetailsDropdown(
                          forecast: state.alertaRioForecast ?? AlertaRioForecast(
                            city: 'Rio de Janeiro',
                            updatedAt: null,
                            items: [],
                            synoptic: null,
                            temperatures: [],
                            tides: [],
                            isStale: true,
                          ),
                          mapTheme: state.layers.mapTheme,
                          onClose: () {
                            setState(() {
                              _isWeatherExpanded = false;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Painel Cidade Agora (abaixo do clima) - esconde quando dropdown esta aberto
          if (!_isWeatherExpanded)
            Positioned(
              top: MediaQuery.of(context).padding.top + (state.weather != null ? 146 : 76),
              left: 0,
              right: 0,
              child: CityNowPanel(
                cards: CityNowHeuristics.generateCards(
                  incidents: state.incidents,
                  rainGauges: state.rainGauges,
                  activeAlerts: alertsState.activeAlerts,
                ),
                onViewOnMap: (location) {
                  // Usa o sistema de foco com highlight
                  controller.focusOnPoint(location, zoom: 15.0);
                },
              ),
            ),

          // Badge de highlight ativo (abaixo da barra operacional)
          if (state.hasActiveHighlight)
            Positioned(
              top: MediaQuery.of(context).padding.top + 76,
              right: AppSpacing.md,
              child: HighlightActiveBadge(
                onClear: controller.clearHighlight,
              ),
            ),

          // Overlay de timestamp do radar (no canto inferior esquerdo, acima da legenda do heatmap)
          if (state.layers.radarEnabled && state.currentRadarSnapshot != null)
            Positioned(
              left: AppSpacing.md,
              bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg +
                  (state.layers.rainHeatmapEnabled ? 40 : 0),
              child: RadarTimestampOverlay(
                timestamp: state.currentRadarSnapshot!.timestamp,
              ),
            ),

          // Legenda do heatmap de chuva
          if (state.layers.rainHeatmapEnabled && state.rainGauges != null)
            Positioned(
              left: AppSpacing.md,
              bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
              child: const CompactRainHeatmapLegend(),
            ),

          // Controle de timeline do radar na parte inferior
          if (state.layers.radarEnabled && state.radar != null && state.radar!.hasAnimation)
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
              child: RadarTimelineControl(
                radar: state.radar!,
                currentIndex: state.radarFrameIndex,
                isPlaying: state.isRadarAnimationPlaying,
                isLiveMode: state.isRadarLiveMode,
                onIndexChanged: controller.setRadarFrameIndex,
                onPlayPause: controller.toggleRadarAnimation,
                onLiveModeToggle: controller.toggleRadarLiveMode,
              ),
            ),

          // Botão de camadas e filtros
          Positioned(
            right: AppSpacing.md,
            bottom: 120,
            child: MapLayersButton(
              activeFilterCount: state.incidentFilters.activeFilterCount,
              onPressed: _showLayersBottomSheet,
            ),
          ),

          // Botão de centralizar
          Positioned(
            right: AppSpacing.md,
            bottom: 180,
            child: FloatingActionButton.small(
              heroTag: 'center',
              backgroundColor: AppColors.surface,
              onPressed: _centerOnUser,
              child: state.isLoadingLocation
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : Icon(
                      state.hasLocationPermission
                          ? LucideIcons.locateFixed
                          : LucideIcons.locate,
                      color: state.hasLocationPermission
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
            ),
          ),

          // Botão de refresh
          Positioned(
            right: AppSpacing.md,
            bottom: 240,
            child: FloatingActionButton.small(
              heroTag: 'refresh',
              backgroundColor: AppColors.surface,
              onPressed: () => controller.loadAllData(),
              child: state.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : const Icon(LucideIcons.refreshCw, color: AppColors.textPrimary),
            ),
          ),

          // Indicador de loading inicial
          if (state.isLoading &&
              state.radar == null &&
              state.incidents == null &&
              state.rainGauges == null)
            Container(
              color: AppColors.background.withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRadarLayer(RadarSnapshot snapshot, RadarBoundingBox bbox) {
    if (snapshot.url.isEmpty) {
      debugPrint('⚠️ Radar: URL vazia');
      return const SizedBox.shrink();
    }

    // Constrói URL completa se for relativa
    String imageUrl = snapshot.url;
    if (imageUrl.startsWith('/')) {
      final baseUrl = ref.read(baseUrlProvider);
      imageUrl = '$baseUrl$imageUrl';
    }

    // Usa o bounding box do próprio snapshot (mais preciso)
    final snapshotBbox = snapshot.boundingBox;

    debugPrint('🛰️ Radar URL: $imageUrl');
    debugPrint('📍 Radar Bounds: N=${snapshotBbox.north}, S=${snapshotBbox.south}, E=${snapshotBbox.east}, W=${snapshotBbox.west}');
    debugPrint('📍 BaseURL atual: ${ref.read(baseUrlProvider)}');

    final bounds = fm.LatLngBounds(
      LatLng(snapshotBbox.south, snapshotBbox.west),  // Southwest
      LatLng(snapshotBbox.north, snapshotBbox.east),  // Northeast
    );

    debugPrint('📍 LatLngBounds: SW=(${bounds.southWest}), NE=(${bounds.northEast})');

    // Usa Image.network com builder para garantir que carrega
    return Stack(
      children: [
        // Widget oculto para forçar carregamento e debug
        Positioned(
          left: -1000,
          child: Image.network(
            imageUrl,
            width: 1,
            height: 1,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                debugPrint('✅ Radar imagem carregada: $imageUrl');
              } else {
                final progress = loadingProgress.expectedTotalBytes != null
                    ? (loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! * 100).toStringAsFixed(0)
                    : '?';
                debugPrint('⏳ Carregando radar: $progress%');
              }
              return child;
            },
            errorBuilder: (context, error, stack) {
              debugPrint('❌ ERRO ao carregar radar: $error');
              debugPrint('❌ Stack: $stack');
              return const SizedBox.shrink();
            },
          ),
        ),
        // Camada de overlay do radar
        fm.OverlayImageLayer(
          overlayImages: [
            fm.OverlayImage(
              bounds: bounds,
              opacity: 0.85,
              imageProvider: NetworkImage(imageUrl),
            ),
          ],
        ),
      ],
    );
  }
}
