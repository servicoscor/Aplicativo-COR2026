import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';

/// Widget de marcador de cluster para incidentes
class IncidentClusterMarker extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const IncidentClusterMarker({
    super.key,
    required this.count,
    this.onTap,
  });

  Color get _clusterColor {
    if (count >= 10) return AppColors.emergency;
    if (count >= 5) return AppColors.accent;
    if (count >= 3) return AppColors.alert;
    return AppColors.primary;
  }

  double get _size {
    if (count >= 10) return 56;
    if (count >= 5) return 50;
    return 44;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          color: _clusterColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: _clusterColor.withOpacity(0.4),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Icon(
                LucideIcons.alertTriangle,
                color: Colors.white,
                size: 12,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget de marcador de cluster para pluviometros
class RainGaugeClusterMarker extends StatelessWidget {
  final int count;
  final VoidCallback? onTap;

  const RainGaugeClusterMarker({
    super.key,
    required this.count,
    this.onTap,
  });

  double get _size {
    if (count >= 10) return 52;
    if (count >= 5) return 46;
    return 40;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.info,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.info.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                count.toString(),
                style: const TextStyle(
                  color: AppColors.info,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const Icon(
                LucideIcons.droplet,
                color: AppColors.info,
                size: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
