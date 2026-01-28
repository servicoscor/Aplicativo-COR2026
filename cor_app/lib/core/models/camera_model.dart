// Modelo de câmera do COR
//
// As câmeras são fornecidas pela API Tixxi e exibidas no mapa
// com clustering para não poluir a visualização.

import 'package:latlong2/latlong.dart';

/// Tipo de câmera
enum CameraType {
  /// Câmera fixa (tem "fixa" no nome)
  fixed,

  /// Câmera móvel
  mobile,
}

/// Modelo de uma câmera do COR
class Camera {
  /// Código único da câmera (usado na URL de streaming)
  final String code;

  /// Chave de autenticação para acesso ao stream
  final String key;

  /// Nome/descrição da câmera
  final String name;

  /// Localização da câmera
  final LatLng location;

  /// Tipo da câmera (fixa ou móvel)
  final CameraType type;

  /// Status da câmera (online/offline)
  final bool isOnline;

  /// URL base do streaming
  static const String _streamBaseUrl = 'https://dev.tixxi.rio/outvideo3/';

  const Camera({
    required this.code,
    required this.key,
    required this.name,
    required this.location,
    required this.type,
    this.isOnline = true,
  });

  /// Determina o tipo baseado no nome
  static CameraType typeFromName(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('fixa') || lowerName.contains('fixas')) {
      return CameraType.fixed;
    }
    return CameraType.mobile;
  }

  /// URL completa do stream de vídeo
  String get streamUrl => '$_streamBaseUrl?CODE=$code&KEY=$key';

  /// Se é câmera fixa
  bool get isFixed => type == CameraType.fixed;

  /// Se é câmera móvel
  bool get isMobile => type == CameraType.mobile;

  /// Cria câmera a partir de JSON da API
  factory Camera.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? json['nome'] as String? ?? '';
    final code = json['code']?.toString() ?? json['codigo']?.toString() ?? '';
    final key = json['key'] as String? ?? json['chave'] as String? ?? 'G5325';

    // Tenta extrair latitude/longitude de diferentes formatos
    double lat = 0.0;
    double lng = 0.0;

    if (json['latitude'] != null && json['longitude'] != null) {
      lat = (json['latitude'] as num).toDouble();
      lng = (json['longitude'] as num).toDouble();
    } else if (json['lat'] != null && json['lng'] != null) {
      lat = (json['lat'] as num).toDouble();
      lng = (json['lng'] as num).toDouble();
    } else if (json['location'] != null) {
      final loc = json['location'];
      if (loc is Map) {
        lat = (loc['lat'] ?? loc['latitude'] ?? 0.0 as num).toDouble();
        lng = (loc['lng'] ?? loc['longitude'] ?? 0.0 as num).toDouble();
      } else if (loc is List && loc.length >= 2) {
        lat = (loc[0] as num).toDouble();
        lng = (loc[1] as num).toDouble();
      }
    }

    return Camera(
      code: code,
      key: key,
      name: name,
      location: LatLng(lat, lng),
      type: Camera.typeFromName(name),
      isOnline: json['online'] as bool? ?? (json['status'] == 'online' || json['status'] == null),
    );
  }

  Map<String, dynamic> toJson() => {
    'code': code,
    'key': key,
    'name': name,
    'latitude': location.latitude,
    'longitude': location.longitude,
    'type': type.name,
    'online': isOnline,
  };

  @override
  String toString() => 'Camera($code: $name)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Camera &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

/// Resposta da API de câmeras
class CamerasResponse {
  final List<Camera> cameras;
  final int totalCount;
  final DateTime fetchedAt;

  const CamerasResponse({
    required this.cameras,
    required this.totalCount,
    required this.fetchedAt,
  });

  /// Quantidade de câmeras fixas
  int get fixedCount => cameras.where((c) => c.isFixed).length;

  /// Quantidade de câmeras móveis
  int get mobileCount => cameras.where((c) => c.isMobile).length;

  /// Câmeras online
  List<Camera> get onlineCameras => cameras.where((c) => c.isOnline).toList();

  factory CamerasResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> cameraList = json['cameras'] ??
        json['data'] ??
        json['items'] ??
        (json is List ? json : []);

    final cameras = cameraList
        .map((c) => Camera.fromJson(c as Map<String, dynamic>))
        .where((c) => c.location.latitude != 0.0 && c.location.longitude != 0.0)
        .toList();

    return CamerasResponse(
      cameras: cameras,
      totalCount: json['total'] as int? ?? cameras.length,
      fetchedAt: DateTime.now(),
    );
  }
}
