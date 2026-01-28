import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/models/rain_gauge_model.dart';
import '../../../../core/theme/app_theme.dart';

/// Intensidade da chuva para o heatmap
enum RainHeatmapIntensity {
  none,
  low,
  medium,
  high,
  veryHigh,
}

/// Ponto de dados para o heatmap
class HeatmapPoint {
  final LatLng location;
  final double value; // mm de chuva
  final RainHeatmapIntensity intensity;

  HeatmapPoint({
    required this.location,
    required this.value,
    required this.intensity,
  });

  /// Cor baseada na intensidade
  Color get color {
    switch (intensity) {
      case RainHeatmapIntensity.none:
        return Colors.transparent;
      case RainHeatmapIntensity.low:
        return const Color(0xFF4CAF50); // Verde
      case RainHeatmapIntensity.medium:
        return const Color(0xFFFFC107); // Amarelo
      case RainHeatmapIntensity.high:
        return const Color(0xFFFF9800); // Laranja
      case RainHeatmapIntensity.veryHigh:
        return const Color(0xFFF44336); // Vermelho
    }
  }

  /// Raio baseado na intensidade (em metros)
  double get radiusMeters {
    switch (intensity) {
      case RainHeatmapIntensity.none:
        return 0;
      case RainHeatmapIntensity.low:
        return 1500;
      case RainHeatmapIntensity.medium:
        return 2000;
      case RainHeatmapIntensity.high:
        return 2500;
      case RainHeatmapIntensity.veryHigh:
        return 3000;
    }
  }

  /// Opacidade baseada no valor
  double get opacity {
    if (value <= 0) return 0;
    // Opacidade entre 0.2 e 0.6 baseada no valor
    return math.min(0.6, 0.2 + (value / 50) * 0.4);
  }

  /// Cria a partir de um RainGauge
  factory HeatmapPoint.fromRainGauge(RainGauge gauge, {bool use1Hour = false}) {
    final reading = gauge.currentReading;
    if (reading == null) {
      return HeatmapPoint(
        location: gauge.location,
        value: 0,
        intensity: RainHeatmapIntensity.none,
      );
    }

    // Usa mm/1h se disponível e solicitado, senão usa valor atual (15min)
    final value = use1Hour
        ? (reading.accumulated1hour ?? reading.value)
        : reading.value;

    return HeatmapPoint(
      location: gauge.location,
      value: value,
      intensity: _calculateIntensity(value, use1Hour),
    );
  }

  /// Calcula intensidade baseado no valor
  static RainHeatmapIntensity _calculateIntensity(double value, bool use1Hour) {
    if (value <= 0) return RainHeatmapIntensity.none;

    // Thresholds diferentes para 15min vs 1h
    if (use1Hour) {
      // Acumulado 1 hora
      if (value < 5) return RainHeatmapIntensity.low;
      if (value < 15) return RainHeatmapIntensity.medium;
      if (value < 30) return RainHeatmapIntensity.high;
      return RainHeatmapIntensity.veryHigh;
    } else {
      // 15 minutos
      if (value < 2.5) return RainHeatmapIntensity.low;
      if (value < 10) return RainHeatmapIntensity.medium;
      if (value < 25) return RainHeatmapIntensity.high;
      return RainHeatmapIntensity.veryHigh;
    }
  }
}

/// Camada de heatmap de chuva para flutter_map
class RainHeatmapLayer extends StatelessWidget {
  final List<RainGauge> stations;
  final bool use1HourAccumulated;

  const RainHeatmapLayer({
    super.key,
    required this.stations,
    this.use1HourAccumulated = false,
  });

  @override
  Widget build(BuildContext context) {
    // Converte estações em pontos de heatmap
    final points = stations
        .map((s) => HeatmapPoint.fromRainGauge(s, use1Hour: use1HourAccumulated))
        .where((p) => p.intensity != RainHeatmapIntensity.none)
        .toList();

    if (points.isEmpty) {
      return const SizedBox.shrink();
    }

    // Ordena por intensidade (menor primeiro) para que os mais intensos fiquem por cima
    points.sort((a, b) => a.intensity.index.compareTo(b.intensity.index));

    return CircleLayer(
      circles: points.map((point) => _buildCircle(point)).toList(),
    );
  }

  CircleMarker _buildCircle(HeatmapPoint point) {
    return CircleMarker(
      point: point.location,
      radius: point.radiusMeters,
      useRadiusInMeter: true,
      color: point.color.withOpacity(point.opacity),
      borderColor: point.color.withOpacity(point.opacity * 0.5),
      borderStrokeWidth: 1,
    );
  }
}

/// Widget de legenda do heatmap
class RainHeatmapLegend extends StatelessWidget {
  final bool use1HourAccumulated;
  final VoidCallback? onClose;

  const RainHeatmapLegend({
    super.key,
    this.use1HourAccumulated = false,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.water_drop,
                size: 16,
                color: AppColors.info,
              ),
              const SizedBox(width: 6),
              Text(
                use1HourAccumulated ? 'Chuva (1h)' : 'Chuva (15min)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (onClose != null) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onClose,
                  child: const Icon(
                    Icons.close,
                    size: 14,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          _buildLegendItem(
            color: const Color(0xFF4CAF50),
            label: 'Fraca',
            value: use1HourAccumulated ? '< 5mm' : '< 2.5mm',
          ),
          const SizedBox(height: 4),
          _buildLegendItem(
            color: const Color(0xFFFFC107),
            label: 'Moderada',
            value: use1HourAccumulated ? '5-15mm' : '2.5-10mm',
          ),
          const SizedBox(height: 4),
          _buildLegendItem(
            color: const Color(0xFFFF9800),
            label: 'Forte',
            value: use1HourAccumulated ? '15-30mm' : '10-25mm',
          ),
          const SizedBox(height: 4),
          _buildLegendItem(
            color: const Color(0xFFF44336),
            label: 'Muito Forte',
            value: use1HourAccumulated ? '> 30mm' : '> 25mm',
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color.withOpacity(0.6),
            shape: BoxShape.circle,
            border: Border.all(
              color: color,
              width: 1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

/// Legenda compacta (apenas cores)
class CompactRainHeatmapLegend extends StatelessWidget {
  const CompactRainHeatmapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.water_drop,
            size: 12,
            color: AppColors.info,
          ),
          const SizedBox(width: 6),
          _buildColorBar(),
          const SizedBox(width: 6),
          const Text(
            'Fraca',
            style: TextStyle(fontSize: 9, color: AppColors.textMuted),
          ),
          const SizedBox(width: 2),
          const Text(
            '→',
            style: TextStyle(fontSize: 9, color: AppColors.textMuted),
          ),
          const SizedBox(width: 2),
          const Text(
            'Forte',
            style: TextStyle(fontSize: 9, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildColorBar() {
    return Container(
      width: 60,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF4CAF50), // Verde
            Color(0xFFFFC107), // Amarelo
            Color(0xFFFF9800), // Laranja
            Color(0xFFF44336), // Vermelho
          ],
        ),
      ),
    );
  }
}
