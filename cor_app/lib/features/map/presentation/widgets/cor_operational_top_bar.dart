import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/models/operational_status_model.dart';
import '../../../../core/services/status_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../controllers/map_controller.dart';

/// Barra superior operacional do COR
/// Exibe logo, estágio da cidade e nível de calor
class CorOperationalTopBar extends ConsumerWidget {
  const CorOperationalTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusState = ref.watch(statusControllerProvider);
    final status = statusState.status;
    final mapState = ref.watch(mapControllerProvider);
    final isLoading = mapState.isLoading || statusState.isLoading;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: AppColors.divider,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Linha principal: Logo + Badges
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  // Logo do COR - Botão de atualizar
                  _CorLogoButton(
                    isLoading: isLoading,
                    onTap: () => _refreshAllData(ref),
                  ),

                  const Spacer(),

                  // Badges de status
                  if (status != null) ...[
                    // Badge Estágio da Cidade
                    _StageBadge(
                      stage: status.cityStage,
                      onTap: () => _showStageDetails(context, status.cityStage),
                    ),

                    const SizedBox(width: 8),

                    // Badge Nível de Calor
                    _HeatBadge(
                      level: status.heatLevel,
                      onTap: () => _showHeatDetails(context, status.heatLevel),
                    ),
                  ] else if (statusState.isLoading) ...[
                    // Shimmer loading
                    _buildLoadingBadge(),
                    const SizedBox(width: 8),
                    _buildLoadingBadge(),
                  ],
                ],
              ),
            ),

            // Linha de atualização
            if (status != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.5),
                ),
                child: Text(
                  status.updatedAgo,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Atualiza todos os dados do app
  void _refreshAllData(WidgetRef ref) {
    // Feedback háptico
    HapticFeedback.mediumImpact();

    // Atualiza dados do mapa (incidentes, radar, pluviômetros, clima, etc)
    ref.read(mapControllerProvider.notifier).loadAllData();

    // Atualiza status operacional (estágio, calor)
    ref.read(statusControllerProvider.notifier).refresh();
  }

  Widget _buildLoadingBadge() {
    return Container(
      width: 80,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  void _showStageDetails(BuildContext context, CityStage stage) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _StageDetailSheet(stage: stage),
    );
  }

  void _showHeatDetails(BuildContext context, HeatLevel level) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _HeatDetailSheet(level: level),
    );
  }
}

/// Badge do Estágio da Cidade - Usa imagem se disponível
class _StageBadge extends StatefulWidget {
  final CityStage stage;
  final VoidCallback onTap;

  const _StageBadge({
    required this.stage,
    required this.onTap,
  });

  @override
  State<_StageBadge> createState() => _StageBadgeState();
}

class _StageBadgeState extends State<_StageBadge> {
  bool _imageExists = false;

  @override
  void initState() {
    super.initState();
    _checkImageExists();
  }

  @override
  void didUpdateWidget(_StageBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stage != widget.stage) {
      _checkImageExists();
    }
  }

  Future<void> _checkImageExists() async {
    try {
      await rootBundle.load(widget.stage.imagePath);
      if (mounted) setState(() => _imageExists = true);
    } catch (_) {
      if (mounted) setState(() => _imageExists = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: _imageExists
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                widget.stage.imagePath,
                height: 36,
                fit: BoxFit.contain,
              ),
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: widget.stage.color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: widget.stage.color.withOpacity(0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.stage.icon,
                    size: 16,
                    color: widget.stage.textColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.stage.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: widget.stage.textColor,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Badge do Nível de Calor - Usa imagem se disponível
class _HeatBadge extends StatefulWidget {
  final HeatLevel level;
  final VoidCallback onTap;

  const _HeatBadge({
    required this.level,
    required this.onTap,
  });

  @override
  State<_HeatBadge> createState() => _HeatBadgeState();
}

class _HeatBadgeState extends State<_HeatBadge> {
  bool _imageExists = false;

  @override
  void initState() {
    super.initState();
    _checkImageExists();
  }

  @override
  void didUpdateWidget(_HeatBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level != widget.level) {
      _checkImageExists();
    }
  }

  Future<void> _checkImageExists() async {
    try {
      await rootBundle.load(widget.level.imagePath);
      if (mounted) setState(() => _imageExists = true);
    } catch (_) {
      if (mounted) setState(() => _imageExists = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: _imageExists
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                widget.level.imagePath,
                height: 36,
                fit: BoxFit.contain,
              ),
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: widget.level.color,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: widget.level.color.withOpacity(0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.level.icon,
                    size: 16,
                    color: widget.level.textColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.level.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: widget.level.textColor,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Bottom Sheet com detalhes do Estágio da Cidade
class _StageDetailSheet extends StatelessWidget {
  final CityStage stage;

  const _StageDetailSheet({required this.stage});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header com cor do estágio
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: stage.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: stage.color.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: stage.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    stage.icon,
                    color: stage.textColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ESTÁGIO DA CIDADE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stage.fullLabel,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: stage.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Seções de informação
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoSection(
                  title: 'Quando é ativado',
                  icon: LucideIcons.helpCircle,
                  content: stage.whenActivated,
                ),
                const SizedBox(height: 16),
                _InfoSection(
                  title: 'Impacto na cidade',
                  icon: LucideIcons.alertTriangle,
                  content: stage.impact,
                ),
              ],
            ),
          ),

          // Todos os estágios
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NÍVEIS DE ESTÁGIO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: CityStage.values.map((s) {
                    final isActive = s == stage;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isActive ? s.color : s.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: isActive
                            ? null
                            : Border.all(color: s.color.withOpacity(0.3)),
                      ),
                      child: Text(
                        s.fullLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                          color: isActive ? s.textColor : s.color,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Safe area bottom
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

/// Bottom Sheet com detalhes do Nível de Calor
class _HeatDetailSheet extends StatelessWidget {
  final HeatLevel level;

  const _HeatDetailSheet({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header com cor do nível
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: level.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: level.color.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: level.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    level.icon,
                    color: level.textColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NÍVEL DE CALOR',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        level.fullLabel,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: level.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        level.temperatureRange,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Seções de informação
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoSection(
                  title: 'Quando é ativado',
                  icon: LucideIcons.helpCircle,
                  content: level.whenActivated,
                ),
                const SizedBox(height: 16),
                _InfoSection(
                  title: 'Ações recomendadas',
                  icon: LucideIcons.checkCircle,
                  content: level.recommendedActions,
                ),
              ],
            ),
          ),

          // Todos os níveis
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NÍVEIS DE CALOR',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                ...HeatLevel.values.map((l) {
                  final isActive = l == level;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: l.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l.fullLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                            color: isActive ? l.color : AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          l.temperatureRange,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          // Safe area bottom
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

/// Seção de informação genérica
class _InfoSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final String content;

  const _InfoSection({
    required this.title,
    required this.icon,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Botão com logo do COR que atualiza o app
class _CorLogoButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onTap;

  const _CorLogoButton({
    required this.isLoading,
    required this.onTap,
  });

  @override
  State<_CorLogoButton> createState() => _CorLogoButtonState();
}

class _CorLogoButtonState extends State<_CorLogoButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  bool _logoExists = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _checkLogoExists();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_CorLogoButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _rotationController.repeat();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _rotationController.stop();
      _rotationController.reset();
    }
  }

  Future<void> _checkLogoExists() async {
    try {
      await rootBundle.load('assets/images/logo_cor.png');
      if (mounted) setState(() => _logoExists = true);
    } catch (_) {
      // Logo não existe, usa fallback
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isLoading ? null : widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: widget.isLoading
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Logo grande
            AnimatedBuilder(
              animation: _rotationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: widget.isLoading ? _rotationController.value * 2 * 3.14159 : 0,
                  child: child,
                );
              },
              child: _logoExists
                  ? Image.asset(
                      'assets/images/logo_cor.png',
                      height: 36,
                      fit: BoxFit.contain,
                    )
                  : Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        widget.isLoading ? LucideIcons.refreshCw : LucideIcons.radio,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
            ),
            // Indicador de loading sobreposto
            if (widget.isLoading)
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
