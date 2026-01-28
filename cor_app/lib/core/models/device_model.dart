/// Modelo de dispositivo
class Device {
  final String id;
  final String platform;
  final String pushToken;
  final String? maskedToken;
  final List<String>? neighborhoods;
  final DateTime? lastLocationAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Device({
    required this.id,
    required this.platform,
    required this.pushToken,
    this.maskedToken,
    this.neighborhoods,
    this.lastLocationAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id']?.toString() ?? '',
      platform: json['platform'] ?? 'android',
      pushToken: json['push_token'] ?? '',
      maskedToken: json['masked_token'],
      neighborhoods: json['neighborhoods'] != null
          ? List<String>.from(json['neighborhoods'])
          : null,
      lastLocationAt: json['last_location_at'] != null
          ? DateTime.parse(json['last_location_at'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }
}

/// Request de registro de dispositivo
class DeviceRegisterRequest {
  final String platform;
  final String pushToken;
  final List<String>? neighborhoods;

  DeviceRegisterRequest({
    required this.platform,
    required this.pushToken,
    this.neighborhoods,
  });

  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      'push_token': pushToken,
      if (neighborhoods != null && neighborhoods!.isNotEmpty)
        'neighborhoods': neighborhoods,
    };
  }
}

/// Request de atualização de localização
class DeviceLocationRequest {
  final double latitude;
  final double longitude;

  DeviceLocationRequest({
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'lat': latitude,
      'lon': longitude,
    };
  }
}
