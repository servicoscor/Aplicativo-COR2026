import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Status de conectividade do app
enum ConnectivityStatus {
  /// Conectado e dados atualizados
  online,

  /// Conectado mas dados podem estar stale
  onlineStale,

  /// Sem conexão
  offline,

  /// Verificando conexão
  checking,
}

/// Estado de conectividade com informações adicionais
class ConnectivityState {
  final ConnectivityStatus status;
  final DateTime? lastUpdated;
  final int? dataAgeMinutes;
  final bool isRefreshing;

  const ConnectivityState({
    this.status = ConnectivityStatus.checking,
    this.lastUpdated,
    this.dataAgeMinutes,
    this.isRefreshing = false,
  });

  bool get isOnline =>
      status == ConnectivityStatus.online ||
      status == ConnectivityStatus.onlineStale;

  bool get isOffline => status == ConnectivityStatus.offline;

  bool get hasStaleData =>
      status == ConnectivityStatus.onlineStale ||
      (dataAgeMinutes != null && dataAgeMinutes! > 5);

  /// Formata a idade dos dados
  String get ageFormatted {
    if (dataAgeMinutes == null) return '';
    if (dataAgeMinutes! < 1) return 'agora';
    if (dataAgeMinutes == 1) return 'há 1 min';
    if (dataAgeMinutes! < 60) return 'há $dataAgeMinutes min';
    final hours = dataAgeMinutes! ~/ 60;
    if (hours == 1) return 'há 1 hora';
    return 'há $hours horas';
  }

  /// Mensagem de status
  String get statusMessage {
    switch (status) {
      case ConnectivityStatus.online:
        if (isRefreshing) return 'Atualizando...';
        if (dataAgeMinutes != null && dataAgeMinutes! > 0) {
          return 'Atualizado $ageFormatted';
        }
        return 'Online';
      case ConnectivityStatus.onlineStale:
        return 'Dados de $ageFormatted';
      case ConnectivityStatus.offline:
        if (dataAgeMinutes != null) {
          return 'Offline - dados de $ageFormatted';
        }
        return 'Sem conexão';
      case ConnectivityStatus.checking:
        return 'Verificando conexão...';
    }
  }

  ConnectivityState copyWith({
    ConnectivityStatus? status,
    DateTime? lastUpdated,
    int? dataAgeMinutes,
    bool? isRefreshing,
  }) {
    return ConnectivityState(
      status: status ?? this.status,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      dataAgeMinutes: dataAgeMinutes ?? this.dataAgeMinutes,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

/// Controller de conectividade
class ConnectivityController extends StateNotifier<ConnectivityState> {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityController(this._connectivity)
      : super(const ConnectivityState()) {
    _init();
  }

  void _init() {
    // Verifica conexão inicial
    _checkConnectivity();

    // Escuta mudanças de conexão (API nova: List<ConnectivityResult>)
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _handleConnectivityChange(results);
    });
  }

  Future<void> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _handleConnectivityChange(results);
    } catch (e) {
      if (kDebugMode) print('Erro ao verificar conectividade: $e');
      state = state.copyWith(status: ConnectivityStatus.offline);
    }
  }

  void _handleConnectivityChange(List<ConnectivityResult> results) {
    // Verifica se há alguma conexão (não apenas 'none')
    final hasConnection = results.isNotEmpty &&
        !results.every((r) => r == ConnectivityResult.none);

    if (hasConnection) {
      // Verifica se os dados estão stale
      if (state.dataAgeMinutes != null && state.dataAgeMinutes! > 5) {
        state = state.copyWith(status: ConnectivityStatus.onlineStale);
      } else {
        state = state.copyWith(status: ConnectivityStatus.online);
      }
    } else {
      state = state.copyWith(status: ConnectivityStatus.offline);
    }

    if (kDebugMode) {
      print('Conectividade: ${state.status} (resultados: $results)');
    }
  }

  /// Atualiza a idade dos dados (chamado pelo MapController)
  void updateDataAge(int? ageMinutes) {
    final newStatus = state.isOnline
        ? (ageMinutes != null && ageMinutes > 5
            ? ConnectivityStatus.onlineStale
            : ConnectivityStatus.online)
        : state.status;

    state = state.copyWith(
      dataAgeMinutes: ageMinutes,
      status: newStatus,
      lastUpdated: ageMinutes == 0 ? DateTime.now() : state.lastUpdated,
    );
  }

  /// Indica que está atualizando dados
  void setRefreshing(bool isRefreshing) {
    state = state.copyWith(isRefreshing: isRefreshing);
  }

  /// Marca dados como atualizados
  void markDataUpdated() {
    state = state.copyWith(
      lastUpdated: DateTime.now(),
      dataAgeMinutes: 0,
      status: state.isOnline ? ConnectivityStatus.online : state.status,
      isRefreshing: false,
    );
  }

  /// Força verificação de conectividade
  Future<void> checkConnectivity() async {
    await _checkConnectivity();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Provider do Connectivity
final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

/// Provider do ConnectivityController
final connectivityControllerProvider =
    StateNotifierProvider<ConnectivityController, ConnectivityState>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return ConnectivityController(connectivity);
});

/// Provider para status de conexão simplificado
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityControllerProvider).isOnline;
});

/// Provider para status de dados stale
final hasStaleDataProvider = Provider<bool>((ref) {
  return ref.watch(connectivityControllerProvider).hasStaleData;
});
