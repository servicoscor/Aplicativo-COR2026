import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/alert_model.dart';
import '../../data/alerts_repository.dart';
import '../../../map/presentation/controllers/map_controller.dart';

/// Estado da tela de alertas
class AlertsState {
  final List<Alert> alerts;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final Alert? selectedAlert;
  final int unreadCount;

  // Filtros
  final String? selectedSeverity;
  final String? selectedNeighborhood;
  final bool showUnreadOnly;

  const AlertsState({
    this.alerts = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.selectedAlert,
    this.unreadCount = 0,
    this.selectedSeverity,
    this.selectedNeighborhood,
    this.showUnreadOnly = false,
  });

  AlertsState copyWith({
    List<Alert>? alerts,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    Alert? selectedAlert,
    bool clearSelectedAlert = false,
    int? unreadCount,
    String? selectedSeverity,
    bool clearSelectedSeverity = false,
    String? selectedNeighborhood,
    bool clearSelectedNeighborhood = false,
    bool? showUnreadOnly,
  }) {
    return AlertsState(
      alerts: alerts ?? this.alerts,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error,
      selectedAlert: clearSelectedAlert ? null : (selectedAlert ?? this.selectedAlert),
      unreadCount: unreadCount ?? this.unreadCount,
      selectedSeverity: clearSelectedSeverity ? null : (selectedSeverity ?? this.selectedSeverity),
      selectedNeighborhood: clearSelectedNeighborhood ? null : (selectedNeighborhood ?? this.selectedNeighborhood),
      showUnreadOnly: showUnreadOnly ?? this.showUnreadOnly,
    );
  }

  /// Alertas não expirados
  List<Alert> get activeAlerts => alerts.where((a) => !a.isExpired).toList();

  /// Alertas filtrados localmente
  List<Alert> get filteredAlerts {
    return alerts.where((a) {
      if (showUnreadOnly && a.isRead) return false;
      if (selectedSeverity != null && a.severity != selectedSeverity) return false;
      if (selectedNeighborhood != null) {
        if (a.neighborhoods == null || !a.neighborhoods!.contains(selectedNeighborhood)) {
          return false;
        }
      }
      return !a.isExpired;
    }).toList();
  }

  /// Contagem de alertas por severidade
  int get emergencyCount => alerts.where((a) => a.severity == 'emergency').length;
  int get alertCount => alerts.where((a) => a.severity == 'alert').length;
  int get infoCount => alerts.where((a) => a.severity == 'info').length;
}

/// Controller de alertas
class AlertsController extends StateNotifier<AlertsState> {
  final AlertsRepository _repository;
  final Ref _ref;

  AlertsController(this._repository, this._ref) : super(const AlertsState());

  /// Carrega alertas da inbox
  Future<void> loadAlerts({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(isRefreshing: true, error: null);
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      // Tenta obter localização atual
      final userLocation = _ref.read(userLocationProvider);

      final response = await _repository.getInbox(
        latitude: userLocation?.latitude,
        longitude: userLocation?.longitude,
      );

      state = state.copyWith(
        alerts: response.alerts,
        unreadCount: response.unreadCount,
        isLoading: false,
        isRefreshing: false,
      );
    } catch (e) {
      if (kDebugMode) print('Erro ao carregar alertas: $e');
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: e is AppException ? e.message : 'Erro ao carregar alertas',
      );
    }
  }

  /// Marca um alerta como lido
  Future<void> markAsRead(String alertId) async {
    // Optimistic update - marca como lido imediatamente na UI
    final updatedAlerts = state.alerts.map((alert) {
      if (alert.id == alertId && !alert.isRead) {
        return alert.copyWith(isRead: true, readAt: DateTime.now());
      }
      return alert;
    }).toList();

    final newUnreadCount = updatedAlerts.where((a) => !a.isRead).length;

    state = state.copyWith(
      alerts: updatedAlerts,
      unreadCount: newUnreadCount,
    );

    // Envia requisição para API em background
    final success = await _repository.markAsRead(alertId);

    if (!success && kDebugMode) {
      print('Falha ao marcar alerta $alertId como lido na API');
    }
  }

  /// Define filtro de severidade
  void setSeverityFilter(String? severity) {
    if (severity == state.selectedSeverity) {
      // Se mesmo filtro, limpa
      state = state.copyWith(clearSelectedSeverity: true);
    } else {
      state = state.copyWith(selectedSeverity: severity);
    }
  }

  /// Define filtro de bairro
  void setNeighborhoodFilter(String? neighborhood) {
    if (neighborhood == state.selectedNeighborhood) {
      state = state.copyWith(clearSelectedNeighborhood: true);
    } else {
      state = state.copyWith(selectedNeighborhood: neighborhood);
    }
  }

  /// Define filtro de não lidos
  void setShowUnreadOnly(bool value) {
    state = state.copyWith(showUnreadOnly: value);
  }

  /// Limpa todos os filtros
  void clearFilters() {
    state = state.copyWith(
      clearSelectedSeverity: true,
      clearSelectedNeighborhood: true,
      showUnreadOnly: false,
    );
  }

  /// Seleciona um alerta para visualização detalhada
  void selectAlert(Alert alert) {
    state = state.copyWith(selectedAlert: alert);
  }

  /// Limpa alerta selecionado
  void clearSelectedAlert() {
    state = state.copyWith(clearSelectedAlert: true);
  }

  /// Limpa erro
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider do controller de alertas
final alertsControllerProvider = StateNotifierProvider<AlertsController, AlertsState>((ref) {
  final repository = ref.watch(alertsRepositoryProvider);
  return AlertsController(repository, ref);
});

/// Provider para o alerta selecionado (para navegação)
final selectedAlertProvider = Provider<Alert?>((ref) {
  return ref.watch(alertsControllerProvider).selectedAlert;
});

/// Provider para notificações não lidas (badge)
final unreadAlertsCountProvider = Provider<int>((ref) {
  final state = ref.watch(alertsControllerProvider);
  return state.unreadCount;
});
