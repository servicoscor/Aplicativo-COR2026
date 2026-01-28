import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/models/camera_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../screens/camera_player_screen.dart';
import 'camera_marker.dart';

/// Bottom sheet com detalhes da câmera
class CameraBottomSheet extends StatelessWidget {
  final Camera camera;
  final VoidCallback? onViewOnMap;

  const CameraBottomSheet({
    super.key,
    required this.camera,
    this.onViewOnMap,
  });

  @override
  Widget build(BuildContext context) {
    final color = CameraColors.colorForType(camera.type);

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
              color: AppColors.textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header com ícone e tipo
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        camera.isFixed ? LucideIcons.video : LucideIcons.videotape,
                        color: color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            camera.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  camera.isFixed ? 'Fixa' : 'Móvel',
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (camera.isOnline)
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.success,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Online',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.success,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppColors.textMuted,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Offline',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Informações da câmera
                _InfoTile(
                  icon: LucideIcons.hash,
                  label: 'Código',
                  value: camera.code,
                ),
                const SizedBox(height: AppSpacing.sm),
                _InfoTile(
                  icon: LucideIcons.mapPin,
                  label: 'Coordenadas',
                  value:
                      '${camera.location.latitude.toStringAsFixed(4)}, ${camera.location.longitude.toStringAsFixed(4)}',
                ),

                const SizedBox(height: AppSpacing.xl),

                // Botões de ação
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onViewOnMap,
                        icon: const Icon(LucideIcons.mapPin, size: 18),
                        label: const Text('Ver no mapa'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.divider),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: camera.isOnline ? () => _openPlayer(context) : null,
                        icon: const Icon(LucideIcons.play, size: 18),
                        label: const Text('Assistir'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.textMuted.withValues(alpha: 0.3),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),

                // Padding inferior para safe area
                SizedBox(height: MediaQuery.of(context).padding.bottom + AppSpacing.md),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openPlayer(BuildContext context) {
    // Fecha o bottom sheet primeiro
    Navigator.of(context).pop();

    // Navega para o player fullscreen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CameraPlayerScreen(camera: camera),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
