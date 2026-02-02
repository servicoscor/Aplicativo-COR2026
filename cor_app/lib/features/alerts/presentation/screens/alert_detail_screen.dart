import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/models/alert_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/severity_badge.dart';
import '../../../map/presentation/controllers/map_controller.dart';
import '../controllers/alerts_controller.dart';

/// Tela de detalhes do alerta
class AlertDetailScreen extends ConsumerStatefulWidget {
  final Alert alert;

  const AlertDetailScreen({super.key, required this.alert});

  @override
  ConsumerState<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends ConsumerState<AlertDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Marca o alerta como lido quando a tela é aberta
    if (!widget.alert.isRead) {
      Future.microtask(() {
        ref.read(alertsControllerProvider.notifier).markAsRead(widget.alert.id);
      });
    }
  }

  Color get _severityColor {
    switch (widget.alert.severity) {
      case 'emergency':
        return AppColors.emergency;
      case 'alert':
        return AppColors.alert;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');
    final severity = Severity.fromString(alert.severity);
    final userLocation = ref.watch(userLocationProvider);

    // Determina centro do mapa
    LatLng? mapCenter;
    List<LatLng>? polygonPoints;

    if (alert.hasGeometry) {
      // Tenta extrair polígono da primeira área
      for (final area in alert.areas!) {
        polygonPoints = area.getPolygonCoordinates();
        if (polygonPoints != null && polygonPoints.isNotEmpty) {
          // Centraliza no centroide do polígono
          double sumLat = 0, sumLng = 0;
          for (final point in polygonPoints) {
            sumLat += point.latitude;
            sumLng += point.longitude;
          }
          mapCenter = LatLng(
            sumLat / polygonPoints.length,
            sumLng / polygonPoints.length,
          );
          break;
        }
      }
    }

    // Fallback para localização do usuário ou Rio
    mapCenter ??= userLocation ?? const LatLng(-22.9068, -43.1729);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar com gradiente de severidade
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      _severityColor.withOpacity(0.3),
                      AppColors.background,
                    ],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(LucideIcons.arrowLeft),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges
                  Row(
                    children: [
                      SeverityBadge(severity: severity),
                      const SizedBox(width: AppSpacing.sm),
                      if (alert.broadcast)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.radio,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Alerta Geral',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (alert.matchType == 'geo')
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.mapPin,
                                size: 14,
                                color: AppColors.accent,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Sua Região',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Título
                  Text(
                    alert.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Data/hora
                  Row(
                    children: [
                      const Icon(
                        LucideIcons.calendar,
                        size: 16,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        alert.sentAt != null
                            ? dateFormat.format(alert.sentAt!)
                            : dateFormat.format(alert.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (alert.expiresAt != null) ...[
                        const SizedBox(width: AppSpacing.lg),
                        Icon(
                          LucideIcons.clock,
                          size: 16,
                          color: alert.isExpired ? AppColors.error : AppColors.textMuted,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          alert.isExpired
                              ? 'Expirado'
                              : 'Válido até ${dateFormat.format(alert.expiresAt!)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: alert.isExpired ? AppColors.error : null,
                              ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Corpo do alerta
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Text(
                      alert.body,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            height: 1.6,
                          ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Mini mapa
                  Text(
                    'Área do Alerta',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.divider),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: mapCenter,
                        initialZoom: alert.hasGeometry ? 13 : 12,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                          subdomains: const ['a', 'b', 'c', 'd'],
                        ),

                        // Polígono da área
                        if (polygonPoints != null)
                          PolygonLayer(
                            polygons: [
                              Polygon(
                                points: polygonPoints,
                                color: _severityColor.withOpacity(0.2),
                                borderColor: _severityColor,
                                borderStrokeWidth: 2,
                              ),
                            ],
                          ),

                        // Marcador central se não tiver polígono
                        if (polygonPoints == null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: mapCenter,
                                width: 40,
                                height: 40,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _severityColor.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _severityColor,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    LucideIcons.alertTriangle,
                                    color: _severityColor,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),

                        // Localização do usuário
                        if (userLocation != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                point: userLocation,
                                width: 16,
                                height: 16,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Botão ver no mapa principal
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final controller = ref.read(mapControllerProvider.notifier);

                        // Se tiver polígono, foca com highlight de área
                        if (polygonPoints != null && polygonPoints.isNotEmpty) {
                          controller.focusOnPolygon(
                            polygonPoints,
                            color: _severityColor,
                            duration: const Duration(seconds: 20),
                          );
                        } else {
                          // Senão, foca no ponto central
                          controller.focusOnPoint(
                            mapCenter!, // Nunca null - tem fallback definido
                            zoom: 14.0,
                            color: _severityColor,
                          );
                        }

                        // Navega de volta para o mapa
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(LucideIcons.map),
                      label: Text(AppLocalizations.of(context)!.viewOnMap),
                    ),
                  ),

                  // Espaço para safe area
                  SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpacing.lg),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
