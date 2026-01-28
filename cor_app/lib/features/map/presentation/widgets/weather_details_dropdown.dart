import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/models/alertario_forecast_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/map_controller.dart';

/// Dropdown com detalhes completos do Alerta Rio
class WeatherDetailsDropdown extends StatelessWidget {
  final AlertaRioForecast forecast;
  final VoidCallback onClose;
  final MapTheme mapTheme;

  const WeatherDetailsDropdown({
    super.key,
    required this.forecast,
    required this.onClose,
    this.mapTheme = MapTheme.dark,
  });

  /// Cores adaptativas baseadas no tema do mapa
  Color get _surfaceColor => mapTheme == MapTheme.dark
      ? AppColors.surface.withValues(alpha: 0.98)
      : const Color(0xFAFFFFFF); // 98% branco opaco

  Color get _backgroundColor => mapTheme == MapTheme.dark
      ? AppColors.background.withValues(alpha: 0.6)
      : const Color(0xFFF1F5F9); // Slate 100

  Color get _textPrimaryColor => mapTheme == MapTheme.dark
      ? AppColors.textPrimary
      : const Color(0xFF1E293B); // Slate 800

  Color get _textSecondaryColor => mapTheme == MapTheme.dark
      ? AppColors.textSecondary
      : const Color(0xFF64748B); // Slate 500

  Color get _textMutedColor => mapTheme == MapTheme.dark
      ? AppColors.textMuted
      : const Color(0xFF94A3B8); // Slate 400

  Color get _dividerColor => mapTheme == MapTheme.dark
      ? AppColors.divider.withValues(alpha: 0.5)
      : const Color(0x33000000); // 20% preto

  @override
  Widget build(BuildContext context) {
    // Debug log
    if (kDebugMode) {
      print('[WeatherDetailsDropdown] Renderizando dropdown:');
      print('  - items: ${forecast.items.length}');
      print('  - temperatures: ${forecast.temperatures.length}');
      print('  - synoptic: ${forecast.synoptic != null}');
      print('  - tides: ${forecast.tides.length}');
      print('  - city: ${forecast.city}');
      print('  - updatedAt: ${forecast.updatedAt}');
    }

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(AppRadius.lg),
        bottomRight: Radius.circular(AppRadius.lg),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          decoration: BoxDecoration(
            // Fundo adaptativo ao tema
            color: _surfaceColor,
            // Nota: borderRadius é aplicado pelo ClipRRect externo
            // Usar Border com lados diferentes sem borderRadius para evitar erro
            border: Border(
              bottom: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.4),
                width: 2,
              ),
              left: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 1,
              ),
              right: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: mapTheme == MapTheme.dark ? 0.5 : 0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                _buildHeader(),

                // Content
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Previsão por período
                      if (forecast.items.isNotEmpty) ...[
                        _buildSectionTitle('Previsao por Periodo'),
                        const SizedBox(height: AppSpacing.sm),
                        _buildPeriodsList(),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Temperaturas por zona
                      if (forecast.temperatures.isNotEmpty) ...[
                        _buildSectionTitle('Temperaturas por Zona'),
                        const SizedBox(height: AppSpacing.sm),
                        _buildTemperaturesList(),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Resumo sinótico
                      if (forecast.synoptic != null) ...[
                        _buildSectionTitle('Resumo Sinotico'),
                        const SizedBox(height: AppSpacing.sm),
                        _buildSynopticSummary(),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // Tábua de marés
                      if (forecast.tides.isNotEmpty) ...[
                        _buildSectionTitle('Tabua de Mares'),
                        const SizedBox(height: AppSpacing.sm),
                        _buildTidesList(),
                      ],

                      // Mensagem se não houver dados
                      if (forecast.items.isEmpty &&
                          forecast.temperatures.isEmpty &&
                          forecast.synoptic == null &&
                          forecast.tides.isEmpty)
                        _buildNoDataMessage(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.2),
            AppColors.primary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            LucideIcons.cloudSun,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Previsao Alerta Rio',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textPrimaryColor,
              ),
            ),
          ),
          if (forecast.updatedAt != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _formatTime(forecast.updatedAt!),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppColors.success,
                ),
              ),
            ),
          const SizedBox(width: AppSpacing.md),
          GestureDetector(
            onTap: onClose,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.emergency.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.emergency.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                LucideIcons.x,
                size: 16,
                color: AppColors.emergency,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodsList() {
    return Column(
      children: forecast.items.map((item) {
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.xs),
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: _getPeriodColor(item.period).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              // Ícone do período com fundo
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _getPeriodColor(item.period).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getPeriodIcon(item.period),
                  size: 16,
                  color: _getPeriodColor(item.period),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Período
              SizedBox(
                width: 75,
                child: Text(
                  item.period,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getPeriodColor(item.period),
                  ),
                ),
              ),
              // Condição
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.condition,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _textPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.precipitation != null &&
                        item.precipitation!.isNotEmpty &&
                        item.precipitation != 'Sem chuva')
                      Row(
                        children: [
                          Icon(
                            LucideIcons.cloudRain,
                            size: 10,
                            color: AppColors.info,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              item.precipitation!,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.info,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTemperaturesList() {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: forecast.temperatures.map((zone) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.info.withValues(alpha: 0.1),
                AppColors.alert.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(
              color: _dividerColor,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                zone.zone,
                style: TextStyle(
                  fontSize: 10,
                  color: _textSecondaryColor,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${zone.tempMin?.round() ?? '-'}°',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.info,
                ),
              ),
              Text(
                ' - ',
                style: TextStyle(
                  fontSize: 11,
                  color: _textMutedColor,
                ),
              ),
              Text(
                '${zone.tempMax?.round() ?? '-'}°',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.alert,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSynopticSummary() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: _dividerColor,
        ),
      ),
      child: Text(
        forecast.synoptic!.summary,
        style: TextStyle(
          fontSize: 11,
          color: _textPrimaryColor,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildTidesList() {
    return Row(
      children: forecast.tides.map((tide) {
        final isHigh = tide.level.toLowerCase().contains('alta');
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: AppSpacing.xs),
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: (isHigh ? AppColors.info : AppColors.success)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: (isHigh ? AppColors.info : AppColors.success)
                    .withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  isHigh ? LucideIcons.arrowUp : LucideIcons.arrowDown,
                  size: 16,
                  color: isHigh ? AppColors.info : AppColors.success,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTideTime(tide.time),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isHigh ? AppColors.info : AppColors.success,
                  ),
                ),
                Text(
                  '${tide.height.toStringAsFixed(1)}m',
                  style: TextStyle(
                    fontSize: 10,
                    color: _textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getPeriodIcon(String period) {
    final lower = period.toLowerCase();
    if (lower.contains('manh')) return LucideIcons.sunrise;
    if (lower.contains('tarde')) return LucideIcons.sun;
    if (lower.contains('noite')) return LucideIcons.moon;
    if (lower.contains('madrugada')) return LucideIcons.moonStar;
    return LucideIcons.clock;
  }

  Color _getPeriodColor(String period) {
    final lower = period.toLowerCase();
    if (lower.contains('manh')) return Colors.orange;
    if (lower.contains('tarde')) return Colors.amber;
    if (lower.contains('noite')) return const Color(0xFF6366F1); // Indigo mais vibrante
    if (lower.contains('madrugada')) return const Color(0xFF8B5CF6); // Purple mais vibrante
    return AppColors.textSecondary;
  }

  String _formatTime(DateTime dt) {
    return DateFormat('HH:mm').format(dt.toLocal());
  }

  String _formatTideTime(DateTime dt) {
    return DateFormat('HH:mm').format(dt.toLocal());
  }

  Widget _buildNoDataMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: _dividerColor),
      ),
      child: Column(
        children: [
          Icon(
            LucideIcons.cloudOff,
            size: 48,
            color: _textMutedColor,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Dados indisponiveis',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: _textPrimaryColor,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Nao foi possivel carregar os detalhes da previsao do Alerta Rio. Tente novamente mais tarde.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: _textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
