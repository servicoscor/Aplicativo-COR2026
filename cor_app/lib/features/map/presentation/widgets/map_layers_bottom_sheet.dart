import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/incident_model.dart';
import '../../../../core/services/camera_service.dart';
import '../../../../core/widgets/data_age_badge.dart';
import '../controllers/map_controller.dart';
import 'camera_marker.dart';

/// Bottom sheet para camadas e filtros do mapa
class MapLayersBottomSheet extends ConsumerWidget {
  const MapLayersBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mapControllerProvider);
    final controller = ref.read(mapControllerProvider.notifier);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Titulo
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const Icon(LucideIcons.layers, color: AppColors.primary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                const Text(
                  'Camadas e Filtros',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (state.incidentFilters.hasActiveFilters)
                  TextButton(
                    onPressed: controller.clearIncidentFilters,
                    child: Text(AppLocalizations.of(context)!.clearFilters),
                  ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.divider),

          // Conteudo scrollavel
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Seção de Aparência do Mapa
                  _buildSectionHeader('Aparência'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildMapThemeSelector(state, controller),
                  const SizedBox(height: AppSpacing.lg),

                  // Secao de Camadas
                  _buildSectionHeader('Camadas do Mapa'),
                  const SizedBox(height: AppSpacing.sm),
                  _buildLayerToggle(
                    icon: LucideIcons.radio,
                    label: 'Radar Meteorologico',
                    subtitle: 'Imagem de precipitacao',
                    isEnabled: state.layers.radarEnabled,
                    onChanged: (_) => controller.toggleRadar(),
                    color: AppColors.info,
                    isStale: state.radar?.isStale ?? false,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildLayerToggle(
                    icon: LucideIcons.droplet,
                    label: 'Pluviometros',
                    subtitle: '${state.rainGauges?.stations.length ?? 0} estacoes',
                    isEnabled: state.layers.rainGaugesEnabled,
                    onChanged: (_) => controller.toggleRainGauges(),
                    color: AppColors.success,
                    isStale: state.rainGauges?.isStale ?? false,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildLayerToggle(
                    icon: LucideIcons.thermometer,
                    label: 'Heatmap Chuva',
                    subtitle: 'Intensidade por area',
                    isEnabled: state.layers.rainHeatmapEnabled,
                    onChanged: (_) => controller.toggleRainHeatmap(),
                    color: const Color(0xFFFF9800),
                    isStale: state.rainGauges?.isStale ?? false,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildLayerToggle(
                    icon: LucideIcons.bell,
                    label: 'Sirenes',
                    subtitle: '${state.sirens?.sirens.length ?? 0} sirenes',
                    isEnabled: state.layers.sirensEnabled,
                    onChanged: (_) => controller.toggleSirens(),
                    color: AppColors.alert,
                    isStale: state.sirens?.isStale ?? false,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _buildLayerToggle(
                    icon: LucideIcons.alertTriangle,
                    label: 'Incidentes',
                    subtitle: '${state.filteredIncidents.length} ativos',
                    isEnabled: state.layers.incidentsEnabled,
                    onChanged: (_) => controller.toggleIncidents(),
                    color: AppColors.alert,
                    isStale: state.incidents?.isStale ?? false,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Consumer(
                    builder: (context, ref, _) {
                      final camerasState = ref.watch(camerasControllerProvider);
                      final cameraCount = camerasState.cameras?.totalCount ?? 0;
                      final fixedCount = camerasState.cameras?.fixedCount ?? 0;
                      final mobileCount = camerasState.cameras?.mobileCount ?? 0;
                      return _buildCameraLayerToggle(
                        label: 'Cameras COR',
                        subtitle: cameraCount > 0
                            ? '$cameraCount cameras ($fixedCount fixas, $mobileCount moveis)'
                            : 'Carregando...',
                        isEnabled: state.layers.camerasEnabled,
                        onChanged: (_) => controller.toggleCameras(),
                      );
                    },
                  ),

                  const SizedBox(height: AppSpacing.lg),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: AppSpacing.md),

                  // Filtros de Incidentes (so mostra se a camada estiver ativa)
                  if (state.layers.incidentsEnabled) ...[
                    _buildSectionHeader('Filtrar por Tipo'),
                    const SizedBox(height: AppSpacing.sm),
                    _buildIncidentTypeFilters(state, controller),

                    const SizedBox(height: AppSpacing.lg),

                    _buildSectionHeader('Filtrar por Severidade'),
                    const SizedBox(height: AppSpacing.sm),
                    _buildSeverityFilters(state, controller),
                  ],

                  // Padding inferior para safe area
                  SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpacing.md),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapThemeSelector(MapState state, MapController controller) {
    final isDark = state.layers.mapTheme == MapTheme.dark;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          // Opção Dark
          Expanded(
            child: GestureDetector(
              onTap: () => controller.setMapTheme(MapTheme.dark),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.primary.withOpacity(0.15) : null,
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(AppRadius.md - 1)),
                  border: isDark ? Border.all(color: AppColors.primary.withOpacity(0.3)) : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.moon,
                      size: 18,
                      color: isDark ? AppColors.primary : AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Escuro',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isDark ? FontWeight.w600 : FontWeight.w400,
                        color: isDark ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Opção Light
          Expanded(
            child: GestureDetector(
              onTap: () => controller.setMapTheme(MapTheme.light),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !isDark ? AppColors.primary.withOpacity(0.15) : null,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(AppRadius.md - 1)),
                  border: !isDark ? Border.all(color: AppColors.primary.withOpacity(0.3)) : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.sun,
                      size: 18,
                      color: !isDark ? AppColors.primary : AppColors.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Claro',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: !isDark ? FontWeight.w600 : FontWeight.w400,
                        color: !isDark ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildLayerToggle({
    required IconData icon,
    required String label,
    required String subtitle,
    required bool isEnabled,
    required ValueChanged<bool> onChanged,
    required Color color,
    int? ageMinutes,
    bool isStale = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isEnabled ? color.withOpacity(0.1) : AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isEnabled ? color.withOpacity(0.3) : AppColors.divider,
        ),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: isEnabled ? color : AppColors.textMuted),
        title: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isEnabled ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
            if (isEnabled && (ageMinutes != null || isStale))
              DataAgeBadge.fromAge(
                ageMinutes: ageMinutes,
                isStale: isStale,
                isOutdated: (ageMinutes ?? 0) > 10,
                compact: true,
                showIcon: false,
              ),
          ],
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isEnabled ? AppColors.textSecondary : AppColors.textMuted,
          ),
        ),
        value: isEnabled,
        onChanged: onChanged,
        activeColor: color,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
    );
  }

  Widget _buildCameraLayerToggle({
    required String label,
    required String subtitle,
    required bool isEnabled,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isEnabled
            ? LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  CameraColors.fixed.withOpacity(0.1),
                  CameraColors.mobile.withOpacity(0.1),
                ],
              )
            : null,
        color: isEnabled ? null : AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isEnabled
              ? CameraColors.fixed.withOpacity(0.3)
              : AppColors.divider,
        ),
      ),
      child: SwitchListTile(
        secondary: Icon(
          LucideIcons.video,
          color: isEnabled ? CameraColors.fixed : AppColors.textMuted,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isEnabled ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
            ),
            if (isEnabled) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: CameraColors.fixed.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: CameraColors.fixed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Fixa',
                      style: TextStyle(fontSize: 10, color: CameraColors.fixed),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: CameraColors.mobile.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: CameraColors.mobile,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Movel',
                      style: TextStyle(fontSize: 10, color: CameraColors.mobile),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isEnabled ? AppColors.textSecondary : AppColors.textMuted,
          ),
        ),
        value: isEnabled,
        onChanged: onChanged,
        activeColor: CameraColors.fixed,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
    );
  }

  Widget _buildIncidentTypeFilters(MapState state, MapController controller) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: IncidentType.values.map((type) {
        if (type == IncidentType.unknown) return const SizedBox.shrink();

        final isSelected = state.incidentFilters.selectedTypes.isEmpty ||
            state.incidentFilters.selectedTypes.contains(type);

        return FilterChip(
          avatar: Icon(
            type.icon,
            size: 16,
            color: isSelected ? Colors.white : type.color,
          ),
          label: Text(type.label),
          selected: state.incidentFilters.selectedTypes.contains(type),
          onSelected: (_) => controller.toggleIncidentTypeFilter(type),
          backgroundColor: AppColors.background,
          selectedColor: type.color,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            fontSize: 12,
            color: state.incidentFilters.selectedTypes.contains(type)
                ? Colors.white
                : AppColors.textSecondary,
          ),
          side: BorderSide(
            color: isSelected ? type.color : AppColors.divider,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
        );
      }).toList(),
    );
  }

  Widget _buildSeverityFilters(MapState state, MapController controller) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: IncidentSeverity.values.map((severity) {
        final isSelected = state.incidentFilters.selectedSeverities.isEmpty ||
            state.incidentFilters.selectedSeverities.contains(severity);

        return FilterChip(
          avatar: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: severity.color,
              shape: BoxShape.circle,
            ),
          ),
          label: Text(severity.label),
          selected: state.incidentFilters.selectedSeverities.contains(severity),
          onSelected: (_) => controller.toggleIncidentSeverityFilter(severity),
          backgroundColor: AppColors.background,
          selectedColor: severity.color,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            fontSize: 12,
            color: state.incidentFilters.selectedSeverities.contains(severity)
                ? Colors.white
                : AppColors.textSecondary,
          ),
          side: BorderSide(
            color: isSelected ? severity.color : AppColors.divider,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
        );
      }).toList(),
    );
  }
}

/// Botao flutuante para abrir o bottom sheet de camadas
class MapLayersButton extends StatelessWidget {
  final int activeFilterCount;
  final VoidCallback onPressed;

  const MapLayersButton({
    super.key,
    required this.activeFilterCount,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        FloatingActionButton.small(
          heroTag: 'layers',
          backgroundColor: AppColors.surface,
          onPressed: onPressed,
          child: const Icon(LucideIcons.layers, color: AppColors.primary),
        ),
        if (activeFilterCount > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                activeFilterCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
