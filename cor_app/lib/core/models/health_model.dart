/// Modelo de resposta do health check
class HealthResponse {
  final String status;
  final String? version;
  final DateTime timestamp;
  final Map<String, SourceHealth>? sources;
  final DatabaseHealth? database;
  final CacheHealth? cache;

  HealthResponse({
    required this.status,
    this.version,
    required this.timestamp,
    this.sources,
    this.database,
    this.cache,
  });

  bool get isHealthy => status == 'healthy';
  bool get isDegraded => status == 'degraded';
  bool get isUnhealthy => status == 'unhealthy';

  factory HealthResponse.fromJson(Map<String, dynamic> json) {
    Map<String, SourceHealth>? sources;
    if (json['sources'] != null) {
      sources = {};
      (json['sources'] as Map).forEach((key, value) {
        sources![key] = SourceHealth.fromJson(value);
      });
    }

    return HealthResponse(
      status: json['status'] ?? 'unknown',
      version: json['version'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      sources: sources,
      database: json['database'] != null
          ? DatabaseHealth.fromJson(json['database'])
          : null,
      cache: json['cache'] != null
          ? CacheHealth.fromJson(json['cache'])
          : null,
    );
  }
}

/// Health de uma fonte de dados
class SourceHealth {
  final String status;
  final DateTime? lastSuccess;
  final DateTime? lastError;
  final int? latencyMs;
  final int? requestCount;
  final int? errorCount;

  SourceHealth({
    required this.status,
    this.lastSuccess,
    this.lastError,
    this.latencyMs,
    this.requestCount,
    this.errorCount,
  });

  bool get isHealthy => status == 'healthy';

  factory SourceHealth.fromJson(Map<String, dynamic> json) {
    return SourceHealth(
      status: json['status'] ?? 'unknown',
      lastSuccess: json['last_success'] != null
          ? DateTime.parse(json['last_success'])
          : null,
      lastError: json['last_error'] != null
          ? DateTime.parse(json['last_error'])
          : null,
      latencyMs: json['latency_ms'],
      requestCount: json['request_count'],
      errorCount: json['error_count'],
    );
  }
}

/// Health do banco de dados
class DatabaseHealth {
  final String status;
  final int? latencyMs;

  DatabaseHealth({
    required this.status,
    this.latencyMs,
  });

  bool get isHealthy => status == 'healthy';

  factory DatabaseHealth.fromJson(Map<String, dynamic> json) {
    return DatabaseHealth(
      status: json['status'] ?? 'unknown',
      latencyMs: json['latency_ms'],
    );
  }
}

/// Health do cache
class CacheHealth {
  final String status;
  final int? latencyMs;

  CacheHealth({
    required this.status,
    this.latencyMs,
  });

  bool get isHealthy => status == 'healthy';

  factory CacheHealth.fromJson(Map<String, dynamic> json) {
    return CacheHealth(
      status: json['status'] ?? 'unknown',
      latencyMs: json['latency_ms'],
    );
  }
}
