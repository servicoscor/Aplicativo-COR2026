import 'package:latlong2/latlong.dart';

/// Modelo de pluviômetro
class RainGauge {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String? neighborhood;
  final String? region;
  final double? altitude;
  final String status;
  final RainReading? currentReading;

  RainGauge({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.neighborhood,
    this.region,
    this.altitude,
    required this.status,
    this.currentReading,
  });

  LatLng get location => LatLng(latitude, longitude);

  factory RainGauge.fromJson(Map<String, dynamic> json) {
    // Backend pode enviar como 'last_reading' ou 'current_reading'
    final readingJson = json['last_reading'] ?? json['current_reading'];

    return RainGauge(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      neighborhood: json['neighborhood'],
      region: json['region'],
      altitude: json['altitude_m']?.toDouble() ?? json['altitude']?.toDouble(),
      status: json['status'] ?? 'active',
      currentReading: readingJson != null
          ? RainReading.fromJson(readingJson)
          : null,
    );
  }
}

/// Leitura de chuva
class RainReading {
  final double value;
  final double? accumulated5min;
  final double? accumulated15min;
  final double? accumulated1hour;
  final double? accumulated4hours;
  final double? accumulated24hours;
  final double? accumulated96hours;
  final double? accumulatedMonth;
  final String? intensity;
  final DateTime timestamp;

  RainReading({
    required this.value,
    this.accumulated5min,
    this.accumulated15min,
    this.accumulated1hour,
    this.accumulated4hours,
    this.accumulated24hours,
    this.accumulated96hours,
    this.accumulatedMonth,
    this.intensity,
    required this.timestamp,
  });

  factory RainReading.fromJson(Map<String, dynamic> json) {
    // Backend envia 'value_mm', Flutter usava 'value'
    final value = (json['value_mm'] ?? json['value'] ?? 0).toDouble();

    // Campos de acumulação
    final acc5min = json['accumulated_5min'];
    final acc15min = json['accumulated_15min'];
    final acc1h = json['accumulated_1h'] ?? json['accumulated_1hour'];
    final acc4h = json['accumulated_4h'] ?? json['accumulated_4hours'];
    final acc24h = json['accumulated_24h'] ?? json['accumulated_24hours'];
    final acc96h = json['accumulated_96h'] ?? json['accumulated_96hours'];
    final accMonth = json['accumulated_month'];

    return RainReading(
      value: value,
      accumulated5min: acc5min?.toDouble(),
      accumulated15min: acc15min?.toDouble(),
      accumulated1hour: acc1h?.toDouble(),
      accumulated4hours: acc4h?.toDouble(),
      accumulated24hours: acc24h?.toDouble(),
      accumulated96hours: acc96h?.toDouble(),
      accumulatedMonth: accMonth?.toDouble(),
      intensity: json['intensity'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  /// Cor baseada na intensidade
  String get intensityColor {
    switch (intensity?.toLowerCase()) {
      case 'none':
        return '#94A3B8'; // Cinza
      case 'light':
        return '#22C55E'; // Verde
      case 'moderate':
        return '#F59E0B'; // Amarelo
      case 'heavy':
        return '#F97316'; // Laranja
      case 'very_heavy':
        return '#EF4444'; // Vermelho
      default:
        return '#94A3B8';
    }
  }
}

/// Resumo dos pluviômetros
class RainGaugeSummary {
  final int totalStations;
  final int activeStations;
  final int stationsWithRain;
  final double maxValue;
  final double averageValue;
  final String? maxStation;

  RainGaugeSummary({
    required this.totalStations,
    required this.activeStations,
    required this.stationsWithRain,
    required this.maxValue,
    required this.averageValue,
    this.maxStation,
  });

  factory RainGaugeSummary.fromJson(Map<String, dynamic> json) {
    // Backend envia 'max_rain_15min' e 'avg_rain_1h'
    final maxValue = json['max_rain_15min'] ?? json['max_rain_1h'] ?? json['max_value'] ?? 0;
    final avgValue = json['avg_rain_1h'] ?? json['average_value'] ?? 0;

    return RainGaugeSummary(
      totalStations: json['total_stations'] ?? 0,
      activeStations: json['active_stations'] ?? 0,
      stationsWithRain: json['stations_with_rain'] ?? 0,
      maxValue: (maxValue).toDouble(),
      averageValue: (avgValue).toDouble(),
      maxStation: json['max_station'],
    );
  }
}

/// Resposta do endpoint de pluviômetros
class RainGaugeResponse {
  final List<RainGauge> stations;
  final RainGaugeSummary? summary;
  final bool isStale;

  RainGaugeResponse({
    required this.stations,
    this.summary,
    this.isStale = false,
  });

  factory RainGaugeResponse.fromJson(Map<String, dynamic> json) {
    // Backend envia 'data', mas pode ser 'stations' ou 'items'
    final stationsData = json['data'] ?? json['stations'] ?? json['items'] ?? [];
    return RainGaugeResponse(
      stations: (stationsData as List)
          .map((e) => RainGauge.fromJson(e as Map<String, dynamic>))
          .toList(),
      summary: json['summary'] != null
          ? RainGaugeSummary.fromJson(json['summary'])
          : null,
      isStale: json['is_stale'] ?? json['stale'] ?? false,
    );
  }
}
