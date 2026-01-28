import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/operational_status_model.dart';
import '../network/api_client.dart';

/// Serviço para obter o status operacional da cidade
class StatusService {
  final ApiClient _apiClient;

  // Intervalo de atualização automática (5 minutos)
  static const _updateInterval = Duration(minutes: 5);

  Timer? _updateTimer;

  StatusService(this._apiClient);

  /// Obtém o status operacional atual da API
  Future<OperationalStatus> getStatus() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/v1/status/operational',
      );

      if (response['success'] == true && response['data'] != null) {
        return OperationalStatus.fromJson(response['data']);
      }

      // Se a resposta não tiver o formato esperado, retorna status padrão
      if (kDebugMode) {
        print('[StatusService] Resposta inesperada: $response');
      }
      return OperationalStatus.defaultStatus;
    } catch (e) {
      if (kDebugMode) {
        print('[StatusService] Erro ao buscar status: $e');
      }
      // Em caso de erro, propaga para que o controller trate
      rethrow;
    }
  }

  /// Para timer de atualização
  void dispose() {
    _updateTimer?.cancel();
  }
}

/// Estado do status operacional
class StatusState {
  final OperationalStatus? status;
  final bool isLoading;
  final String? error;

  const StatusState({
    this.status,
    this.isLoading = false,
    this.error,
  });

  StatusState copyWith({
    OperationalStatus? status,
    bool? isLoading,
    String? error,
  }) {
    return StatusState(
      status: status ?? this.status,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Estado inicial
  static const initial = StatusState(isLoading: true);
}

/// Controller do status operacional
class StatusController extends StateNotifier<StatusState> {
  final StatusService _service;
  Timer? _refreshTimer;

  StatusController(this._service) : super(StatusState.initial) {
    _init();
  }

  void _init() {
    // Carrega status inicial
    loadStatus();

    // Configura refresh automático a cada 5 minutos
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => loadStatus(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _service.dispose();
    super.dispose();
  }

  /// Carrega o status operacional
  Future<void> loadStatus() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final status = await _service.getStatus();
      state = state.copyWith(status: status, isLoading: false);

      if (kDebugMode) {
        print('[StatusService] Status carregado: '
            'Estágio ${status.cityStage.number}, '
            'NC${status.heatLevel.number}');
      }
    } catch (e) {
      // Em caso de erro, mantém o status anterior se existir
      // ou usa o status padrão
      final fallbackStatus = state.status ?? OperationalStatus.defaultStatus;
      state = state.copyWith(
        status: fallbackStatus,
        isLoading: false,
        error: 'Erro ao carregar status: $e',
      );

      if (kDebugMode) {
        print('[StatusService] Erro: $e');
      }
    }
  }

  /// Força atualização
  Future<void> refresh() async {
    await loadStatus();
  }
}

/// Provider do serviço
final statusServiceProvider = Provider<StatusService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return StatusService(apiClient);
});

/// Provider do controller
final statusControllerProvider =
    StateNotifierProvider<StatusController, StatusState>((ref) {
  final service = ref.watch(statusServiceProvider);
  return StatusController(service);
});

/// Provider conveniente para o status atual
final operationalStatusProvider = Provider<OperationalStatus?>((ref) {
  return ref.watch(statusControllerProvider).status;
});

/// Provider para verificar se está carregando
final statusLoadingProvider = Provider<bool>((ref) {
  return ref.watch(statusControllerProvider).isLoading;
});
