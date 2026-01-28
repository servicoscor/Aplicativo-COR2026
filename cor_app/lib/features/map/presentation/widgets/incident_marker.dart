import 'package:flutter/material.dart';
import '../../../../core/models/incident_model.dart';
import '../../../../core/theme/app_theme.dart';

/// Widget de marcador de incidente no mapa
class IncidentMarkerWidget extends StatelessWidget {
  final Incident incident;
  final VoidCallback? onTap;

  const IncidentMarkerWidget({
    super.key,
    required this.incident,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: incident.type.color,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: incident.type.color.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            incident.type.icon,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

/// Widget compacto para lista
class IncidentListTile extends StatelessWidget {
  final Incident incident;
  final VoidCallback? onTap;

  const IncidentListTile({
    super.key,
    required this.incident,
    this.onTap,
  });

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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: incident.type.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  incident.type.icon,
                  color: incident.type.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      incident.title,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: incident.severity.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            incident.type.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: incident.severity.color,
                            ),
                          ),
                        ),
                        if (incident.affectedRoutes != null &&
                            incident.affectedRoutes!.isNotEmpty) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              incident.affectedRoutes!.join(', '),
                              style: Theme.of(context).textTheme.labelSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
