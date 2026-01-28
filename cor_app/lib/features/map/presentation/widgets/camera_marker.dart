import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/models/camera_model.dart';
import '../../../../core/theme/app_theme.dart';

/// Cores das câmeras
class CameraColors {
  /// Azul para câmeras fixas
  static const Color fixed = Color(0xFF2196F3);
  static const Color fixedDark = Color(0xFF1565C0);

  /// Verde para câmeras móveis
  static const Color mobile = Color(0xFF4CAF50);
  static const Color mobileDark = Color(0xFF2E7D32);

  /// Retorna a cor baseada no tipo
  static Color colorForType(CameraType type) {
    return type == CameraType.fixed ? fixed : mobile;
  }

  /// Retorna a cor escura baseada no tipo
  static Color darkColorForType(CameraType type) {
    return type == CameraType.fixed ? fixedDark : mobileDark;
  }
}

/// Widget de marcador de câmera no mapa
class CameraMarkerWidget extends StatelessWidget {
  final Camera camera;
  final VoidCallback? onTap;

  const CameraMarkerWidget({
    super.key,
    required this.camera,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = CameraColors.colorForType(camera.type);
    final darkColor = CameraColors.darkColorForType(camera.type);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: darkColor.withOpacity(0.4),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            camera.isFixed ? LucideIcons.video : LucideIcons.videotape,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }
}

/// Widget de cluster de câmeras
class CameraClusterMarker extends StatelessWidget {
  final int count;
  final int fixedCount;
  final int mobileCount;

  const CameraClusterMarker({
    super.key,
    required this.count,
    this.fixedCount = 0,
    this.mobileCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Determina a cor predominante
    Color primaryColor;
    Color secondaryColor;

    if (fixedCount > mobileCount) {
      primaryColor = CameraColors.fixed;
      secondaryColor = CameraColors.mobile;
    } else if (mobileCount > fixedCount) {
      primaryColor = CameraColors.mobile;
      secondaryColor = CameraColors.fixed;
    } else {
      // Mix das duas cores
      primaryColor = CameraColors.fixed;
      secondaryColor = CameraColors.mobile;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryColor, secondaryColor],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.camera,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(height: 1),
          Text(
            count.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cluster marker simples (só com contagem)
class SimpleCameraClusterMarker extends StatelessWidget {
  final int count;

  const SimpleCameraClusterMarker({
    super.key,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [CameraColors.fixed, CameraColors.mobile],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: CameraColors.fixed.withOpacity(0.3),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.video,
              color: Colors.white,
              size: 14,
            ),
            Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
