/// Models for Alerta Rio forecast data

/// Item de previsão por período
class AlertaRioForecastItem {
  final String period;
  final String? date;
  final String condition;
  final String? conditionIcon;
  final String? precipitation;
  final String? temperatureTrend;
  final String? windDirection;
  final String? windSpeed;

  AlertaRioForecastItem({
    required this.period,
    this.date,
    required this.condition,
    this.conditionIcon,
    this.precipitation,
    this.temperatureTrend,
    this.windDirection,
    this.windSpeed,
  });

  factory AlertaRioForecastItem.fromJson(Map<String, dynamic> json) {
    return AlertaRioForecastItem(
      period: json['period'] ?? '',
      date: json['date'],
      condition: json['condition'] ?? 'Desconhecido',
      conditionIcon: json['condition_icon'],
      precipitation: json['precipitation'],
      temperatureTrend: json['temperature_trend'],
      windDirection: json['wind_direction'],
      windSpeed: json['wind_speed'],
    );
  }
}

/// Temperatura por zona
class AlertaRioTemperatureZone {
  final String zone;
  final double? tempMin;
  final double? tempMax;

  AlertaRioTemperatureZone({
    required this.zone,
    this.tempMin,
    this.tempMax,
  });

  factory AlertaRioTemperatureZone.fromJson(Map<String, dynamic> json) {
    return AlertaRioTemperatureZone(
      zone: json['zone'] ?? '',
      tempMin: (json['temp_min'] as num?)?.toDouble(),
      tempMax: (json['temp_max'] as num?)?.toDouble(),
    );
  }
}

/// Informação de maré
class AlertaRioTide {
  final DateTime time;
  final double height;
  final String level;

  AlertaRioTide({
    required this.time,
    required this.height,
    required this.level,
  });

  factory AlertaRioTide.fromJson(Map<String, dynamic> json) {
    DateTime? parsedTime;
    try {
      final timeValue = json['time'];
      if (timeValue is String) {
        parsedTime = DateTime.tryParse(timeValue);
      }
    } catch (_) {
      // Silently ignore parse errors
    }

    return AlertaRioTide(
      time: parsedTime ?? DateTime.now(),
      height: (json['height'] as num?)?.toDouble() ?? 0.0,
      level: json['level'] ?? '',
    );
  }
}

/// Resumo sinótico
class AlertaRioSynoptic {
  final String summary;
  final DateTime? createdAt;

  AlertaRioSynoptic({
    required this.summary,
    this.createdAt,
  });

  factory AlertaRioSynoptic.fromJson(Map<String, dynamic> json) {
    return AlertaRioSynoptic(
      summary: json['summary'] ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }
}

/// Dados completos da previsão Alerta Rio
class AlertaRioForecast {
  final String city;
  final DateTime? updatedAt;
  final List<AlertaRioForecastItem> items;
  final AlertaRioSynoptic? synoptic;
  final List<AlertaRioTemperatureZone> temperatures;
  final List<AlertaRioTide> tides;
  final bool isStale;

  AlertaRioForecast({
    required this.city,
    this.updatedAt,
    required this.items,
    this.synoptic,
    required this.temperatures,
    required this.tides,
    this.isStale = false,
  });

  factory AlertaRioForecast.fromJson(Map<String, dynamic> json) {
    // Extrai e converte data para Map<String, dynamic>
    Map<String, dynamic> data;
    final rawData = json['data'];
    if (rawData is Map<String, dynamic>) {
      data = rawData;
    } else if (rawData is Map) {
      data = Map<String, dynamic>.from(rawData);
    } else {
      data = json;
    }

    // Parse items safely
    List<AlertaRioForecastItem> items = [];
    try {
      final itemsList = data['items'];
      if (itemsList is List) {
        for (final e in itemsList) {
          try {
            if (e is Map<String, dynamic>) {
              items.add(AlertaRioForecastItem.fromJson(e));
            } else if (e is Map) {
              items.add(AlertaRioForecastItem.fromJson(Map<String, dynamic>.from(e)));
            }
          } catch (_) {
            // Skip invalid items
          }
        }
      }
    } catch (_) {
      // Keep empty list
    }

    // Parse temperatures safely
    List<AlertaRioTemperatureZone> temperatures = [];
    try {
      final tempsList = data['temperatures'];
      if (tempsList is List) {
        for (final e in tempsList) {
          try {
            if (e is Map<String, dynamic>) {
              temperatures.add(AlertaRioTemperatureZone.fromJson(e));
            } else if (e is Map) {
              temperatures.add(AlertaRioTemperatureZone.fromJson(Map<String, dynamic>.from(e)));
            }
          } catch (_) {
            // Skip invalid items
          }
        }
      }
    } catch (_) {
      // Keep empty list
    }

    // Parse tides safely
    List<AlertaRioTide> tides = [];
    try {
      final tidesList = data['tides'];
      if (tidesList is List) {
        for (final e in tidesList) {
          try {
            if (e is Map<String, dynamic>) {
              tides.add(AlertaRioTide.fromJson(e));
            } else if (e is Map) {
              tides.add(AlertaRioTide.fromJson(Map<String, dynamic>.from(e)));
            }
          } catch (_) {
            // Skip invalid items
          }
        }
      }
    } catch (_) {
      // Keep empty list
    }

    // Parse synoptic safely
    AlertaRioSynoptic? synoptic;
    try {
      final synopticData = data['synoptic'];
      if (synopticData is Map<String, dynamic>) {
        synoptic = AlertaRioSynoptic.fromJson(synopticData);
      } else if (synopticData is Map) {
        synoptic = AlertaRioSynoptic.fromJson(Map<String, dynamic>.from(synopticData));
      }
    } catch (_) {
      // Keep null
    }

    return AlertaRioForecast(
      city: data['city'] ?? 'Rio de Janeiro',
      updatedAt: data['updated_at'] != null
          ? DateTime.tryParse(data['updated_at'].toString())
          : null,
      items: items,
      synoptic: synoptic,
      temperatures: temperatures,
      tides: tides,
      isStale: json['stale'] ?? false,
    );
  }

  /// Temperatura média calculada
  double get averageTemperature {
    if (temperatures.isEmpty) return 25.0;

    double sum = 0;
    int count = 0;
    for (final zone in temperatures) {
      final min = zone.tempMin ?? 0;
      final max = zone.tempMax ?? 0;
      if (min > 0 || max > 0) {
        sum += (min + max) / 2;
        count++;
      }
    }
    return count > 0 ? sum / count : 25.0;
  }

  /// Período atual (primeiro item)
  AlertaRioForecastItem? get currentPeriod =>
      items.isNotEmpty ? items.first : null;
}
