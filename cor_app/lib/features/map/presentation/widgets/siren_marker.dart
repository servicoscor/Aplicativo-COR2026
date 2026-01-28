import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/models/siren_model.dart';
import '../../../../core/theme/app_theme.dart';

/// Widget de marcador de sirene no mapa
class SirenMarkerWidget extends StatelessWidget {
  final Siren siren;
  final VoidCallback? onTap;

  const SirenMarkerWidget({
    super.key,
    required this.siren,
    this.onTap,
  });

  Color get _markerColor {
    switch (siren.status) {
      case SirenStatus.triggered:
        return AppColors.emergency; // Vermelho - Acionada
      case SirenStatus.active:
        return AppColors.success; // Verde - Ativa
      case SirenStatus.inactive:
        return AppColors.textMuted; // Cinza - Desativada
      case SirenStatus.unknown:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTriggered = siren.isTriggered;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: _markerColor,
            width: isTriggered ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _markerColor.withOpacity(isTriggered ? 0.5 : 0.3),
              blurRadius: isTriggered ? 10 : 6,
              spreadRadius: isTriggered ? 2 : 1,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            isTriggered ? LucideIcons.bellRing : LucideIcons.bell,
            size: 18,
            color: _markerColor,
          ),
        ),
      ),
    );
  }
}

/// Widget para lista de sirenes
class SirenListTile extends StatelessWidget {
  final Siren siren;
  final VoidCallback? onTap;

  const SirenListTile({
    super.key,
    required this.siren,
    this.onTap,
  });

  Color get _statusColor {
    switch (siren.status) {
      case SirenStatus.triggered:
        return AppColors.emergency;
      case SirenStatus.active:
        return AppColors.success;
      case SirenStatus.inactive:
        return AppColors.textMuted;
      case SirenStatus.unknown:
        return AppColors.textSecondary;
    }
  }

  IconData get _statusIcon {
    switch (siren.status) {
      case SirenStatus.triggered:
        return LucideIcons.bellRing;
      case SirenStatus.active:
        return LucideIcons.bell;
      case SirenStatus.inactive:
        return LucideIcons.bellOff;
      case SirenStatus.unknown:
        return LucideIcons.bellMinus;
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  color: _statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Center(
                  child: Icon(
                    _statusIcon,
                    color: _statusColor,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      siren.name,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (siren.basin != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        siren.basin!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            siren.statusLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _statusColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: siren.online
                                ? AppColors.success
                                : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          siren.online ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontSize: 10,
                            color: siren.online
                                ? AppColors.success
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Marcador de cluster de sirenes
class SirenClusterMarker extends StatelessWidget {
  final int count;

  const SirenClusterMarker({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.alert,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.alert.withOpacity(0.3),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.bell,
            size: 14,
            color: AppColors.alert,
          ),
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.alert,
            ),
          ),
        ],
      ),
    );
  }
}
