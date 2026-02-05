import 'package:latlong2/latlong.dart';

/// Status operacional da sirene
enum SirenStatus {
  inactive, // ds - Desativada
  active,   // at - Ativa (pronta)
  triggered, // ac - Acionada (em alarme)
  unknown,
}

/// Extensão para converter string em SirenStatus
extension SirenStatusExtension on String? {
  SirenStatus toSirenStatus() {
    switch (this?.toLowerCase()) {
      case 'ds':
      case 'inactive':
        return SirenStatus.inactive;
      case 'at':
      case 'active':
        return SirenStatus.active;
      case 'ac':
      case 'triggered':
        return SirenStatus.triggered;
      default:
        return SirenStatus.unknown;
    }
  }
}

/// Modelo de sirene
class Siren {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? basin;
  final bool online;
  final SirenStatus status;
  final String statusLabel;

  Siren({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.basin,
    required this.online,
    required this.status,
    required this.statusLabel,
  });

  LatLng get location => LatLng(latitude, longitude);

  /// Verifica se a sirene está acionada
  bool get isTriggered => status == SirenStatus.triggered;

  /// Verifica se a sirene está operacional
  bool get isOperational =>
      status == SirenStatus.active || status == SirenStatus.triggered;

  factory Siren.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status']?.toString();
    final online = json['online'] == true || json['online'] == 'true';
    final parsedStatus = statusStr.toSirenStatus();
    final normalizedStatus =
        (parsedStatus == SirenStatus.inactive && online)
            ? SirenStatus.active
            : parsedStatus;
    final labelFromApi = json['status_label'];
    final baseLabel = labelFromApi ?? _getStatusLabel(statusStr);
    final normalizedLabel = normalizedStatus == parsedStatus
        ? baseLabel
        : _labelForStatus(normalizedStatus);

    return Siren(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      basin: json['basin'],
      online: online,
      status: normalizedStatus,
      statusLabel: normalizedLabel,
    );
  }

  static String _getStatusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'ds':
      case 'inactive':
        return 'Desativada';
      case 'at':
      case 'active':
        return 'Ativa';
      case 'ac':
      case 'triggered':
        return 'Acionada';
      default:
        return 'Desconhecido';
    }
  }

  static String _labelForStatus(SirenStatus status) {
    switch (status) {
      case SirenStatus.inactive:
        return 'Desativada';
      case SirenStatus.active:
        return 'Ativa';
      case SirenStatus.triggered:
        return 'Acionada';
      case SirenStatus.unknown:
        return 'Desconhecido';
    }
  }
}

/// Resumo das sirenes
class SirensSummary {
  final int totalSirens;
  final int onlineSirens;
  final int activeSirens;
  final int triggeredSirens;
  final int inactiveSirens;

  SirensSummary({
    required this.totalSirens,
    required this.onlineSirens,
    required this.activeSirens,
    required this.triggeredSirens,
    required this.inactiveSirens,
  });

  factory SirensSummary.fromJson(Map<String, dynamic> json) {
    return SirensSummary(
      totalSirens: json['total_sirens'] ?? 0,
      onlineSirens: json['online_sirens'] ?? 0,
      activeSirens: json['active_sirens'] ?? 0,
      triggeredSirens: json['triggered_sirens'] ?? 0,
      inactiveSirens: json['inactive_sirens'] ?? 0,
    );
  }
}

/// Resposta do endpoint de sirenes
class SirensResponse {
  final List<Siren> sirens;
  final SirensSummary? summary;
  final DateTime? dataTimestamp;
  final bool isStale;

  SirensResponse({
    required this.sirens,
    this.summary,
    this.dataTimestamp,
    this.isStale = false,
  });

  factory SirensResponse.fromJson(Map<String, dynamic> json) {
    // Backend envia 'data', mas pode ser 'sirens'
    final sirensData = json['data'] ?? json['sirens'] ?? [];
    return SirensResponse(
      sirens: (sirensData as List)
          .map((e) => Siren.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary: json['summary'] != null
          ? SirensSummary.fromJson(json['summary'])
          : null,
      dataTimestamp: json['data_timestamp'] != null
          ? DateTime.tryParse(json['data_timestamp'])
          : null,
      isStale: json['is_stale'] ?? json['stale'] ?? false,
    );
  }
}
