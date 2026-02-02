import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../controllers/subscriptions_controller.dart';

/// Tela de configuração de bairros para alertas
class NeighborhoodSubscriptionsScreen extends ConsumerStatefulWidget {
  const NeighborhoodSubscriptionsScreen({super.key});

  @override
  ConsumerState<NeighborhoodSubscriptionsScreen> createState() =>
      _NeighborhoodSubscriptionsScreenState();
}

class _NeighborhoodSubscriptionsScreenState
    extends ConsumerState<NeighborhoodSubscriptionsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Carrega dados ao iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(subscriptionsControllerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final success = await ref.read(subscriptionsControllerProvider.notifier).save();
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.neighborhoodsSavedSuccess),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.neighborhoodsSavedError),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(subscriptionsControllerProvider);
    final controller = ref.read(subscriptionsControllerProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.neighborhoodAlertsTitle),
        actions: [
          // Contador de selecionados
          if (state.selectedCount > 0)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: AppSpacing.sm),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  l10n.selectedCountLabel(state.selectedCount),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null && state.allNeighborhoods.isEmpty
              ? ErrorState(
                  message: state.error!,
                  onRetry: controller.load,
                )
              : Column(
                  children: [
                    // Toggle sincronizar com favoritos
                    _buildSyncToggle(state, controller),

                    // Busca e ações
                    _buildSearchAndActions(state, controller),

                    // Lista de bairros
                    Expanded(
                      child: _buildNeighborhoodList(state, controller),
                    ),

                    // Botão salvar
                    _buildSaveButton(state),
                  ],
                ),
    );
  }

  Widget _buildSyncToggle(SubscriptionsState state, SubscriptionsController controller) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
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
              LucideIcons.heartHandshake,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.syncWithFavoritesTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.syncWithFavoritesSubtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Switch(
            value: state.syncWithFavorites,
            onChanged: (value) => controller.setSyncWithFavorites(value),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndActions(
      SubscriptionsState state, SubscriptionsController controller) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          // Busca
          TextField(
            controller: _searchController,
            onChanged: controller.setSearchQuery,
            decoration: InputDecoration(
              hintText: l10n.favoritesSearchHint,
              prefixIcon: const Icon(LucideIcons.search, size: 20),
              suffixIcon: state.searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        controller.setSearchQuery('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.divider),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Ações rápidas
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.selectAll,
                  icon: const Icon(LucideIcons.checkCheck, size: 16),
                  label: Text(l10n.selectAll),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: controller.clearAll,
                  icon: const Icon(LucideIcons.x, size: 16),
                  label: Text(l10n.clear),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  Widget _buildNeighborhoodList(
      SubscriptionsState state, SubscriptionsController controller) {
    final l10n = AppLocalizations.of(context)!;
    final neighborhoods = state.filteredNeighborhoods;

    if (neighborhoods.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              LucideIcons.searchX,
              size: 48,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.noNeighborhoodsFoundTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.tryAnotherSearch,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      itemCount: neighborhoods.length,
      itemBuilder: (context, index) {
        final neighborhood = neighborhoods[index];
        final isSelected = state.selectedNeighborhoods.contains(neighborhood.name);

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withOpacity(0.1)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.divider,
            ),
          ),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (_) => controller.toggleNeighborhood(neighborhood.name),
            title: Text(
              neighborhood.displayName,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.primary,
            dense: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSaveButton(SubscriptionsState state) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.divider),
          ),
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: state.isSaving ? null : _save,
            icon: state.isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(LucideIcons.save),
            label: Text(state.isSaving ? l10n.saving : l10n.save),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
          ),
        ),
      ),
    );
  }
}
