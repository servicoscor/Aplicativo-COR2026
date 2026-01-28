import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/radar_model.dart';
import '../../../../core/widgets/data_age_badge.dart';

/// Widget de controle de timeline do radar - versão minimalista
/// Apenas mostra timestamp e indicador AO VIVO
/// O radar roda automaticamente quando habilitado nas camadas
class RadarTimelineControl extends StatelessWidget {
  final RadarResponse radar;
  final int currentIndex;
  final bool isPlaying;
  final bool isLiveMode;
  final ValueChanged<int>? onIndexChanged;
  final VoidCallback? onPlayPause;
  final VoidCallback? onLiveModeToggle;
  final int? dataAgeMinutes;

  const RadarTimelineControl({
    super.key,
    required this.radar,
    required this.currentIndex,
    required this.isPlaying,
    this.isLiveMode = false,
    this.onIndexChanged,
    this.onPlayPause,
    this.onLiveModeToggle,
    this.dataAgeMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final snapshots = radar.allSnapshots;
    if (snapshots.isEmpty) return const SizedBox.shrink();

    final currentSnapshot = snapshots[currentIndex.clamp(0, snapshots.length - 1)];
    final timeFormat = DateFormat('HH:mm', 'pt_BR');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          // Indicador compacto de radar
          _CompactRadarIndicator(
            timestamp: currentSnapshot.timestamp,
            isLive: isLiveMode && isPlaying,
            frameIndex: currentIndex,
            totalFrames: snapshots.length,
          ),
          const Spacer(),
          // Timeline minimalista
          if (snapshots.length > 1)
            Text(
              '${timeFormat.format(snapshots.first.timestamp)} - ${timeFormat.format(snapshots.last.timestamp)}',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}

/// Indicador compacto de radar com timestamp e ponto pulsante
class _CompactRadarIndicator extends StatefulWidget {
  final DateTime timestamp;
  final bool isLive;
  final int frameIndex;
  final int totalFrames;

  const _CompactRadarIndicator({
    required this.timestamp,
    required this.isLive,
    required this.frameIndex,
    required this.totalFrames,
  });

  @override
  State<_CompactRadarIndicator> createState() => _CompactRadarIndicatorState();
}

class _CompactRadarIndicatorState extends State<_CompactRadarIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm', 'pt_BR');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isLive
              ? Colors.red.withOpacity(0.4)
              : AppColors.divider,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ponto pulsante (vermelho se ao vivo, azul se parado)
          if (widget.isLive)
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(_animation.value),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(_animation.value * 0.5),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                );
              },
            )
          else
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 8),
          // Timestamp
          Text(
            timeFormat.format(widget.timestamp),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          // Frame indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: (widget.isLive ? Colors.red : AppColors.primary).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${widget.frameIndex + 1}/${widget.totalFrames}',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: widget.isLive ? Colors.red : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget de timestamp flutuante no mapa
class RadarTimestampOverlay extends StatelessWidget {
  final DateTime timestamp;
  final int? dataAgeMinutes;
  final bool isStale;

  const RadarTimestampOverlay({
    super.key,
    required this.timestamp,
    this.dataAgeMinutes,
    this.isStale = false,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm', 'pt_BR');
    final dateFormat = DateFormat('dd/MM', 'pt_BR');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.radio,
            size: 14,
            color: AppColors.primary,
          ),
          const SizedBox(width: 6),
          Text(
            '${dateFormat.format(timestamp)} ${timeFormat.format(timestamp)}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (dataAgeMinutes != null || isStale) ...[
            const SizedBox(width: 8),
            DataAgeBadge.fromAge(
              ageMinutes: dataAgeMinutes,
              isStale: isStale,
              isOutdated: (dataAgeMinutes ?? 0) > 10,
              compact: true,
              showIcon: false,
            ),
          ],
        ],
      ),
    );
  }
}

/// Provider/Manager para estado da animação do radar
class RadarAnimationManager {
  final RadarResponse radar;
  final void Function(int) onFrameChange;

  Timer? _animationTimer;
  int _currentIndex = 0;
  bool _isPlaying = false;

  // Configuração de animação
  static const Duration frameDelay = Duration(milliseconds: 400);

  RadarAnimationManager({
    required this.radar,
    required this.onFrameChange,
  }) {
    // Começa no frame mais recente
    _currentIndex = radar.allSnapshots.length - 1;
  }

  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;

  /// Inicia ou pausa a animação
  void togglePlayPause() {
    if (_isPlaying) {
      pause();
    } else {
      play();
    }
  }

  /// Inicia a animação
  void play() {
    if (radar.allSnapshots.length <= 1) return;

    _isPlaying = true;
    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(frameDelay, (_) {
      _currentIndex = (_currentIndex + 1) % radar.allSnapshots.length;
      onFrameChange(_currentIndex);
    });
  }

  /// Pausa a animação
  void pause() {
    _isPlaying = false;
    _animationTimer?.cancel();
  }

  /// Define o índice manualmente
  void setIndex(int index) {
    _currentIndex = index.clamp(0, radar.allSnapshots.length - 1);
    onFrameChange(_currentIndex);
  }

  /// Limpa recursos
  void dispose() {
    _animationTimer?.cancel();
  }
}
