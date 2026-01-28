/// Modelo de snapshot de radar
class RadarSnapshot {
  final String id;
  final String url;
  final String? thumbnailUrl;
  final DateTime timestamp;
  final RadarBoundingBox boundingBox;
  final String? source;
  final String? productType;

  RadarSnapshot({
    required this.id,
    required this.url,
    this.thumbnailUrl,
    required this.timestamp,
    required this.boundingBox,
    this.source,
    this.productType,
  });

  factory RadarSnapshot.fromJson(Map<String, dynamic> json) {
    return RadarSnapshot(
      id: json['id']?.toString() ?? '',
      url: json['url'] ?? '',
      thumbnailUrl: json['thumbnail_url'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      boundingBox: RadarBoundingBox.fromJson(json['bounding_box'] ?? {}),
      source: json['source'],
      productType: json['product_type'],
    );
  }
}

/// Bounding box do radar
class RadarBoundingBox {
  final double north;
  final double south;
  final double east;
  final double west;

  RadarBoundingBox({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });

  factory RadarBoundingBox.fromJson(Map<String, dynamic> json) {
    // Coordenadas oficiais do radar Alerta Rio
    // Fonte: https://www.sistema-alerta-rio.com.br/upload/Mapa/mapaRadar.js
    // L.latLngBounds(L.latLng(-24.431567, -45.336972), L.latLng(-21.478793, -41.159092))
    return RadarBoundingBox(
      north: (json['north'] ?? -21.478793).toDouble(),
      south: (json['south'] ?? -24.431567).toDouble(),
      east: (json['east'] ?? -41.159092).toDouble(),
      west: (json['west'] ?? -45.336972).toDouble(),
    );
  }
}

/// Metadados do radar
class RadarMetadata {
  final String stationId;
  final String stationName;
  final double latitude;
  final double longitude;
  final int rangeKm;
  final int updateIntervalMinutes;

  RadarMetadata({
    required this.stationId,
    required this.stationName,
    required this.latitude,
    required this.longitude,
    required this.rangeKm,
    required this.updateIntervalMinutes,
  });

  factory RadarMetadata.fromJson(Map<String, dynamic> json) {
    // Coordenadas oficiais do Radar Sumaré (Alerta Rio)
    // Fonte: https://www.sistema-alerta-rio.com.br/upload/Mapa/mapaRadar.js
    // Centro do círculo: L.circle([-22.960849, -43.2646667], {radius: 138900})
    return RadarMetadata(
      stationId: json['station_id'] ?? '',
      stationName: json['station_name'] ?? 'Sumaré (Alerta Rio)',
      // Suporta tanto latitude/longitude quanto station_lat/station_lon
      latitude: (json['latitude'] ?? json['station_lat'] ?? -22.960849).toDouble(),
      longitude: (json['longitude'] ?? json['station_lon'] ?? -43.2646667).toDouble(),
      rangeKm: json['range_km'] ?? 139, // 138.9 km oficial
      updateIntervalMinutes: json['update_interval_minutes'] ?? 2,
    );
  }
}

/// Resposta do endpoint de radar
class RadarResponse {
  final RadarSnapshot current;
  final List<RadarSnapshot> previous;
  final RadarMetadata? metadata;
  final bool isStale;

  RadarResponse({
    required this.current,
    required this.previous,
    this.metadata,
    this.isStale = false,
  });

  factory RadarResponse.fromJson(Map<String, dynamic> json) {
    // Suporta tanto 'previous' quanto 'previous_snapshots' da API
    final previousData = json['previous'] ?? json['previous_snapshots'] ?? [];

    // Suporta tanto 'current' quanto 'data' da API
    final currentData = json['current'] ?? json['data'] ?? json;

    return RadarResponse(
      current: RadarSnapshot.fromJson(currentData),
      previous: (previousData as List)
          .map((e) => RadarSnapshot.fromJson(e))
          .toList(),
      metadata: json['metadata'] != null
          ? RadarMetadata.fromJson(json['metadata'])
          : null,
      isStale: json['is_stale'] ?? json['cache']?['stale'] ?? false,
    );
  }

  /// Retorna todos os snapshots ordenados por timestamp (mais antigo primeiro)
  List<RadarSnapshot> get allSnapshots {
    final all = [...previous, current];
    all.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return all;
  }

  /// Número total de snapshots disponíveis
  int get snapshotCount => previous.length + 1;

  /// Verifica se há animação disponível (mais de 1 snapshot)
  bool get hasAnimation => previous.isNotEmpty;
}
