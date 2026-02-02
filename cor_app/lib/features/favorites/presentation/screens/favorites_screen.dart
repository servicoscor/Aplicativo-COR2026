import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../controllers/favorites_controller.dart';

/// Tela de bairros favoritos
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(favoritesControllerProvider);
    final controller = ref.read(favoritesControllerProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.favoritesTitle),
      ),
      body: Column(
        children: [
          // Campo de busca
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Instrução
                Text(
                  l10n.favoritesInstruction,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Campo de busca
                TextField(
                  controller: _searchController,
                  focusNode: _focusNode,
                  onChanged: controller.updateSearchQuery,
                  decoration: InputDecoration(
                    hintText: l10n.favoritesSearchHint,
                    prefixIcon: const Icon(LucideIcons.search, size: 20),
                    suffixIcon: state.searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              controller.clearSearch();
                            },
                          )
                        : null,
                  ),
                ),

                // Sugestões de busca
                if (state.filteredSuggestions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      children: state.filteredSuggestions.map((neighborhood) {
                        return _SuggestionTile(
                          neighborhood: neighborhood,
                          onTap: () {
                            controller.addFavorite(neighborhood);
                            _searchController.clear();
                            _focusNode.unfocus();
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1),

          // Lista de favoritos
          Expanded(
            child: state.favorites.isEmpty
                ? _buildEmptyState(l10n)
                : _buildFavoritesList(state.favorites, controller),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return EmptyState(
      icon: LucideIcons.mapPin,
      title: l10n.favoritesEmptyTitle,
      subtitle: l10n.favoritesEmptySubtitle,
    );
  }

  Widget _buildFavoritesList(List<String> favorites, FavoritesController controller) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: favorites.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final neighborhood = favorites[index];
        return _FavoriteTile(
          neighborhood: neighborhood,
          onRemove: () => _confirmRemove(controller, neighborhood),
        );
      },
    );
  }

  void _confirmRemove(FavoritesController controller, String neighborhood) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.favoritesRemoveTitle),
        content: Text(
          AppLocalizations.of(context)!.favoritesRemoveBody(neighborhood),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              controller.removeFavorite(neighborhood);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(AppLocalizations.of(context)!.remove),
          ),
        ],
      ),
    );
  }
}

/// Tile de sugestão de bairro
class _SuggestionTile extends StatelessWidget {
  final String neighborhood;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.neighborhood,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            const Icon(
              LucideIcons.mapPin,
              size: 18,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                neighborhood,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const Icon(
              LucideIcons.plus,
              size: 18,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tile de bairro favorito
class _FavoriteTile extends StatelessWidget {
  final String neighborhood;
  final VoidCallback onRemove;

  const _FavoriteTile({
    required this.neighborhood,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              LucideIcons.mapPin,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              neighborhood,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2, size: 18),
            color: AppColors.error,
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
