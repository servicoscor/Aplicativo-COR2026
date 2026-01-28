import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/models/alert_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/severity_badge.dart';

/// Card de alerta na lista
class AlertCard extends StatelessWidget {
  final Alert alert;
  final VoidCallback? onTap;

  const AlertCard({
    super.key,
    required this.alert,
    this.onTap,
  });

  Color get _severityColor {
    switch (alert.severity) {
      case 'emergency':
        return AppColors.emergency;
      case 'alert':
        return AppColors.alert;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm', 'pt_BR');
    final dateFormat = DateFormat('dd/MM', 'pt_BR');
    final severity = Severity.fromString(alert.severity);

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
            border: Border.all(
              color: alert.severity == 'emergency'
                  ? _severityColor.withOpacity(0.3)
                  : AppColors.divider,
              width: alert.severity == 'emergency' ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header com badges
              Row(
                children: [
                  // Indicador de não lido
                  if (!alert.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  SeverityBadge(severity: severity, compact: true),
                  const SizedBox(width: AppSpacing.sm),
                  if (alert.broadcast)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.radio,
                            size: 12,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Geral',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (alert.matchType == 'geo')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.mapPin,
                            size: 12,
                            color: AppColors.accent,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Local',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  // Timestamp
                  Text(
                    alert.sentAt != null
                        ? '${dateFormat.format(alert.sentAt!)} ${timeFormat.format(alert.sentAt!)}'
                        : timeFormat.format(alert.createdAt),
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Título
              Text(
                alert.title,
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: AppSpacing.xs),

              // Corpo
              Text(
                alert.body,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              // Expiração
              if (alert.expiresAt != null) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Icon(
                      LucideIcons.clock,
                      size: 14,
                      color: alert.isExpired ? AppColors.error : AppColors.textMuted,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      alert.isExpired
                          ? 'Expirado'
                          : 'Expira em ${_formatExpiration(alert.expiresAt!)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: alert.isExpired ? AppColors.error : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatExpiration(DateTime expiresAt) {
    final now = DateTime.now();
    final difference = expiresAt.difference(now);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    }
    if (difference.inHours > 0) {
      return '${difference.inHours}h';
    }
    if (difference.inMinutes > 0) {
      return '${difference.inMinutes}min';
    }
    return 'breve';
  }
}
