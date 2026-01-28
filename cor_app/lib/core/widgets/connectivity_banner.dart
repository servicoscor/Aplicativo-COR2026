import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/connectivity_service.dart';
import '../theme/app_theme.dart';

/// Banner de status de conectividade
/// Mostra ONLINE/OFFLINE e idade dos dados
class ConnectivityBanner extends ConsumerWidget {
  /// Limite em minutos para considerar dados como "stale" (alerta visual)
  final int staleWarningMinutes;

  /// Se deve mostrar mesmo quando online com dados frescos
  final bool alwaysShow;

  const ConnectivityBanner({
    super.key,
    this.staleWarningMinutes = 5,
    this.alwaysShow = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(connectivityControllerProvider);

    // Não mostra se estiver online com dados frescos e alwaysShow = false
    if (!alwaysShow &&
        state.status == ConnectivityStatus.online &&
        !state.hasStaleData &&
        !state.isRefreshing) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getBackgroundColor(state),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            _buildStatusIcon(state),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                state.statusMessage,
                style: TextStyle(
                  color: _getTextColor(state),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (state.isRefreshing)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getTextColor(state),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(ConnectivityState state) {
    IconData icon;
    Color color;

    switch (state.status) {
      case ConnectivityStatus.online:
        icon = state.hasStaleData ? LucideIcons.clock : LucideIcons.wifi;
        color = state.hasStaleData ? AppColors.alert : AppColors.success;
        break;
      case ConnectivityStatus.onlineStale:
        icon = LucideIcons.clock;
        color = AppColors.alert;
        break;
      case ConnectivityStatus.offline:
        icon = LucideIcons.wifiOff;
        color = AppColors.emergency;
        break;
      case ConnectivityStatus.checking:
        icon = LucideIcons.loader;
        color = AppColors.textSecondary;
        break;
    }

    return Icon(icon, size: 18, color: color);
  }

  Color _getBackgroundColor(ConnectivityState state) {
    switch (state.status) {
      case ConnectivityStatus.online:
        if (state.hasStaleData) {
          return AppColors.alert.withOpacity(0.15);
        }
        return AppColors.success.withOpacity(0.15);
      case ConnectivityStatus.onlineStale:
        return AppColors.alert.withOpacity(0.15);
      case ConnectivityStatus.offline:
        return AppColors.emergency.withOpacity(0.2);
      case ConnectivityStatus.checking:
        return AppColors.surface;
    }
  }

  Color _getTextColor(ConnectivityState state) {
    switch (state.status) {
      case ConnectivityStatus.online:
        return state.hasStaleData ? AppColors.alert : AppColors.success;
      case ConnectivityStatus.onlineStale:
        return AppColors.alert;
      case ConnectivityStatus.offline:
        return AppColors.emergency;
      case ConnectivityStatus.checking:
        return AppColors.textSecondary;
    }
  }
}

/// Banner compacto de conectividade (para uso em headers)
class CompactConnectivityIndicator extends ConsumerWidget {
  const CompactConnectivityIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(connectivityControllerProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getBackgroundColor(state),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDot(state),
          const SizedBox(width: 4),
          Text(
            _getLabel(state),
            style: TextStyle(
              color: _getTextColor(state),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(ConnectivityState state) {
    Color color;
    switch (state.status) {
      case ConnectivityStatus.online:
        color = state.hasStaleData ? AppColors.alert : AppColors.success;
        break;
      case ConnectivityStatus.onlineStale:
        color = AppColors.alert;
        break;
      case ConnectivityStatus.offline:
        color = AppColors.emergency;
        break;
      case ConnectivityStatus.checking:
        color = AppColors.textSecondary;
        break;
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  String _getLabel(ConnectivityState state) {
    if (state.isRefreshing) return 'Atualizando';

    switch (state.status) {
      case ConnectivityStatus.online:
        if (state.dataAgeMinutes != null && state.dataAgeMinutes! > 0) {
          return state.ageFormatted;
        }
        return 'Online';
      case ConnectivityStatus.onlineStale:
        return state.ageFormatted;
      case ConnectivityStatus.offline:
        return 'Offline';
      case ConnectivityStatus.checking:
        return '...';
    }
  }

  Color _getBackgroundColor(ConnectivityState state) {
    switch (state.status) {
      case ConnectivityStatus.online:
        return (state.hasStaleData ? AppColors.alert : AppColors.success)
            .withOpacity(0.15);
      case ConnectivityStatus.onlineStale:
        return AppColors.alert.withOpacity(0.15);
      case ConnectivityStatus.offline:
        return AppColors.emergency.withOpacity(0.2);
      case ConnectivityStatus.checking:
        return AppColors.surface;
    }
  }

  Color _getTextColor(ConnectivityState state) {
    switch (state.status) {
      case ConnectivityStatus.online:
        return state.hasStaleData ? AppColors.alert : AppColors.success;
      case ConnectivityStatus.onlineStale:
        return AppColors.alert;
      case ConnectivityStatus.offline:
        return AppColors.emergency;
      case ConnectivityStatus.checking:
        return AppColors.textSecondary;
    }
  }
}

/// Widget que mostra um alerta de dados desatualizados
class StaleDataAlert extends ConsumerWidget {
  final int warningThresholdMinutes;

  const StaleDataAlert({
    super.key,
    this.warningThresholdMinutes = 5,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(connectivityControllerProvider);

    // Não mostra se não estiver stale
    if (!state.hasStaleData ||
        state.dataAgeMinutes == null ||
        state.dataAgeMinutes! < warningThresholdMinutes) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.alert.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.alert.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.alertTriangle,
            color: AppColors.alert,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Dados desatualizados',
                  style: TextStyle(
                    color: AppColors.alert,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Última atualização ${state.ageFormatted}',
                  style: TextStyle(
                    color: AppColors.alert.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
