import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/subscriptions_repository.dart';

/// Estado da tela de subscriptions
class SubscriptionsState {
  final List<Neighborhood> allNeighborhoods;
  final Set<String> selectedNeighborhoods;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String searchQuery;
  final bool syncWithFavorites;

  const SubscriptionsState({
    this.allNeighborhoods = const [],
    this.selectedNeighborhoods = const {},
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.searchQuery = '',
    this.syncWithFavorites = true,
  });

  SubscriptionsState copyWith({
    List<Neighborhood>? allNeighborhoods,
    Set<String>? selectedNeighborhoods,
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
    String? searchQuery,
    bool? syncWithFavorites,
  }) {
    return SubscriptionsState(
      allNeighborhoods: allNeighborhoods ?? this.allNeighborhoods,
      selectedNeighborhoods: selectedNeighborhoods ?? this.selectedNeighborhoods,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      searchQuery: searchQuery ?? this.searchQuery,
      syncWithFavorites: syncWithFavorites ?? this.syncWithFavorites,
    );
  }

  /// Bairros filtrados pela busca
  List<Neighborhood> get filteredNeighborhoods {
    if (searchQuery.isEmpty) {
      return allNeighborhoods;
    }
    final query = searchQuery.toLowerCase();
    return allNeighborhoods
        .where((n) => n.displayName.toLowerCase().contains(query))
        .toList();
  }

  /// Número de bairros selecionados
  int get selectedCount => selectedNeighborhoods.length;
}

/// Controller de subscriptions
class SubscriptionsController extends StateNotifier<SubscriptionsState> {
  final SubscriptionsRepository _repository;

  SubscriptionsController(this._repository) : super(const SubscriptionsState());

  /// Carrega dados iniciais
  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Carrega bairros disponíveis e selecionados em paralelo
      final results = await Future.wait([
        _repository.getNeighborhoods(),
        _repository.getSubscriptions(),
      ]);

      final neighborhoods = results[0] as List<Neighborhood>;
      final selected = results[1] as List<String>;
      final syncWithFavorites = _repository.syncWithFavorites;

      state = state.copyWith(
        allNeighborhoods: neighborhoods,
        selectedNeighborhoods: selected.toSet(),
        syncWithFavorites: syncWithFavorites,
        isLoading: false,
      );
    } catch (e) {
      if (kDebugMode) print('Erro ao carregar subscriptions: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar bairros',
      );
    }
  }

  /// Alterna seleção de um bairro
  void toggleNeighborhood(String name) {
    final selected = Set<String>.from(state.selectedNeighborhoods);
    if (selected.contains(name)) {
      selected.remove(name);
    } else {
      selected.add(name);
    }
    state = state.copyWith(selectedNeighborhoods: selected);
  }

  /// Seleciona todos os bairros
  void selectAll() {
    final allNames = state.allNeighborhoods.map((n) => n.name).toSet();
    state = state.copyWith(selectedNeighborhoods: allNames);
  }

  /// Limpa todas as seleções
  void clearAll() {
    state = state.copyWith(selectedNeighborhoods: {});
  }

  /// Atualiza query de busca
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Define sincronização com favoritos
  Future<void> setSyncWithFavorites(bool value) async {
    await _repository.setSyncWithFavorites(value);
    state = state.copyWith(syncWithFavorites: value);
  }

  /// Salva as seleções na API
  Future<bool> save() async {
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final success = await _repository.updateSubscriptions(
        state.selectedNeighborhoods.toList(),
      );

      state = state.copyWith(isSaving: false);

      if (!success) {
        state = state.copyWith(error: 'Erro ao salvar bairros');
      }

      return success;
    } catch (e) {
      if (kDebugMode) print('Erro ao salvar subscriptions: $e');
      state = state.copyWith(
        isSaving: false,
        error: 'Erro ao salvar bairros',
      );
      return false;
    }
  }
}

/// Provider do controller
final subscriptionsControllerProvider =
    StateNotifierProvider<SubscriptionsController, SubscriptionsState>((ref) {
  final repository = ref.watch(subscriptionsRepositoryProvider);
  return SubscriptionsController(repository);
});
