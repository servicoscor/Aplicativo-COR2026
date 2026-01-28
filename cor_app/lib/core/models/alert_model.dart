import 'package:latlong2/latlong.dart';

/// Modelo de Alerta
class Alert {
  final String id;
  final String title;
  final String body;
  final String severity; // info, alert, emergency
  final String status;   // draft, sent, canceled
  final bool broadcast;
  final DateTime createdAt;
  final DateTime? sentAt;
  final DateTime? expiresAt;
  final List<AlertArea>? areas;
  final List<String>? neighborhoods;
  final String? matchType; // broadcast, geo, neighborhood (do inbox)
  final bool isRead;
  final DateTime? readAt;

  Alert({
    required this.id,
    required this.title,
    required this.body,
    required this.severity,
    required this.status,
    required this.broadcast,
    required this.createdAt,
    this.sentAt,
    this.expiresAt,
    this.areas,
    this.neighborhoods,
    this.matchType,
    this.isRead = false,
    this.readAt,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    List<AlertArea>? areas;
    if (json['areas'] != null) {
      areas = (json['areas'] as List)
          .map((e) => AlertArea.fromJson(e))
          .toList();
    }

    List<String>? neighborhoods;
    if (json['neighborhoods'] != null) {
      neighborhoods = (json['neighborhoods'] as List).cast<String>();
    }

    return Alert(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      severity: json['severity'] ?? 'info',
      status: json['status'] ?? 'draft',
      broadcast: json['broadcast'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      sentAt: json['sent_at'] != null
          ? DateTime.parse(json['sent_at'])
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      areas: areas,
      neighborhoods: neighborhoods,
      matchType: json['match_type'],
      isRead: json['is_read'] ?? false,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'])
          : null,
    );
  }

  /// Cria uma cópia do alerta com campos modificados
  Alert copyWith({
    String? id,
    String? title,
    String? body,
    String? severity,
    String? status,
    bool? broadcast,
    DateTime? createdAt,
    DateTime? sentAt,
    DateTime? expiresAt,
    List<AlertArea>? areas,
    List<String>? neighborhoods,
    String? matchType,
    bool? isRead,
    DateTime? readAt,
  }) {
    return Alert(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      broadcast: broadcast ?? this.broadcast,
      createdAt: createdAt ?? this.createdAt,
      sentAt: sentAt ?? this.sentAt,
      expiresAt: expiresAt ?? this.expiresAt,
      areas: areas ?? this.areas,
      neighborhoods: neighborhoods ?? this.neighborhoods,
      matchType: matchType ?? this.matchType,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
    );
  }

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get hasGeometry => areas != null && areas!.isNotEmpty;
}

/// Área geográfica do alerta
class AlertArea {
  final String? id;
  final Map<String, dynamic>? geometry;

  AlertArea({this.id, this.geometry});

  factory AlertArea.fromJson(Map<String, dynamic> json) {
    return AlertArea(
      id: json['id']?.toString(),
      geometry: json['geometry'],
    );
  }

  /// Extrai coordenadas do polígono para desenhar no mapa
  List<LatLng>? getPolygonCoordinates() {
    if (geometry == null) return null;

    try {
      final type = geometry!['type'];
      if (type == 'Polygon') {
        final coords = geometry!['coordinates'] as List;
        if (coords.isNotEmpty) {
          final ring = coords[0] as List;
          return ring.map((c) {
            final coord = c as List;
            return LatLng(coord[1].toDouble(), coord[0].toDouble());
          }).toList();
        }
      } else if (type == 'MultiPolygon') {
        final coords = geometry!['coordinates'] as List;
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
      // Falha silenciosa se geometria for inválida
    }
    return null;
  }
}

/// Resposta da inbox de alertas
class AlertInboxResponse {
  final List<Alert> alerts;
  final int total;
  final int unreadCount;

  AlertInboxResponse({
    required this.alerts,
    required this.total,
    this.unreadCount = 0,
  });

  factory AlertInboxResponse.fromJson(Map<String, dynamic> json) {
    final items = json['data'] ?? json['items'] ?? json['alerts'] ?? [];
    final alerts = (items as List).map((e) => Alert.fromJson(e)).toList();
    return AlertInboxResponse(
      alerts: alerts,
      total: json['total'] ?? alerts.length,
      unreadCount: json['unread_count'] ?? alerts.where((a) => !a.isRead).length,
    );
  }
}
