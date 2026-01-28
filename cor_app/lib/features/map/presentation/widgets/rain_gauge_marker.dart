import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/models/rain_gauge_model.dart';
import '../../../../core/theme/app_theme.dart';

/// Widget de marcador de pluviômetro no mapa
class RainGaugeMarkerWidget extends StatelessWidget {
  final RainGauge gauge;
  final VoidCallback? onTap;

  const RainGaugeMarkerWidget({
    super.key,
    required this.gauge,
    this.onTap,
  });

  Color get _markerColor {
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

  @override
  Widget build(BuildContext context) {
    final reading = gauge.currentReading;
    final hasRain = reading != null && reading.value > 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: _markerColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _markerColor.withOpacity(0.3),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: hasRain
              ? Text(
                  reading.value.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _markerColor,
                  ),
                )
              : Icon(
                  LucideIcons.droplet,
                  size: 18,
                  color: _markerColor,
                ),
        ),
      ),
    );
  }
}

/// Widget para lista de pluviômetros
class RainGaugeListTile extends StatelessWidget {
  final RainGauge gauge;
  final VoidCallback? onTap;

  const RainGaugeListTile({
    super.key,
    required this.gauge,
    this.onTap,
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

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _intensityColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.droplet,
                      color: _intensityColor,
                      size: 20,
                    ),
                    if (reading != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${reading.value.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _intensityColor,
                        ),
                      ),
                    ],
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
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      gauge.neighborhood ?? gauge.region ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _intensityColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _intensityLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _intensityColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (reading != null) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (reading.accumulated1hour != null)
                      _buildAccumulated('1h', reading.accumulated1hour!),
                    if (reading.accumulated24hours != null) ...[
                      const SizedBox(height: 4),
                      _buildAccumulated('24h', reading.accumulated24hours!),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccumulated(String label, double value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '${value.toStringAsFixed(1)} mm',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
