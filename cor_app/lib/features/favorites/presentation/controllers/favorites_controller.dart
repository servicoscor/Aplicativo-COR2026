import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/favorites_repository.dart';
import '../../../settings/data/subscriptions_repository.dart';

/// Estado da tela de favoritos
class FavoritesState {
  final List<String> favorites;
  final String searchQuery;
  final bool isSaving;

  const FavoritesState({
    this.favorites = const [],
    this.searchQuery = '',
    this.isSaving = false,
  });

  FavoritesState copyWith({
    List<String>? favorites,
    String? searchQuery,
    bool? isSaving,
  }) {
    return FavoritesState(
      favorites: favorites ?? this.favorites,
      searchQuery: searchQuery ?? this.searchQuery,
      isSaving: isSaving ?? this.isSaving,
    );
  }

  /// Bairros filtrados pela busca
  List<String> get filteredSuggestions {
    if (searchQuery.isEmpty) return [];

    final query = searchQuery.toLowerCase();
    return rioNeighborhoods
        .where((n) =>
            n.toLowerCase().contains(query) &&
            !favorites.contains(n))
        .take(10)
        .toList();
  }
}

/// Controller de favoritos
class FavoritesController extends StateNotifier<FavoritesState> {
  final FavoritesRepository _repository;
  final SubscriptionsRepository _subscriptionsRepository;
  final void Function(List<String> neighborhoods)? _onFavoritesChanged;

  FavoritesController(
    this._repository,
    this._subscriptionsRepository, {
    void Function(List<String> neighborhoods)? onFavoritesChanged,
  })  : _onFavoritesChanged = onFavoritesChanged,
        super(const FavoritesState()) {
    _loadFavorites();
  }

  void _loadFavorites() {
    state = state.copyWith(favorites: _repository.favorites);
  }

  /// Sincroniza favoritos com subscriptions se habilitado
  Future<void> _syncSubscriptions(List<String> favorites) async {
    if (_subscriptionsRepository.syncWithFavorites) {
      try {
        await _subscriptionsRepository.updateSubscriptions(favorites);
        if (kDebugMode) print('Subscriptions sincronizadas com favoritos');
      } catch (e) {
        if (kDebugMode) print('Erro ao sincronizar subscriptions: $e');
      }
    }
  }

  /// Atualiza query de busca
  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Adiciona um bairro aos favoritos
  Future<void> addFavorite(String neighborhood) async {
    if (state.favorites.contains(neighborhood)) return;

    state = state.copyWith(isSaving: true);

    try {
      await _repository.addFavorite(neighborhood);
      final newFavorites = [...state.favorites, neighborhood];
      state = state.copyWith(
        favorites: newFavorites,
        searchQuery: '',
        isSaving: false,
      );
      _onFavoritesChanged?.call(newFavorites);

      // Sincroniza com subscriptions
      _syncSubscriptions(newFavorites);
    } catch (e) {
      if (kDebugMode) print('Erro ao adicionar favorito: $e');
      state = state.copyWith(isSaving: false);
    }
  }

  /// Remove um bairro dos favoritos
  Future<void> removeFavorite(String neighborhood) async {
    state = state.copyWith(isSaving: true);

    try {
      await _repository.removeFavorite(neighborhood);
      final newFavorites = state.favorites.where((n) => n != neighborhood).toList();
      state = state.copyWith(
        favorites: newFavorites,
        isSaving: false,
      );
      _onFavoritesChanged?.call(newFavorites);

      // Sincroniza com subscriptions
      _syncSubscriptions(newFavorites);
    } catch (e) {
      if (kDebugMode) print('Erro ao remover favorito: $e');
      state = state.copyWith(isSaving: false);
    }
  }

  /// Limpa busca
  void clearSearch() {
    state = state.copyWith(searchQuery: '');
  }
}

/// Callback para quando favoritos mudam (para re-registrar device)
final onFavoritesChangedProvider = Provider<void Function(List<String>)?>(
  (ref) => null,
);

/// Provider do controller de favoritos
final favoritesControllerProvider = StateNotifierProvider<FavoritesController, FavoritesState>((ref) {
  final repository = ref.watch(favoritesRepositoryProvider);
  final subscriptionsRepository = ref.watch(subscriptionsRepositoryProvider);
  final onChanged = ref.watch(onFavoritesChangedProvider);
  return FavoritesController(
    repository,
    subscriptionsRepository,
    onFavoritesChanged: onChanged,
  );
});

/// Provider para a lista de favoritos (para uso em outros lugares)
final favoritesListProvider = Provider<List<String>>((ref) {
  return ref.watch(favoritesControllerProvider).favorites;
});
