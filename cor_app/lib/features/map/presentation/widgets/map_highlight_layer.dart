import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/map_controller.dart';

/// Layer de highlight animado para o mapa
class MapHighlightLayer extends ConsumerStatefulWidget {
  const MapHighlightLayer({super.key});

  @override
  ConsumerState<MapHighlightLayer> createState() => _MapHighlightLayerState();
}

class _MapHighlightLayerState extends ConsumerState<MapHighlightLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnimation = Tween<double>(begin: 0.8, end: 0.3).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final highlight = ref.watch(mapHighlightProvider);

    if (highlight == null || highlight.isExpired) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        switch (highlight.type) {
          case MapHighlightType.point:
            return _buildPointHighlight(highlight);
          case MapHighlightType.polygon:
            return _buildPolygonHighlight(highlight);
          case MapHighlightType.bounds:
            return _buildBoundsHighlight(highlight);
        }
      },
    );
  }

  Widget _buildPointHighlight(MapHighlightState highlight) {
    if (highlight.point == null) return const SizedBox.shrink();

    return MarkerLayer(
      markers: [
        Marker(
          point: highlight.point!,
          width: 80 * _pulseAnimation.value,
          height: 80 * _pulseAnimation.value,
          child: _PulseMarker(
            color: highlight.color,
            pulseValue: _pulseAnimation.value,
            opacityValue: _opacityAnimation.value,
          ),
        ),
      ],
    );
  }

  Widget _buildPolygonHighlight(MapHighlightState highlight) {
    if (highlight.polygon == null || highlight.polygon!.isEmpty) {
      return const SizedBox.shrink();
    }

    return PolygonLayer(
      polygons: [
        // Área preenchida com opacidade animada
        Polygon(
          points: highlight.polygon!,
          color: highlight.color.withOpacity(0.15 * _opacityAnimation.value),
          borderColor: highlight.color.withOpacity(_opacityAnimation.value),
          borderStrokeWidth: 3.0 * _pulseAnimation.value,
          isFilled: true,
        ),
        // Borda externa com glow
        Polygon(
          points: highlight.polygon!,
          color: Colors.transparent,
          borderColor: highlight.color.withOpacity(0.3 * _opacityAnimation.value),
          borderStrokeWidth: 8.0 * _pulseAnimation.value,
          isFilled: false,
        ),
      ],
    );
  }

  Widget _buildBoundsHighlight(MapHighlightState highlight) {
    if (highlight.bounds == null) return const SizedBox.shrink();

    final bounds = highlight.bounds!;
    final points = [
      bounds.northWest,
      bounds.northEast,
      bounds.southEast,
      bounds.southWest,
      bounds.northWest, // Fecha o retângulo
    ];

    return PolygonLayer(
      polygons: [
        Polygon(
          points: points,
          color: highlight.color.withOpacity(0.1 * _opacityAnimation.value),
          borderColor: highlight.color.withOpacity(_opacityAnimation.value),
          borderStrokeWidth: 2.0 * _pulseAnimation.value,
          isFilled: true,
        ),
      ],
    );
  }
}

/// Marker pulsante para highlight de ponto
class _PulseMarker extends StatelessWidget {
  final Color color;
  final double pulseValue;
  final double opacityValue;

  const _PulseMarker({
    required this.color,
    required this.pulseValue,
    required this.opacityValue,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Círculo externo pulsante (glow)
        Container(
          width: 70 * pulseValue,
          height: 70 * pulseValue,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15 * opacityValue),
            border: Border.all(
              color: color.withOpacity(0.3 * opacityValue),
              width: 2,
            ),
          ),
        ),
        // Círculo médio
        Container(
          width: 45 * pulseValue,
          height: 45 * pulseValue,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.25 * opacityValue),
            border: Border.all(
              color: color.withOpacity(0.5 * opacityValue),
              width: 2,
            ),
          ),
        ),
        // Círculo central sólido
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget standalone para marker pulsante (pode ser usado fora do layer)
class PulseMarkerWidget extends StatefulWidget {
  final Color color;
  final double size;
  final VoidCallback? onTap;

  const PulseMarkerWidget({
    super.key,
    this.color = AppColors.accent,
    this.size = 60,
    this.onTap,
  });

  @override
  State<PulseMarkerWidget> createState() => _PulseMarkerWidgetState();
}

class _PulseMarkerWidgetState extends State<PulseMarkerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.7, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Onda pulsante
                Container(
                  width: widget.size * _pulseAnimation.value,
                  height: widget.size * _pulseAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.color.withOpacity(_opacityAnimation.value),
                      width: 3,
                    ),
                  ),
                ),
                // Ponto central
                Container(
                  width: widget.size * 0.35,
                  height: widget.size * 0.35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Widget para contorno de polígono animado (standalone)
class AnimatedPolygonOutline extends StatefulWidget {
  final List<LatLng> points;
  final Color color;
  final double strokeWidth;

  const AnimatedPolygonOutline({
    super.key,
    required this.points,
    this.color = AppColors.accent,
    this.strokeWidth = 3.0,
  });

  @override
  State<AnimatedPolygonOutline> createState() => _AnimatedPolygonOutlineState();
}

class _AnimatedPolygonOutlineState extends State<AnimatedPolygonOutline>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _strokeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _opacityAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _strokeAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.points.isEmpty) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return PolygonLayer(
          polygons: [
            // Área preenchida
            Polygon(
              points: widget.points,
              color: widget.color.withOpacity(0.1 * _opacityAnimation.value),
              borderColor: widget.color.withOpacity(_opacityAnimation.value),
              borderStrokeWidth: widget.strokeWidth * _strokeAnimation.value,
              isFilled: true,
            ),
            // Glow externo
            Polygon(
              points: widget.points,
              color: Colors.transparent,
              borderColor: widget.color.withOpacity(0.3 * _opacityAnimation.value),
              borderStrokeWidth: widget.strokeWidth * 2.5 * _strokeAnimation.value,
              isFilled: false,
            ),
          ],
        );
      },
    );
  }
}

/// Badge indicando highlight ativo com tempo restante
class HighlightActiveBadge extends ConsumerWidget {
  final VoidCallback? onClear;

  const HighlightActiveBadge({super.key, this.onClear});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highlight = ref.watch(mapHighlightProvider);

    if (highlight == null || highlight.isExpired) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: highlight.color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: highlight.color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            'Destacando área',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          if (onClear != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onClear,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
