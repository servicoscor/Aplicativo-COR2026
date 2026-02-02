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

  // URL da API COCR (retorna texto "chapado", sem JSON)
  static const String _cocrCamerasUrl = 'https://aplicativo.cocr.com.br/cameras_api';

  // Se true, usa dados mock ao invés da API real
  static const bool _useMockData = false;

  // Chave padrão para stream (quando não vem da API)
  static const String _defaultCameraKey = 'G5325';

  CameraService(this._dio);

  /// Busca todas as câmeras disponíveis
  Future<CamerasResponse> getCameras() async {
    if (_useMockData) {
      return _getMockCameras();
    }

    try {
      // API COCR retorna texto bruto separado por ';'
      final response = await _dio.get<String>(
        _cocrCamerasUrl,
        options: Options(
          responseType: ResponseType.plain,
          headers: {'Accept': 'text/plain, */*'},
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final parsed = _parseCocrCameras(response.data!);
        if (parsed.cameras.isNotEmpty) {
          return parsed;
        }
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

  /// Converte o texto da API COCR em lista de câmeras
  CamerasResponse _parseCocrCameras(String raw) {
    final cameras = <Camera>[];
    final seen = <String>{};

    final regex = RegExp(
      r'(-2[1-4]\.\d+)\s*;\s*(-4[1-5]\.\d+)\s*;\s*([^;]+?)\s*;\s*([0-9.]+)',
    );

    for (final match in regex.allMatches(raw)) {
      final lat = double.tryParse(match.group(1) ?? '');
      final lng = double.tryParse(match.group(2) ?? '');
      if (lat == null || lng == null) continue;
      if (!_looksLikeLat(lat) || !_looksLikeLng(lng)) continue;

      final nameToken = (match.group(3) ?? '').trim();
      final codeRaw = (match.group(4) ?? '').trim();
      final codeString = _normalizeCodeString(codeRaw);
      if (codeString.isEmpty) continue;

      _tryAddCamera(cameras, seen, codeString, lat, lng, nameToken);
    }

    return CamerasResponse(
      cameras: cameras,
      totalCount: cameras.length,
      fetchedAt: DateTime.now(),
    );
  }

  static CameraType _typeFromNameOrDefault(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('móvel') || lower.contains('movel')) {
      return CameraType.mobile;
    }
    return CameraType.fixed;
  }

  static List<String> _extractNumberStrings(String input) {
    final matches = RegExp(r'[-+]?\d+(?:\.\d+)+|[-+]?\d+').allMatches(input);
    return matches
        .map((m) => _normalizeNumberString(m.group(0)!))
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static String _normalizeCodeString(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9]'), '');
    return cleaned;
  }

  static List<double> _extractNumbers(String input) {
    return _extractNumberStrings(input)
        .map((s) => double.tryParse(s))
        .whereType<double>()
        .toList();
  }

  static double? _parseFirstNumber(String input) {
    final numbers = _extractNumbers(input);
    if (numbers.isEmpty) return null;
    return numbers.first;
  }

  static bool _looksLikeLat(double value) => value >= -25 && value <= -21;
  static bool _looksLikeLng(double value) => value >= -45 && value <= -40;

  static String _normalizeNumberString(String input) {
    final s = input.trim();
    final dotCount = '.'.allMatches(s).length;
    if (dotCount <= 1) return s;

    final isNegative = s.startsWith('-');
    final digitsOnly = s.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.length < 3) return '';

    final head = digitsOnly.substring(0, 2);
    final tail = digitsOnly.substring(2);
    return '${isNegative ? '-' : ''}$head.$tail';
  }

  static void _tryAddCamera(
    List<Camera> cameras,
    Set<String> seen,
    String codeString,
    double lat,
    double lng,
    String nameToken,
  ) {
    final name = nameToken.isEmpty ? 'Câmera $codeString' : nameToken;
    final camera = Camera(
      code: codeString,
      key: _defaultCameraKey,
      name: name,
      location: LatLng(lat, lng),
      type: _typeFromNameOrDefault(name),
    );

    final dedupeKey = '$codeString|${lat.toStringAsFixed(6)}|${lng.toStringAsFixed(6)}';
    if (seen.add(dedupeKey)) {
      cameras.add(camera);
    }
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
        key: _defaultCameraKey,
        name: 'Câmera Fixa - Copacabana Posto 6',
        location: const LatLng(-22.9714, -43.1823),
        type: CameraType.fixed,
      ),
      Camera(
        code: '002',
        key: _defaultCameraKey,
        name: 'Câmera Fixa - Ipanema Posto 9',
        location: const LatLng(-22.9867, -43.2044),
        type: CameraType.fixed,
      ),
      Camera(
        code: '003',
        key: _defaultCameraKey,
        name: 'Câmera Fixa - Leblon',
        location: const LatLng(-22.9855, -43.2237),
        type: CameraType.fixed,
      ),
      Camera(
        code: '004',
        key: _defaultCameraKey,
        name: 'Câmera Fixa - Centro ALERJ',
        location: const LatLng(-22.9068, -43.1729),
        type: CameraType.fixed,
      ),
      Camera(
        code: '005',
        key: _defaultCameraKey,
        name: 'Câmera Fixa - Av. Brasil Penha',
        location: const LatLng(-22.8384, -43.2824),
        type: CameraType.fixed,
      ),
      Camera(
        code: '006',
        key: _defaultCameraKey,
        name: 'Câmera Fixa - Linha Vermelha Fundão',
        location: const LatLng(-22.8563, -43.2361),
        type: CameraType.fixed,
      ),
      Camera(
        code: '007',
        key: _defaultCameraKey,
        name: 'Câmera Fixa - Maracanã',
        location: const LatLng(-22.9121, -43.2302),
        type: CameraType.fixed,
      ),
      Camera(
        code: '008',
        key: _defaultCameraKey,
        name: 'Câmera Fixa - Barra Shopping',
        location: const LatLng(-23.0000, -43.3651),
        type: CameraType.fixed,
      ),
      Camera(
        code: '009',
        key: _defaultCameraKey,
        name: 'Câmera Fixa - Recreio dos Bandeirantes',
        location: const LatLng(-23.0224, -43.4680),
        type: CameraType.fixed,
      ),
      Camera(
        code: '010',
        key: _defaultCameraKey,
        name: 'Câmera Fixa - Aeroporto Santos Dumont',
        location: const LatLng(-22.9104, -43.1631),
        type: CameraType.fixed,
      ),
      Camera(
        code: '011',
        key: _defaultCameraKey,
        name: 'Câmera Fixa - Túnel Rebouças Entrada',
        location: const LatLng(-22.9556, -43.2089),
        type: CameraType.fixed,
      ),
      Camera(
        code: '012',
        key: _defaultCameraKey,
        name: 'Câmera Fixa - Túnel Santa Bárbara',
        location: const LatLng(-22.9233, -43.1883),
        type: CameraType.fixed,
      ),
      Camera(
        code: '013',
        key: _defaultCameraKey,
        name: 'Câmera Fixa - Ponte Rio-Niterói Pedágio',
        location: const LatLng(-22.8730, -43.1370),
        type: CameraType.fixed,
      ),
      Camera(
        code: '014',
        key: _defaultCameraKey,
        name: 'Câmera Fixa - Av. Presidente Vargas',
        location: const LatLng(-22.9039, -43.1778),
        type: CameraType.fixed,
      ),
      Camera(
        code: '015',
        key: _defaultCameraKey,
        name: 'Câmera Fixa - Rodoviária Novo Rio',
        location: const LatLng(-22.8986, -43.2094),
        type: CameraType.fixed,
      ),

      // Câmeras móveis
      Camera(
        code: '101',
        key: _defaultCameraKey,
        name: 'Câmera Móvel - Viatura COR 01',
        location: const LatLng(-22.9149, -43.1806),
        type: CameraType.mobile,
      ),
      Camera(
        code: '102',
        key: _defaultCameraKey,
        name: 'Câmera Móvel - Viatura COR 02',
        location: const LatLng(-22.9534, -43.1736),
        type: CameraType.mobile,
      ),
      Camera(
        code: '103',
        key: _defaultCameraKey,
        name: 'Câmera Móvel - Viatura COR 03',
        location: const LatLng(-22.8756, -43.3339),
        type: CameraType.mobile,
      ),
      Camera(
        code: '104',
        key: _defaultCameraKey,
        name: 'Câmera Móvel - Viatura COR 04',
        location: const LatLng(-22.9823, -43.2145),
        type: CameraType.mobile,
      ),
      Camera(
        code: '105',
        key: _defaultCameraKey,
        name: 'Câmera Móvel - Viatura COR 05',
        location: const LatLng(-22.9301, -43.2456),
        type: CameraType.mobile,
      ),
      Camera(
        code: '106',
        key: _defaultCameraKey,
        name: 'Câmera Móvel - Drone COR 01',
        location: const LatLng(-22.9456, -43.1923),
        type: CameraType.mobile,
      ),
      Camera(
        code: '107',
        key: _defaultCameraKey,
        name: 'Câmera Móvel - Drone COR 02',
        location: const LatLng(-22.8912, -43.2789),
        type: CameraType.mobile,
      ),
      Camera(
        code: '108',
        key: _defaultCameraKey,
        name: 'Câmera Móvel - Moto COR 01',
        location: const LatLng(-22.9667, -43.1856),
        type: CameraType.mobile,
      ),

      // Mais câmeras fixas em vias importantes
      Camera(
        code: '016',
        key: _defaultCameraKey,
        name: 'Câmera Fixa - Autoestrada Lagoa-Barra',
        location: const LatLng(-22.9912, -43.2567),
        type: CameraType.fixed,
      ),
      Camera(
        code: '017',
        key: _defaultCameraKey,
        name: 'Câmera Fixa - Av. Niemeyer',
        location: const LatLng(-22.9978, -43.2456),
        type: CameraType.fixed,
      ),
      Camera(
        code: '018',
        key: _defaultCameraKey,
        name: 'Câmera Fixa - Linha Amarela Anil',
        location: const LatLng(-22.9245, -43.3456),
        type: CameraType.fixed,
      ),
      Camera(
        code: '019',
        key: _defaultCameraKey,
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
