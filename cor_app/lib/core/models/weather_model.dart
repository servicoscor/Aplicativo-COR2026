/// Helper para converter valores que podem vir como String ou num
int _parseIntSafe(dynamic value, [int defaultValue = 0]) {
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? defaultValue;
  return defaultValue;
}

double _parseDoubleSafe(dynamic value, [double defaultValue = 0.0]) {
  if (value == null) return defaultValue;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? defaultValue;
  return defaultValue;
}

/// Modelo de clima atual
class Weather {
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double pressure;
  final double windSpeed;
  final int windDirection;
  final double? visibility;
  final int? uvIndex;
  final String? condition;
  final String? conditionIcon;
  final DateTime? timestamp;
  final bool isStale;

  Weather({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.pressure,
    required this.windSpeed,
    required this.windDirection,
    this.visibility,
    this.uvIndex,
    this.condition,
    this.conditionIcon,
    this.timestamp,
    this.isStale = false,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      temperature: _parseDoubleSafe(json['temperature']),
      feelsLike: _parseDoubleSafe(json['feels_like'] ?? json['temperature']),
      humidity: _parseIntSafe(json['humidity']),
      pressure: _parseDoubleSafe(json['pressure']),
      windSpeed: _parseDoubleSafe(json['wind_speed']),
      windDirection: _parseIntSafe(json['wind_direction']),
      visibility: json['visibility'] != null ? _parseDoubleSafe(json['visibility']) : null,
      uvIndex: json['uv_index'] != null ? _parseIntSafe(json['uv_index']) : null,
      condition: json['condition'],
      conditionIcon: json['condition_icon'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : null,
      isStale: json['is_stale'] ?? false,
    );
  }
}

/// Modelo de previsão por hora
class HourlyForecast {
  final DateTime time;
  final double temperature;
  final int humidity;
  final double precipProbability;
  final double windSpeed;
  final String? condition;
  final String? conditionIcon;

  HourlyForecast({
    required this.time,
    required this.temperature,
    required this.humidity,
    required this.precipProbability,
    required this.windSpeed,
    this.condition,
    this.conditionIcon,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    return HourlyForecast(
      time: DateTime.parse(json['time'] ?? json['datetime']),
      temperature: _parseDoubleSafe(json['temperature']),
      humidity: _parseIntSafe(json['humidity']),
      precipProbability: _parseDoubleSafe(json['precip_probability']),
      windSpeed: _parseDoubleSafe(json['wind_speed']),
      condition: json['condition'],
      conditionIcon: json['condition_icon'],
    );
  }
}

/// Resposta da previsão
class ForecastResponse {
  final List<HourlyForecast> hourly;
  final bool isStale;

  ForecastResponse({required this.hourly, this.isStale = false});

  factory ForecastResponse.fromJson(Map<String, dynamic> json) {
    final hourlyData = json['hourly'] ?? json['forecast'] ?? [];
    return ForecastResponse(
      hourly: (hourlyData as List)
          .map((e) => HourlyForecast.fromJson(e))
          .toList(),
      isStale: json['is_stale'] ?? false,
    );
  }
}
