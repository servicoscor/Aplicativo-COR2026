import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../models/camera_model.dart';

/// Serviço de câmeras do COR
///
/// Busca câmeras da API Tixxi e fornece dados para o mapa.
/// Atualmente usando dados mock até integração completa com API.
class CameraService {
  final Dio _dio;

  // URL base da API Tixxi (ajustar quando soubermos o endpoint correto)
  static const String _baseUrl = 'https://dev.tixxi.rio';

  // Se true, usa dados mock ao invés da API real
  static const bool _useMockData = true;

  CameraService(this._dio);

  /// Busca todas as câmeras disponíveis
  Future<CamerasResponse> getCameras() async {
    if (_useMockData) {
      return _getMockCameras();
    }

    try {
      // Tentativa de endpoint real (ajustar quando soubermos)
      final response = await _dio.get(
        '$_baseUrl/api/cameras',
        options: Options(
          headers: {'Accept': 'application/json'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        return CamerasResponse.fromJson(response.data);
      }

      throw Exception('Erro ao buscar câmeras: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao buscar câmeras da API, usando mock: $e');
      }
      // Fallback para mock se API falhar
      return _getMockCameras();
    }
  }

  /// Busca câmeras dentro de um bounding box
  Future<CamerasResponse> getCamerasInBbox({
    required double north,
    required double south,
    required double east,
    required double west,
  }) async {
    final allCameras = await getCameras();

    final filtered = allCameras.cameras.where((camera) {
      final lat = camera.location.latitude;
      final lng = camera.location.longitude;
      return lat >= south && lat <= north && lng >= west && lng <= east;
    }).toList();

    return CamerasResponse(
      cameras: filtered,
      totalCount: filtered.length,
      fetchedAt: DateTime.now(),
    );
  }

  /// Gera dados mock de câmeras do Rio de Janeiro
  Future<CamerasResponse> _getMockCameras() async {
    // Simula delay de rede
    await Future.delayed(const Duration(milliseconds: 300));

    // Localizações reais de pontos importantes do Rio
    final mockCameras = <Camera>[
      // Câmeras fixas em locais importantes
      Camera(
        code: '001',
        key: 'G5325',
        name: 'Câmera Fixa - Copacabana Posto 6',
        location: const LatLng(-22.9714, -43.1823),
        type: CameraType.fixed,
      ),
      Camera(
        code: '002',
        key: 'G5325',
        name: 'Câmera Fixa - Ipanema Posto 9',
        location: const LatLng(-22.9867, -43.2044),
        type: CameraType.fixed,
      ),
      Camera(
        code: '003',
        key: 'G5325',
        name: 'Câmera Fixa - Leblon',
        location: const LatLng(-22.9855, -43.2237),
        type: CameraType.fixed,
      ),
      Camera(
        code: '004',
        key: 'G5325',
        name: 'Câmera Fixa - Centro ALERJ',
        location: const LatLng(-22.9068, -43.1729),
        type: CameraType.fixed,
      ),
      Camera(
        code: '005',
        key: 'G5325',
        name: 'Câmera Fixa - Av. Brasil Penha',
        location: const LatLng(-22.8384, -43.2824),
        type: CameraType.fixed,
      ),
      Camera(
        code: '006',
        key: 'G5325',
        name: 'Câmera Fixa - Linha Vermelha Fundão',
        location: const LatLng(-22.8563, -43.2361),
        type: CameraType.fixed,
      ),
      Camera(
        code: '007',
        key: 'G5325',
        name: 'Câmera Fixa - Maracanã',
        location: const LatLng(-22.9121, -43.2302),
        type: CameraType.fixed,
      ),
      Camera(
        code: '008',
        key: 'G5325',
        name: 'Câmera Fixa - Barra Shopping',
        location: const LatLng(-23.0000, -43.3651),
        type: CameraType.fixed,
      ),
      Camera(
        code: '009',
        key: 'G5325',
        name: 'Câmera Fixa - Recreio dos Bandeirantes',
        location: const LatLng(-23.0224, -43.4680),
        type: CameraType.fixed,
      ),
      Camera(
        code: '010',
        key: 'G5325',
        name: 'Câmera Fixa - Aeroporto Santos Dumont',
        location: const LatLng(-22.9104, -43.1631),
        type: CameraType.fixed,
      ),
      Camera(
        code: '011',
        key: 'G5325',
        name: 'Câmera Fixa - Túnel Rebouças Entrada',
        location: const LatLng(-22.9556, -43.2089),
        type: CameraType.fixed,
      ),
      Camera(
        code: '012',
        key: 'G5325',
        name: 'Câmera Fixa - Túnel Santa Bárbara',
        location: const LatLng(-22.9233, -43.1883),
        type: CameraType.fixed,
      ),
      Camera(
        code: '013',
        key: 'G5325',
        name: 'Câmera Fixa - Ponte Rio-Niterói Pedágio',
        location: const LatLng(-22.8730, -43.1370),
        type: CameraType.fixed,
      ),
      Camera(
        code: '014',
        key: 'G5325',
        name: 'Câmera Fixa - Av. Presidente Vargas',
        location: const LatLng(-22.9039, -43.1778),
        type: CameraType.fixed,
      ),
      Camera(
        code: '015',
        key: 'G5325',
        name: 'Câmera Fixa - Rodoviária Novo Rio',
        location: const LatLng(-22.8986, -43.2094),
        type: CameraType.fixed,
      ),

      // Câmeras móveis
      Camera(
        code: '101',
        key: 'G5325',
        name: 'Câmera Móvel - Viatura COR 01',
        location: const LatLng(-22.9149, -43.1806),
        type: CameraType.mobile,
      ),
      Camera(
        code: '102',
        key: 'G5325',
        name: 'Câmera Móvel - Viatura COR 02',
        location: const LatLng(-22.9534, -43.1736),
        type: CameraType.mobile,
      ),
      Camera(
        code: '103',
        key: 'G5325',
        name: 'Câmera Móvel - Viatura COR 03',
        location: const LatLng(-22.8756, -43.3339),
        type: CameraType.mobile,
      ),
      Camera(
        code: '104',
        key: 'G5325',
        name: 'Câmera Móvel - Viatura COR 04',
        location: const LatLng(-22.9823, -43.2145),
        type: CameraType.mobile,
      ),
      Camera(
        code: '105',
        key: 'G5325',
        name: 'Câmera Móvel - Viatura COR 05',
        location: const LatLng(-22.9301, -43.2456),
        type: CameraType.mobile,
      ),
      Camera(
        code: '106',
        key: 'G5325',
        name: 'Câmera Móvel - Drone COR 01',
        location: const LatLng(-22.9456, -43.1923),
        type: CameraType.mobile,
      ),
      Camera(
        code: '107',
        key: 'G5325',
        name: 'Câmera Móvel - Drone COR 02',
        location: const LatLng(-22.8912, -43.2789),
        type: CameraType.mobile,
      ),
      Camera(
        code: '108',
        key: 'G5325',
        name: 'Câmera Móvel - Moto COR 01',
        location: const LatLng(-22.9667, -43.1856),
        type: CameraType.mobile,
      ),

      // Mais câmeras fixas em vias importantes
      Camera(
        code: '016',
        key: 'G5325',
        name: 'Câmera Fixa - Autoestrada Lagoa-Barra',
        location: const LatLng(-22.9912, -43.2567),
        type: CameraType.fixed,
      ),
      Camera(
        code: '017',
        key: 'G5325',
        name: 'Câmera Fixa - Av. Niemeyer',
        location: const LatLng(-22.9978, -43.2456),
        type: CameraType.fixed,
      ),
      Camera(
        code: '018',
        key: 'G5325',
        name: 'Câmera Fixa - Linha Amarela Anil',
        location: const LatLng(-22.9245, -43.3456),
        type: CameraType.fixed,
      ),
      Camera(
        code: '019',
        key: 'G5325',
        name: 'Câmera Fixa - Campo Grande Centro',
        location: const LatLng(-22.9036, -43.5598),
        type: CameraType.fixed,
      ),
      Camera(
        code: '020',
        key: 'G5325',
        name: 'Câmera Fixa - Santa Cruz',
        location: const LatLng(-22.9186, -43.6867),
        type: CameraType.fixed,
      ),
      Camera(
        code: '021',
        key: 'G5325',
        name: 'Câmera Fixa - Jacarepaguá',
        location: const LatLng(-22.9512, -43.3923),
        type: CameraType.fixed,
      ),
      Camera(
        code: '022',
        key: 'G5325',
        name: 'Câmera Fixa - Tijuca Praça Saens Peña',
        location: const LatLng(-22.9234, -43.2345),
        type: CameraType.fixed,
      ),
      Camera(
        code: '023',
        key: 'G5325',
        name: 'Câmera Fixa - Méier',
        location: const LatLng(-22.9023, -43.2789),
        type: CameraType.fixed,
      ),
      Camera(
        code: '024',
        key: 'G5325',
        name: 'Câmera Fixa - Madureira',
        location: const LatLng(-22.8734, -43.3389),
        type: CameraType.fixed,
      ),
      Camera(
        code: '025',
        key: 'G5325',
        name: 'Câmera Fixa - Bangu',
        location: const LatLng(-22.8823, -43.4656),
        type: CameraType.fixed,
      ),
    ];

    return CamerasResponse(
      cameras: mockCameras,
      totalCount: mockCameras.length,
      fetchedAt: DateTime.now(),
    );
  }
}

/// Estado das câmeras no mapa
class CamerasState {
  final CamerasResponse? cameras;
  final bool isLoading;
  final String? error;
  final DateTime? lastFetch;

  const CamerasState({
    this.cameras,
    this.isLoading = false,
    this.error,
    this.lastFetch,
  });

  CamerasState copyWith({
    CamerasResponse? cameras,
    bool? isLoading,
    String? error,
    DateTime? lastFetch,
  }) {
    return CamerasState(
      cameras: cameras ?? this.cameras,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastFetch: lastFetch ?? this.lastFetch,
    );
  }
}

/// Controller de câmeras
class CamerasController extends StateNotifier<CamerasState> {
  final CameraService _service;
  Timer? _refreshTimer;

  // Intervalo de atualização das câmeras (móveis podem mudar de posição)
  static const _refreshInterval = Duration(minutes: 5);

  CamerasController(this._service) : super(const CamerasState()) {
    _loadCameras();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      _loadCameras();
    });
  }

  Future<void> _loadCameras() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _service.getCameras();
      state = state.copyWith(
        cameras: response,
        isLoading: false,
        lastFetch: DateTime.now(),
      );

      if (kDebugMode) {
        print('Câmeras carregadas: ${response.totalCount} '
            '(${response.fixedCount} fixas, ${response.mobileCount} móveis)');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      if (kDebugMode) {
        print('Erro ao carregar câmeras: $e');
      }
    }
  }

  /// Força atualização das câmeras
  Future<void> refresh() async {
    await _loadCameras();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

// Providers
final cameraServiceProvider = Provider<CameraService>((ref) {
  final dio = Dio();
  return CameraService(dio);
});

final camerasControllerProvider =
    StateNotifierProvider<CamerasController, CamerasState>((ref) {
  final service = ref.watch(cameraServiceProvider);
  return CamerasController(service);
});

/// Provider para lista de câmeras
final camerasProvider = Provider<List<Camera>?>((ref) {
  return ref.watch(camerasControllerProvider).cameras?.cameras;
});

/// Provider para câmeras fixas
final fixedCamerasProvider = Provider<List<Camera>>((ref) {
  final cameras = ref.watch(camerasProvider);
  return cameras?.where((c) => c.isFixed).toList() ?? [];
});

/// Provider para câmeras móveis
final mobileCamerasProvider = Provider<List<Camera>>((ref) {
  final cameras = ref.watch(camerasProvider);
  return cameras?.where((c) => c.isMobile).toList() ?? [];
});
