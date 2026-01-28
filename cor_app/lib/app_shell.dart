import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'core/theme/app_theme.dart';
import 'core/services/fcm_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/widgets/connectivity_banner.dart';
import 'features/map/presentation/screens/map_screen.dart';
import 'features/map/presentation/controllers/map_controller.dart';
import 'features/alerts/presentation/screens/alerts_screen.dart';
import 'features/alerts/presentation/screens/alert_detail_screen.dart';
import 'features/alerts/presentation/controllers/alerts_controller.dart';
import 'features/favorites/presentation/screens/favorites_screen.dart';
import 'features/settings/presentation/screens/settings_screen.dart';

/// Shell principal do app com navegação
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;
  LatLng? _highlightArea;

  // Keys para preservar estado das telas
  final _mapKey = GlobalKey();
  final _alertsKey = GlobalKey();
  final _favoritesKey = GlobalKey();
  final _settingsKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // Escuta navegação de notificações
    _setupNotificationNavigation();
  }

  void _setupNotificationNavigation() {
    // Listener para quando usuário toca em notificação
    ref.listenManual(alertNavigationProvider, (previous, next) {
      next.whenData((alertId) {
        if (alertId != null) {
          _navigateToAlert(alertId);
        }
      });
    });
  }

  Future<void> _navigateToAlert(String alertId) async {
    // Muda para aba de alertas
    setState(() {
      _currentIndex = 1;
    });

    // Carrega alertas se necessário
    final alertsState = ref.read(alertsControllerProvider);
    if (alertsState.alerts.isEmpty) {
      await ref.read(alertsControllerProvider.notifier).loadAlerts();
    }

    // Encontra o alerta
    final alerts = ref.read(alertsControllerProvider).alerts;
    final alert = alerts.where((a) => a.id == alertId).firstOrNull;

    if (alert != null && mounted) {
      // Navega para detalhes do alerta
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => AlertDetailScreen(alert: alert),
        ),
      );
    }
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
      // Limpa highlight area ao mudar de aba (exceto se for para o mapa)
      if (index != 0) {
        _highlightArea = null;
      }
    });
  }

  void _navigateToMapWithHighlight(LatLng location) {
    setState(() {
      _highlightArea = location;
      _currentIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Escuta contagem de alertas não lidos
    final unreadCount = ref.watch(unreadAlertsCountProvider);

    // Atualiza idade dos dados no ConnectivityController
    final mapState = ref.watch(mapControllerProvider);
    _updateConnectivityDataAge(mapState);

    return Scaffold(
      body: Column(
        children: [
          // Banner de conectividade no topo
          const ConnectivityBanner(),
          // Conteúdo principal
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                MapScreen(
                  key: _mapKey,
                  highlightArea: _highlightArea,
                ),
                AlertsScreen(key: _alertsKey),
                FavoritesScreen(key: _favoritesKey),
                SettingsScreen(key: _settingsKey),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(unreadCount),
    );
  }

  void _updateConnectivityDataAge(MapState mapState) {
    // Calcula idade máxima dos dados baseado em isStale flags
    int? maxAge;

    if (mapState.weather?.isStale == true ||
        mapState.radar?.isStale == true ||
        mapState.incidents?.isStale == true ||
        mapState.rainGauges?.isStale == true) {
      // Se algum dado está stale, assume pelo menos 5 minutos
      maxAge = 5;
    } else if (mapState.weather != null ||
        mapState.radar != null ||
        mapState.incidents != null ||
        mapState.rainGauges != null) {
      // Dados frescos
      maxAge = 0;
    }

    // Atualiza o ConnectivityController
    if (maxAge != null) {
      Future.microtask(() {
        ref.read(connectivityControllerProvider.notifier).updateDataAge(maxAge);

        if (mapState.isLoading) {
          ref.read(connectivityControllerProvider.notifier).setRefreshing(true);
        } else {
          ref.read(connectivityControllerProvider.notifier).setRefreshing(false);
        }
      });
    }
  }

  Widget _buildBottomNav(int unreadCount) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: LucideIcons.map,
                label: 'Mapa',
              ),
              _buildNavItem(
                index: 1,
                icon: LucideIcons.bell,
                label: 'Cidade',
                badge: unreadCount > 0 ? unreadCount : null,
              ),
              _buildSocialButton(),
              _buildNavItem(
                index: 2,
                icon: LucideIcons.heart,
                label: 'Favoritos',
              ),
              _buildNavItem(
                index: 3,
                icon: LucideIcons.settings,
                label: 'Config',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    int? badge,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                ),
                if (badge != null)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.emergency,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge > 9 ? '9+' : badge.toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialButton() {
    return GestureDetector(
      onTap: _showSocialDropup,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.globe,
              size: 24,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 4),
            const Text(
              'Redes',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSocialDropup() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: const Icon(
                      LucideIcons.globe,
                      size: 20,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Text(
                    'Redes Sociais do COR',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            // Social links
            _buildSocialItem(
              icon: LucideIcons.twitter,
              label: 'X (Twitter)',
              subtitle: '@aboraboriooficial',
              color: const Color(0xFF1DA1F2),
              url: 'https://twitter.com/aboraboriooficial',
            ),
            _buildSocialItem(
              icon: LucideIcons.instagram,
              label: 'Instagram',
              subtitle: '@operaboracoesrio',
              color: const Color(0xFFE4405F),
              url: 'https://instagram.com/operaboracoesrio',
            ),
            _buildSocialItem(
              icon: LucideIcons.facebook,
              label: 'Facebook',
              subtitle: 'Centro de Operações Rio',
              color: const Color(0xFF1877F2),
              url: 'https://facebook.com/operaboracoesrio',
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialItem({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required String url,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textMuted,
        ),
      ),
      trailing: Icon(
        LucideIcons.externalLink,
        size: 18,
        color: AppColors.textMuted,
      ),
      onTap: () async {
        Navigator.pop(context);
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
    );
  }
}
