import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/models.dart';
import '../controllers/map_controller.dart';

/// Configurações de limites para heurísticas do Cidade Agora
class CityNowConfig {
  /// Severidades mínimas de incidentes para exibir
  static const Set<IncidentSeverity> incidentSeverityThreshold = {
    IncidentSeverity.high,
    IncidentSeverity.critical,
  };

  /// Limite de mm/15min para alertar sobre chuva
  static const double rainThreshold15min = 10.0;

  /// Limite de mm/1h para alertar sobre chuva (alternativo)
  static const double rainThreshold1hour = 25.0;

  /// Máximo de cards a exibir
  static const int maxCards = 5;

  /// Tipos de incidentes prioritários
  static const Set<IncidentType> priorityIncidentTypes = {
    IncidentType.flooding,
    IncidentType.landslide,
    IncidentType.fire,
    IncidentType.accident,
  };
}

/// Tipo de card do Cidade Agora
enum CityNowCardType {
  incident,
  rainAlert,
  activeAlert,
}

/// Modelo de card para o Cidade Agora
class CityNowCard {
  final String id;
  final CityNowCardType type;
  final String title;
  final String description;
  final LatLng? location;
  final Color color;
  final IconData icon;
  final int priority; // Menor = mais importante
  final dynamic sourceData; // Dados originais (Incident, RainGauge, Alert)

  const CityNowCard({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.location,
    required this.color,
    required this.icon,
    this.priority = 50,
    this.sourceData,
  });

  /// Cria card a partir de incidente de alta severidade
  factory CityNowCard.fromIncident(Incident incident) {
    final severityLabel = incident.severity == IncidentSeverity.critical
        ? 'CRITICO'
        : 'GRAVE';

    return CityNowCard(
      id: 'incident_${incident.id}',
      type: CityNowCardType.incident,
      title: '$severityLabel: ${incident.type.label}',
      description: incident.title,
      location: incident.location,
      color: incident.severity.color,
      icon: incident.type.icon,
      priority: incident.severity == IncidentSeverity.critical ? 1 : 2,
      sourceData: incident,
    );
  }

  /// Cria card a partir de pluviometro com chuva intensa
  factory CityNowCard.fromRainGauge(RainGauge gauge) {
    final reading = gauge.currentReading;
    final value = reading?.value ?? 0;
    final value1h = reading?.accumulated1hour ?? value;

    String intensity;
    Color color;
    int priority;

    if (value >= 25 || value1h >= 50) {
      intensity = 'MUITO FORTE';
      color = const Color(0xFFF44336);
      priority = 3;
    } else if (value >= 10 || value1h >= 25) {
      intensity = 'FORTE';
      color = const Color(0xFFFF9800);
      priority = 4;
    } else {
      intensity = 'MODERADA';
      color = const Color(0xFFFFC107);
      priority = 5;
    }

    return CityNowCard(
      id: 'rain_${gauge.id}',
      type: CityNowCardType.rainAlert,
      title: 'Chuva $intensity',
      description: '${gauge.name}: ${value.toStringAsFixed(1)}mm/15min',
      location: gauge.location,
      color: color,
      icon: LucideIcons.cloudRain,
      priority: priority,
      sourceData: gauge,
    );
  }

  /// Cria card a partir de alerta ativo
  factory CityNowCard.fromAlert(Alert alert) {
    // Determina cor e prioridade baseado na severidade (String)
    Color color;
    int priority;
    switch (alert.severity) {
      case 'emergency':
        color = const Color(0xFFF44336);
        priority = 0;
        break;
      case 'alert':
        color = const Color(0xFFFF9800);
        priority = 1;
        break;
      default:
        color = const Color(0xFF2196F3);
        priority = 6;
    }

    return CityNowCard(
      id: 'alert_${alert.id}',
      type: CityNowCardType.activeAlert,
      title: alert.title,
      description: alert.body,
      location: null, // Alert não tem localização centralizada
      color: color,
      icon: LucideIcons.alertTriangle,
      priority: priority,
      sourceData: alert,
    );
  }
}

/// Servico de heuristicas para gerar cards do Cidade Agora
class CityNowHeuristics {
  /// Gera lista de cards baseado nos dados atuais
  static List<CityNowCard> generateCards({
    required IncidentResponse? incidents,
    required RainGaugeResponse? rainGauges,
    List<Alert>? activeAlerts,
    LatLng? mapCenter,
    double? visibleRadiusKm,
  }) {
    final cards = <CityNowCard>[];

    // 1. Incidentes de alta severidade
    if (incidents != null) {
      final highSeverityIncidents = incidents.incidents
          .where((i) =>
              CityNowConfig.incidentSeverityThreshold.contains(i.severity))
          .where((i) => i.location != null)
          .toList();

      // Ordena por severidade (critical primeiro)
      highSeverityIncidents.sort((a, b) {
        if (a.severity == IncidentSeverity.critical &&
            b.severity != IncidentSeverity.critical) {
          return -1;
        }
        if (b.severity == IncidentSeverity.critical &&
            a.severity != IncidentSeverity.critical) {
          return 1;
        }
        // Prioriza tipos importantes
        final aIsPriority =
            CityNowConfig.priorityIncidentTypes.contains(a.type);
        final bIsPriority =
            CityNowConfig.priorityIncidentTypes.contains(b.type);
        if (aIsPriority && !bIsPriority) return -1;
        if (bIsPriority && !aIsPriority) return 1;
        return 0;
      });

      for (final incident in highSeverityIncidents.take(3)) {
        cards.add(CityNowCard.fromIncident(incident));
      }
    }

    // 2. Pluviometros com chuva acima do limite
    if (rainGauges != null) {
      final heavyRainStations = rainGauges.stations.where((g) {
        final reading = g.currentReading;
        if (reading == null) return false;
        return reading.value >= CityNowConfig.rainThreshold15min ||
            (reading.accumulated1hour ?? 0) >= CityNowConfig.rainThreshold1hour;
      }).toList();

      // Ordena por intensidade (maior primeiro)
      heavyRainStations.sort((a, b) {
        final aValue = a.currentReading?.value ?? 0;
        final bValue = b.currentReading?.value ?? 0;
        return bValue.compareTo(aValue);
      });

      for (final gauge in heavyRainStations.take(2)) {
        cards.add(CityNowCard.fromRainGauge(gauge));
      }
    }

    // 3. Alertas ativos nao expirados
    if (activeAlerts != null) {
      final now = DateTime.now();
      final validAlerts = activeAlerts
          .where((a) => a.expiresAt == null || a.expiresAt!.isAfter(now))
          .toList();

      // Ordena por severidade (emergency > alert > info)
      validAlerts.sort((a, b) {
        const order = {'emergency': 2, 'alert': 1, 'info': 0};
        return (order[b.severity] ?? 0).compareTo(order[a.severity] ?? 0);
      });

      for (final alert in validAlerts.take(2)) {
        cards.add(CityNowCard.fromAlert(alert));
      }
    }

    // Ordena todos os cards por prioridade
    cards.sort((a, b) => a.priority.compareTo(b.priority));

    // Limita ao maximo configurado
    return cards.take(CityNowConfig.maxCards).toList();
  }
}

/// Widget do painel Cidade Agora
class CityNowPanel extends ConsumerStatefulWidget {
  final List<CityNowCard> cards;
  final Function(LatLng location)? onViewOnMap;
  final VoidCallback? onCardTap;

  const CityNowPanel({
    super.key,
    required this.cards,
    this.onViewOnMap,
    this.onCardTap,
  });

  @override
  ConsumerState<CityNowPanel> createState() => _CityNowPanelState();
}

class _CityNowPanelState extends ConsumerState<CityNowPanel>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = true;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    // Inicia expandido
    _animationController.value = 1.0;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.98),
            border: Border(
              bottom: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header colapsavel
              _buildHeader(),

              // Conteudo expandivel
              SizeTransition(
                sizeFactor: _expandAnimation,
                child: _buildCardsList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return GestureDetector(
      onTap: _toggleExpanded,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            // Ícone
            Icon(
              LucideIcons.radio,
              size: 24,
              color: AppColors.textPrimary,
            ),
            const SizedBox(width: AppSpacing.sm),
            // Título
            const Text(
              'Meus Alertas',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            // Separador
            Container(
              width: 1,
              height: 24,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              color: AppColors.divider,
            ),

            // Badge com contagem
            Expanded(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getUrgencyColor().withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.alertCircle,
                          size: 14,
                          color: _getUrgencyColor(),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.cards.length} ${widget.cards.length == 1 ? 'alerta' : 'alertas'}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getUrgencyColor(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Chevron
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: AnimatedRotation(
                turns: _isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  LucideIcons.chevronDown,
                  size: 16,
                  color: AppColors.textSecondary.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getUrgencyColor() {
    if (widget.cards.isEmpty) return AppColors.textMuted;

    final topPriority = widget.cards.first.priority;
    if (topPriority <= 1) return AppColors.emergency;
    if (topPriority <= 3) return AppColors.alert;
    if (topPriority <= 5) return AppColors.alert;
    return AppColors.info;
  }

  Widget _buildCardsList() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.only(
          left: AppSpacing.sm,
          right: AppSpacing.sm,
          bottom: AppSpacing.sm,
        ),
        scrollDirection: Axis.horizontal,
        itemCount: widget.cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          return _buildCard(widget.cards[index]);
        },
      ),
    );
  }

  Widget _buildCard(CityNowCard card) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: card.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: card.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header do card
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: card.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  card.icon,
                  size: 14,
                  color: card.color,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  card.title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: card.color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Descricao
          Text(
            card.description,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),

          const Spacer(),

          // Botao Ver no Mapa
          if (card.location != null)
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  widget.onViewOnMap?.call(card.location!);
                },
                icon: const Icon(LucideIcons.mapPin, size: 14),
                label: Text(AppLocalizations.of(context)!.viewOnMap),
                style: TextButton.styleFrom(
                  foregroundColor: card.color,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  textStyle: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Versao compacta do painel (apenas badge)
class CityNowBadge extends StatelessWidget {
  final int cardCount;
  final int urgencyLevel; // 0 = critico, 1 = alto, 2+ = medio
  final VoidCallback? onTap;

  const CityNowBadge({
    super.key,
    required this.cardCount,
    this.urgencyLevel = 2,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (cardCount == 0) return const SizedBox.shrink();

    final color = urgencyLevel <= 0
        ? AppColors.emergency
        : urgencyLevel <= 1
            ? AppColors.alert
            : const Color(0xFFFF9800);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.radio,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              '$cardCount',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
