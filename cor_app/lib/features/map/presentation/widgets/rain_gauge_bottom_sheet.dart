import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/models/rain_gauge_model.dart';
import '../../../../core/theme/app_theme.dart';

/// Bottom sheet com detalhes do pluviômetro
class RainGaugeBottomSheet extends StatelessWidget {
  final RainGauge gauge;
  final VoidCallback? onViewOnMap;

  const RainGaugeBottomSheet({
    super.key,
    required this.gauge,
    this.onViewOnMap,
  });

  Color get _intensityColor {
    if (gauge.currentReading == null) return AppColors.textMuted;

    final intensity = gauge.currentReading!.intensity?.toLowerCase();
    switch (intensity) {
      case 'none':
        return AppColors.textSecondary;
      case 'light':
        return AppColors.success;
      case 'moderate':
        return AppColors.alert;
      case 'heavy':
        return AppColors.accent;
      case 'very_heavy':
        return AppColors.emergency;
      default:
        return AppColors.textSecondary;
    }
  }

  String get _intensityLabel {
    if (gauge.currentReading == null) return 'Sem dados';

    final intensity = gauge.currentReading!.intensity?.toLowerCase();
    switch (intensity) {
      case 'none':
        return 'Sem chuva';
      case 'light':
        return 'Chuva fraca';
      case 'moderate':
        return 'Chuva moderada';
      case 'heavy':
        return 'Chuva forte';
      case 'very_heavy':
        return 'Chuva muito forte';
      default:
        return 'Sem chuva';
    }
  }

  @override
  Widget build(BuildContext context) {
    final reading = gauge.currentReading;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm', 'pt_BR');

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _intensityColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.droplet,
                            color: _intensityColor,
                            size: 24,
                          ),
                          if (reading != null)
                            Text(
                              '${reading.value.toStringAsFixed(1)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _intensityColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            gauge.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            gauge.neighborhood ?? gauge.region ?? 'Rio de Janeiro',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _intensityColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _intensityLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _intensityColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Acumulados
                if (reading != null) ...[
                  Text(
                    'Acumulado de chuva',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      if (reading.accumulated15min != null)
                        Expanded(
                          child: _buildAccumulatedCard(
                            context,
                            label: '15 min',
                            value: reading.accumulated15min!,
                          ),
                        ),
                      if (reading.accumulated1hour != null) ...[
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildAccumulatedCard(
                            context,
                            label: '1 hora',
                            value: reading.accumulated1hour!,
                          ),
                        ),
                      ],
                      if (reading.accumulated24hours != null) ...[
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildAccumulatedCard(
                            context,
                            label: '24 horas',
                            value: reading.accumulated24hours!,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Informações adicionais
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    children: [
                      if (gauge.altitude != null)
                        _buildInfoRow(
                          context,
                          icon: LucideIcons.mountain,
                          label: 'Altitude',
                          value: '${gauge.altitude!.toStringAsFixed(0)} m',
                        ),
                      if (reading != null) ...[
                        if (gauge.altitude != null) const SizedBox(height: AppSpacing.sm),
                        _buildInfoRow(
                          context,
                          icon: LucideIcons.clock,
                          label: 'Última leitura',
                          value: dateFormat.format(reading.timestamp),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.sm),
                      _buildInfoRow(
                        context,
                        icon: LucideIcons.activity,
                        label: 'Status',
                        value: gauge.status == 'active' ? 'Ativo' : gauge.status,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Botão ver no mapa
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onViewOnMap,
                    icon: const Icon(LucideIcons.mapPin),
                    label: Text(AppLocalizations.of(context)!.viewOnMap),
                  ),
                ),

                // Espaço para safe area
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccumulatedCard(
    BuildContext context, {
    required String label,
    required double value,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        children: [
          Text(
            '${value.toStringAsFixed(1)}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: _intensityColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            'mm',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const Spacer(),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
