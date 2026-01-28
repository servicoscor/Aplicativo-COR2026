import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';

/// Tipo de incidente
enum IncidentType {
  traffic,
  flooding,
  landslide,
  fire,
  accident,
  roadWork,
  event,
  utility,
  weatherAlert,
  unknown;

  String get label {
    switch (this) {
      case IncidentType.traffic:
        return 'Trânsito';
      case IncidentType.flooding:
        return 'Alagamento';
      case IncidentType.landslide:
        return 'Deslizamento';
      case IncidentType.fire:
        return 'Incêndio';
      case IncidentType.accident:
        return 'Acidente';
      case IncidentType.roadWork:
        return 'Obra';
      case IncidentType.event:
        return 'Evento';
      case IncidentType.utility:
        return 'Serviços';
      case IncidentType.weatherAlert:
        return 'Alerta Climático';
      case IncidentType.unknown:
        return 'Outro';
    }
  }

  IconData get icon {
    switch (this) {
      case IncidentType.traffic:
        return LucideIcons.car;
      case IncidentType.flooding:
        return LucideIcons.waves;
      case IncidentType.landslide:
        return LucideIcons.mountain;
      case IncidentType.fire:
        return LucideIcons.flame;
      case IncidentType.accident:
        return LucideIcons.alertTriangle;
      case IncidentType.roadWork:
        return LucideIcons.construction;
      case IncidentType.event:
        return LucideIcons.calendar;
      case IncidentType.utility:
        return LucideIcons.wrench;
      case IncidentType.weatherAlert:
        return LucideIcons.cloudLightning;
      case IncidentType.unknown:
        return LucideIcons.helpCircle;
    }
  }

  Color get color {
    switch (this) {
      case IncidentType.traffic:
        return AppColors.alert;
      case IncidentType.flooding:
        return AppColors.info;
      case IncidentType.landslide:
        return AppColors.emergency;
      case IncidentType.fire:
        return AppColors.emergency;
      case IncidentType.accident:
        return AppColors.alert;
      case IncidentType.roadWork:
        return AppColors.textSecondary;
      case IncidentType.event:
        return AppColors.success;
      case IncidentType.utility:
        return AppColors.textMuted;
      case IncidentType.weatherAlert:
        return AppColors.alert;
      case IncidentType.unknown:
        return AppColors.textMuted;
    }
  }

  static IncidentType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'traffic':
        return IncidentType.traffic;
      case 'flooding':
        return IncidentType.flooding;
      case 'landslide':
        return IncidentType.landslide;
      case 'fire':
        return IncidentType.fire;
      case 'accident':
        return IncidentType.accident;
      case 'road_work':
        return IncidentType.roadWork;
      case 'event':
        return IncidentType.event;
      case 'utility':
        return IncidentType.utility;
      case 'weather_alert':
        return IncidentType.weatherAlert;
      default:
        return IncidentType.unknown;
    }
  }
}

/// Severidade do incidente
enum IncidentSeverity {
  low,
  medium,
  high,
  critical;

  String get label {
    switch (this) {
      case IncidentSeverity.low:
        return 'Baixa';
      case IncidentSeverity.medium:
        return 'Média';
      case IncidentSeverity.high:
        return 'Alta';
      case IncidentSeverity.critical:
        return 'Crítica';
    }
  }

  Color get color {
    switch (this) {
      case IncidentSeverity.low:
        return AppColors.success;
      case IncidentSeverity.medium:
        return AppColors.alert;
      case IncidentSeverity.high:
        return AppColors.accent;
      case IncidentSeverity.critical:
        return AppColors.emergency;
    }
  }

  static IncidentSeverity fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'low':
        return IncidentSeverity.low;
      case 'medium':
        return IncidentSeverity.medium;
      case 'high':
        return IncidentSeverity.high;
      case 'critical':
        return IncidentSeverity.critical;
      default:
        return IncidentSeverity.medium;
    }
  }
}

/// Modelo de incidente
class Incident {
  final String id;
  final IncidentType type;
  final String title;
  final String? description;
  final IncidentSeverity severity;
  final String status;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic>? geometry;
  final List<String>? affectedRoutes;
  final List<String>? tags;
  final DateTime startedAt;
  final DateTime? endedAt;
  final DateTime? updatedAt;

  Incident({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    required this.severity,
    required this.status,
    this.latitude,
    this.longitude,
    this.geometry,
    this.affectedRoutes,
    this.tags,
    required this.startedAt,
    this.endedAt,
    this.updatedAt,
  });

  LatLng? get location {
    if (latitude != null && longitude != null) {
      return LatLng(latitude!, longitude!);
    }
    // Tentar extrair do geometry
    if (geometry != null) {
      try {
        final type = geometry!['type'];
        if (type == 'Point') {
          final coords = geometry!['coordinates'] as List;
          return LatLng(coords[1].toDouble(), coords[0].toDouble());
        }
      } catch (_) {}
    }
    return null;
  }

  factory Incident.fromJson(Map<String, dynamic> json) {
    return Incident(
      id: json['id']?.toString() ?? '',
      type: IncidentType.fromString(json['type']),
      title: json['title'] ?? '',
      description: json['description'],
      severity: IncidentSeverity.fromString(json['severity']),
      status: json['status'] ?? 'active',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      geometry: json['geometry'],
      affectedRoutes: json['affected_routes'] != null
          ? List<String>.from(json['affected_routes'])
          : null,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'])
          : null,
      startedAt: json['started_at'] != null
          ? DateTime.parse(json['started_at'])
          : DateTime.now(),
      endedAt: json['ended_at'] != null
          ? DateTime.parse(json['ended_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }
}

/// Resumo de incidentes
class IncidentSummary {
  final int total;
  final Map<String, int> byType;
  final Map<String, int> bySeverity;
  final Map<String, int> byStatus;

  IncidentSummary({
    required this.total,
    required this.byType,
    required this.bySeverity,
    required this.byStatus,
  });

  factory IncidentSummary.fromJson(Map<String, dynamic> json) {
    return IncidentSummary(
      total: json['total'] ?? 0,
      byType: Map<String, int>.from(json['by_type'] ?? {}),
      bySeverity: Map<String, int>.from(json['by_severity'] ?? {}),
      byStatus: Map<String, int>.from(json['by_status'] ?? {}),
    );
  }
}

/// Resposta do endpoint de incidentes
class IncidentResponse {
  final List<Incident> incidents;
  final IncidentSummary? summary;
  final bool isStale;

  IncidentResponse({
    required this.incidents,
    this.summary,
    this.isStale = false,
  });

  factory IncidentResponse.fromJson(Map<String, dynamic> json) {
    final incidentsData = json['incidents'] ?? json['items'] ?? [];
    return IncidentResponse(
      incidents: (incidentsData as List)
          .map((e) => Incident.fromJson(e))
          .toList(),
      summary: json['summary'] != null
          ? IncidentSummary.fromJson(json['summary'])
          : null,
      isStale: json['is_stale'] ?? false,
    );
  }
}
