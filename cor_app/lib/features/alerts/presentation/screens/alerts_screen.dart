import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../../core/models/alert_model.dart';
import '../controllers/alerts_controller.dart';
import '../widgets/alert_card.dart';
import 'alert_detail_screen.dart';

/// Tela de alertas (inbox)
class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  @override
  void initState() {
    super.initState();
    // Carrega alertas ao iniciar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(alertsControllerProvider.notifier).loadAlerts();
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(alertsControllerProvider.notifier).loadAlerts(refresh: true);
  }

  void _openAlertDetail(Alert alert) {
    ref.read(alertsControllerProvider.notifier).selectAlert(alert);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AlertDetailScreen(alert: alert),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(alertsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cidade'),
        actions: [
          // Contador de não lidos
          if (state.unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.emergency.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.mailOpen, size: 14, color: AppColors.emergency),
                    const SizedBox(width: 4),
                    Text(
                      '${state.unreadCount} não lido${state.unreadCount > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.emergency,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          _buildFilters(state),
          // Lista
          Expanded(child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildFilters(AlertsState state) {
    final controller = ref.read(alertsControllerProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Filtro: Não lidos
            FilterChip(
              label: const Text('Não lidos'),
              selected: state.showUnreadOnly,
              onSelected: (selected) => controller.setShowUnreadOnly(selected),
              avatar: state.showUnreadOnly
                  ? const Icon(LucideIcons.check, size: 16)
                  : const Icon(LucideIcons.mail, size: 16),
              selectedColor: AppColors.primary.withOpacity(0.2),
              checkmarkColor: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),

            // Filtro: Emergência
            FilterChip(
              label: const Text('Emergência'),
              selected: state.selectedSeverity == 'emergency',
              onSelected: (_) => controller.setSeverityFilter('emergency'),
              avatar: const Icon(LucideIcons.alertTriangle, size: 16, color: AppColors.emergency),
              selectedColor: AppColors.emergency.withOpacity(0.2),
              checkmarkColor: AppColors.emergency,
            ),
            const SizedBox(width: AppSpacing.sm),

            // Filtro: Alerta
            FilterChip(
              label: const Text('Alerta'),
              selected: state.selectedSeverity == 'alert',
              onSelected: (_) => controller.setSeverityFilter('alert'),
              avatar: const Icon(LucideIcons.alertCircle, size: 16, color: AppColors.alert),
              selectedColor: AppColors.alert.withOpacity(0.2),
              checkmarkColor: AppColors.alert,
            ),
            const SizedBox(width: AppSpacing.sm),

            // Filtro: Info
            FilterChip(
              label: const Text('Info'),
              selected: state.selectedSeverity == 'info',
              onSelected: (_) => controller.setSeverityFilter('info'),
              avatar: const Icon(LucideIcons.info, size: 16, color: AppColors.info),
              selectedColor: AppColors.info.withOpacity(0.2),
              checkmarkColor: AppColors.info,
            ),

            // Botão limpar filtros (se algum filtro ativo)
            if (state.selectedSeverity != null ||
                state.selectedNeighborhood != null ||
                state.showUnreadOnly) ...[
              const SizedBox(width: AppSpacing.md),
              ActionChip(
                label: const Text('Limpar'),
                avatar: const Icon(LucideIcons.x, size: 16),
                onPressed: controller.clearFilters,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AlertsState state) {
    // Loading inicial
    if (state.isLoading && state.alerts.isEmpty) {
      return const ShimmerList(
        itemCount: 5,
        itemHeight: 120,
      );
    }

    // Erro
    if (state.error != null && state.alerts.isEmpty) {
      return ErrorState(
        message: state.error!,
        onRetry: () => ref.read(alertsControllerProvider.notifier).loadAlerts(),
      );
    }

    // Lista vazia (nenhum alerta)
    if (state.alerts.isEmpty) {
      return EmptyState(
        icon: LucideIcons.bellOff,
        title: 'Nenhum alerta',
        subtitle: 'Você não possui alertas no momento.\nQuando houver novidades, você será notificado.',
        action: ElevatedButton.icon(
          onPressed: _onRefresh,
          icon: const Icon(LucideIcons.refreshCw),
          label: const Text('Atualizar'),
        ),
      );
    }

    final filteredAlerts = state.filteredAlerts;

    // Lista vazia após filtro
    if (filteredAlerts.isEmpty) {
      return EmptyState(
        icon: LucideIcons.filter,
        title: 'Nenhum resultado',
        subtitle: 'Nenhum alerta corresponde aos filtros selecionados.',
        action: ElevatedButton.icon(
          onPressed: () => ref.read(alertsControllerProvider.notifier).clearFilters(),
          icon: const Icon(LucideIcons.x),
          label: const Text('Limpar Filtros'),
        ),
      );
    }

    // Lista de alertas
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: filteredAlerts.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final alert = filteredAlerts[index];
          return AlertCard(
            alert: alert,
            onTap: () => _openAlertDetail(alert),
          );
        },
      ),
    );
  }
}
