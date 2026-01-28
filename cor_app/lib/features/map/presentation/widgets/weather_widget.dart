import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/models/weather_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/data_age_badge.dart';
import '../controllers/map_controller.dart';

/// Widget de clima no topo do mapa
class WeatherWidget extends StatelessWidget {
  final Weather weather;
  final int? ageMinutes;
  final VoidCallback? onTap;
  final bool isExpanded;
  final MapTheme mapTheme;

  const WeatherWidget({
    super.key,
    required this.weather,
    this.ageMinutes,
    this.onTap,
    this.isExpanded = false,
    this.mapTheme = MapTheme.dark,
  });

  /// Cores adaptativas baseadas no tema do mapa
  Color get _backgroundColor => mapTheme == MapTheme.dark
      ? AppColors.glassBackground
      : const Color(0xE6FFFFFF); // 90% branco opaco

  Color get _surfaceColor => mapTheme == MapTheme.dark
      ? AppColors.surface.withValues(alpha: 0.98)
      : const Color(0xFAFFFFFF); // 98% branco opaco

  Color get _borderColor => mapTheme == MapTheme.dark
      ? AppColors.glassBorder
      : const Color(0x33000000); // 20% preto

  Color get _textPrimaryColor => mapTheme == MapTheme.dark
      ? AppColors.textPrimary
      : const Color(0xFF1E293B); // Slate 800

  Color get _textSecondaryColor => mapTheme == MapTheme.dark
      ? AppColors.textSecondary
      : const Color(0xFF64748B); // Slate 500

  Color get _dividerColor => mapTheme == MapTheme.dark
      ? AppColors.divider
      : const Color(0x33000000); // 20% preto

  IconData get _weatherIcon {
    final condition = weather.condition?.toLowerCase() ?? '';
    if (condition.contains('rain') || condition.contains('chuva')) {
      return LucideIcons.cloudRain;
    }
    if (condition.contains('cloud') || condition.contains('nublado')) {
      return LucideIcons.cloud;
    }
    if (condition.contains('sun') || condition.contains('sol') || condition.contains('clear') || condition.contains('claro')) {
      return LucideIcons.sun;
    }
    if (condition.contains('storm') || condition.contains('tempest')) {
      return LucideIcons.cloudLightning;
    }
    if (condition.contains('parcialmente')) {
      return LucideIcons.cloudSun;
    }
    return LucideIcons.thermometer;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: isExpanded
            ? BorderRadius.zero
            : BorderRadius.circular(AppRadius.md),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: isExpanded ? _surfaceColor : _backgroundColor,
              borderRadius: isExpanded
                  ? BorderRadius.zero
                  : BorderRadius.circular(AppRadius.md),
              border: isExpanded
                  ? Border(
                      bottom: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    )
                  : Border.all(color: _borderColor),
              boxShadow: mapTheme == MapTheme.light
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Temperatura principal
                Row(
                  children: [
                    Icon(
                      _weatherIcon,
                      size: 24,
                      color: _textPrimaryColor,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      '${weather.temperature.round()}°',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _textPrimaryColor,
                      ),
                    ),
                  ],
                ),

                // Separador
                Container(
                  width: 1,
                  height: 30,
                  margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  color: _dividerColor,
                ),

                // Info adicional
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Umidade só mostra se disponível (> 0)
                      if (weather.humidity > 0)
                        _buildInfoItem(
                          icon: LucideIcons.droplets,
                          value: '${weather.humidity}%',
                          label: 'Umidade',
                        ),
                      // Vento só mostra se disponível (> 0)
                      if (weather.windSpeed > 0)
                        _buildInfoItem(
                          icon: LucideIcons.wind,
                          value: '${weather.windSpeed.round()} km/h',
                          label: 'Vento',
                        ),
                      // UV só mostra se disponível
                      if (weather.uvIndex != null)
                        _buildInfoItem(
                          icon: LucideIcons.sun,
                          value: '${weather.uvIndex}',
                          label: 'UV',
                        ),
                    ],
                  ),
                ),

                // Indicador de idade dos dados
                if (ageMinutes != null || weather.isStale)
                  Container(
                    margin: const EdgeInsets.only(left: AppSpacing.sm),
                    child: DataAgeBadge.fromAge(
                      ageMinutes: ageMinutes,
                      isStale: weather.isStale,
                      isOutdated: (ageMinutes ?? 0) > 15,
                      compact: true,
                      showIcon: true,
                    ),
                  ),

                // Chevron indicando que é expansível
                if (onTap != null)
                  Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.sm),
                    child: AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        LucideIcons.chevronDown,
                        size: 16,
                        color: _textSecondaryColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: _textSecondaryColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _textPrimaryColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
