import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../features/settings/data/settings_repository.dart';
import 'fcm_service.dart';

/// Serviço de localização com atualização periódica
class LocationService {
  final SettingsRepository _settingsRepository;
  final FCMService? _fcmService;

  Timer? _locationTimer;
  LatLng? _lastKnownLocation;

  // Intervalo de atualização: 5 minutos
  static const _updateInterval = Duration(minutes: 5);

  LocationService(this._settingsRepository, this._fcmService);

  /// Última localização conhecida
  LatLng? get lastKnownLocation => _lastKnownLocation;

  /// Inicializa o serviço e começa atualizações periódicas
  Future<void> initialize() async {
    // Verifica se localização está habilitada nas preferências
    if (!_settingsRepository.isLocationEnabled) {
      if (kDebugMode) print('📍 Localização desabilitada nas preferências');
      return;
    }

    // Tenta obter localização inicial
    await updateLocation();

    // Inicia timer para atualizações periódicas
    _startPeriodicUpdates();
  }

  /// Atualiza localização atual
  Future<LatLng?> updateLocation() async {
    // Verifica se localização está habilitada
    if (!_settingsRepository.isLocationEnabled) {
      return _lastKnownLocation;
    }

    try {
      // Verifica se serviço está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) print('📍 Serviço de localização desabilitado');
        return _lastKnownLocation;
      }

      // Verifica permissão
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (kDebugMode) print('📍 Permissão de localização negada');
        return _lastKnownLocation;
      }

      // Obtém posição atual
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );

      _lastKnownLocation = LatLng(position.latitude, position.longitude);

      // Envia para o backend (se FCM disponível)
      if (_fcmService != null && _fcmService!.isAvailable) {
        await _fcmService!.updateLocation(
          position.latitude,
          position.longitude,
        );
      }

      if (kDebugMode) {
        print('📍 Localização atualizada: ${position.latitude}, ${position.longitude}');
      }

      return _lastKnownLocation;
    } catch (e) {
      if (kDebugMode) print('❌ Erro ao obter localização: $e');
      return _lastKnownLocation;
    }
  }

  /// Inicia atualizações periódicas
  void _startPeriodicUpdates() {
    _locationTimer?.cancel();

    _locationTimer = Timer.periodic(_updateInterval, (_) async {
      if (_settingsRepository.isLocationEnabled) {
        await updateLocation();
      }
    });

    if (kDebugMode) {
      print('📍 Atualizações periódicas de localização iniciadas (${_updateInterval.inMinutes} min)');
    }
  }

  /// Para atualizações periódicas
  void stopPeriodicUpdates() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  /// Reinicia o serviço (chamado quando preferências mudam)
  Future<void> restart() async {
    stopPeriodicUpdates();
    await initialize();
  }

  /// Limpa recursos
  void dispose() {
    stopPeriodicUpdates();
  }
}

/// Provider do Location Service
final locationServiceProvider = Provider<LocationService>((ref) {
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  // FCMService pode ser null se Firebase não estiver disponível
  FCMService? fcmService;
  try {
    fcmService = ref.watch(fcmServiceProvider);
  } catch (e) {
    if (kDebugMode) print('⚠️ FCMService não disponível para LocationService: $e');
  }
  return LocationService(settingsRepo, fcmService);
});

/// Provider para a última localização conhecida
final lastKnownLocationProvider = Provider<LatLng?>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  return locationService.lastKnownLocation;
});
