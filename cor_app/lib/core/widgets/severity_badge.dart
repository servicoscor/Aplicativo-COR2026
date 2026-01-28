import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';

/// Severidade de alertas/incidentes
enum Severity {
  info,
  alert,
  emergency;

  Color get color {
    switch (this) {
      case Severity.info:
        return AppColors.info;
      case Severity.alert:
        return AppColors.alert;
      case Severity.emergency:
        return AppColors.emergency;
    }
  }

  IconData get icon {
    switch (this) {
      case Severity.info:
        return LucideIcons.info;
      case Severity.alert:
        return LucideIcons.alertTriangle;
      case Severity.emergency:
        return LucideIcons.alertOctagon;
    }
  }

  String get label {
    switch (this) {
      case Severity.info:
        return 'Informativo';
      case Severity.alert:
        return 'Alerta';
      case Severity.emergency:
        return 'Emergência';
    }
  }

  static Severity fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'alert':
        return Severity.alert;
      case 'emergency':
        return Severity.emergency;
      default:
        return Severity.info;
    }
  }
}

/// Badge de severidade
class SeverityBadge extends StatelessWidget {
  final Severity severity;
  final bool showLabel;
  final bool compact;

  const SeverityBadge({
    super.key,
    required this.severity,
    this.showLabel = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: compact ? 4 : AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: severity.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: severity.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            severity.icon,
            size: compact ? 14 : 16,
            color: severity.color,
          ),
          if (showLabel) ...[
            SizedBox(width: compact ? 4 : AppSpacing.xs),
            Text(
              severity.label,
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: severity.color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Indicador de status (ponto colorido)
class StatusDot extends StatelessWidget {
  final Color color;
  final double size;
  final bool animate;

  const StatusDot({
    super.key,
    required this.color,
    this.size = 8,
    this.animate = false,
  });

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );

    if (!animate) return dot;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.5, end: 1.0),
      duration: const Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: child,
        );
      },
      child: dot,
    );
  }
}
