import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../services/cache_service.dart';

/// Badge que mostra a idade dos dados
class DataAgeBadge extends StatelessWidget {
  final CacheStatus status;
  final bool showIcon;
  final bool compact;

  const DataAgeBadge({
    super.key,
    required this.status,
    this.showIcon = true,
    this.compact = false,
  });

  /// Cria badge a partir de idade em minutos
  factory DataAgeBadge.fromAge({
    Key? key,
    required int? ageMinutes,
    bool isStale = false,
    bool isOutdated = false,
    bool showIcon = true,
    bool compact = false,
  }) {
    String ageFormatted;
    String ageCompact;

    if (ageMinutes == null) {
      ageFormatted = 'Sem dados';
      ageCompact = '--';
    } else if (ageMinutes < 1) {
      ageFormatted = 'agora';
      ageCompact = '<1m';
    } else if (ageMinutes < 60) {
      ageFormatted = 'há $ageMinutes min';
      ageCompact = '${ageMinutes}m';
    } else {
      final hours = ageMinutes ~/ 60;
      ageFormatted = 'há $hours hora${hours > 1 ? 's' : ''}';
      ageCompact = '${hours}h';
    }

    return DataAgeBadge(
      key: key,
      status: CacheStatus(
        key: '',
        exists: ageMinutes != null,
        isStale: isStale,
        isOutdated: isOutdated,
        ageMinutes: ageMinutes,
        ageFormatted: ageFormatted,
        ageCompact: ageCompact,
      ),
      showIcon: showIcon,
      compact: compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor();
    final icon = _getStatusIcon();

    if (compact) {
      return _buildCompact(color, icon);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            status.ageFormatted ?? 'Sem dados',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompact(Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            status.ageCompact ?? '--',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (status.statusLevel) {
      case 0:
        return AppColors.success;
      case 1:
        return const Color(0xFFFF9800); // Laranja
      case 2:
        return AppColors.emergency;
      default:
        return AppColors.textMuted;
    }
  }

  IconData _getStatusIcon() {
    switch (status.statusLevel) {
      case 0:
        return LucideIcons.checkCircle;
      case 1:
        return LucideIcons.clock;
      case 2:
        return LucideIcons.alertTriangle;
      default:
        return LucideIcons.helpCircle;
    }
  }
}

/// Badge inline para exibir em texto
class DataAgeInline extends StatelessWidget {
  final int? ageMinutes;
  final bool isStale;
  final bool isOutdated;

  const DataAgeInline({
    super.key,
    this.ageMinutes,
    this.isStale = false,
    this.isOutdated = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor();

    String text;
    if (ageMinutes == null) {
      text = '';
    } else if (ageMinutes! < 1) {
      text = '(agora)';
    } else if (ageMinutes! < 60) {
      text = '(há ${ageMinutes}m)';
    } else {
      final hours = ageMinutes! ~/ 60;
      text = '(há ${hours}h)';
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        color: color,
        fontWeight: isOutdated ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Color _getColor() {
    if (isOutdated) return AppColors.emergency;
    if (isStale) return const Color(0xFFFF9800);
    return AppColors.textMuted;
  }
}

/// Banner de alerta quando dados estao muito antigos
class OutdatedDataBanner extends StatelessWidget {
  final String? message;
  final VoidCallback? onRefresh;

  const OutdatedDataBanner({
    super.key,
    this.message,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFF9800).withOpacity(0.15),
        border: Border.all(
          color: const Color(0xFFFF9800).withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            LucideIcons.alertTriangle,
            size: 16,
            color: Color(0xFFFF9800),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message ?? 'Dados podem estar desatualizados',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFFF9800),
              ),
            ),
          ),
          if (onRefresh != null)
            GestureDetector(
              onTap: onRefresh,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Atualizar',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFF9800),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
