import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/models/camera_model.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/camera_marker.dart';

/// Tela de player de câmera em fullscreen (landscape)
class CameraPlayerScreen extends StatefulWidget {
  final Camera camera;

  const CameraPlayerScreen({
    super.key,
    required this.camera,
  });

  @override
  State<CameraPlayerScreen> createState() => _CameraPlayerScreenState();
}

class _CameraPlayerScreenState extends State<CameraPlayerScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _showInfo = true;
  static const double _cameraCssScale = 0.08;
  static const double _viewScale = 0.97;

  @override
  void initState() {
    super.initState();
    _initWebView();
    _forceLandscape();
    _hideInfoAfterDelay();
  }

  void _forceLandscape() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
      overlays: [],
    );
  }

  void _restoreOrientation() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: SystemUiOverlay.values,
    );
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            }
          },
          onPageFinished: (url) {
            if (mounted) {
              setState(() => _isLoading = false);
              _injectFullscreenStyles();
            }
          },
          onWebResourceError: (error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
                _errorMessage = error.description;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.camera.streamUrl));

    final platformController = _controller.platform;
    if (platformController is AndroidWebViewController) {
      platformController.setMediaPlaybackRequiresUserGesture(false);
      platformController.enableZoom(false);
      platformController.setTextZoom(100);
      platformController.setUseWideViewPort(true);
    }
  }

  void _injectFullscreenStyles() {
    final scale = _cameraCssScale.toStringAsFixed(2);
    _controller.runJavaScript('''
      (function() {
        document.body.style.margin = '0';
        document.body.style.padding = '0';
        document.body.style.overflow = 'hidden';
        document.body.style.backgroundColor = 'black';

        var video = document.querySelector('video');
        if (video) {
          video.style.width = '100vw';
          video.style.height = '100vh';
          video.style.objectFit = 'contain';
          video.style.position = 'fixed';
          video.style.top = '0';
          video.style.left = '0';
        }

        var iframe = document.querySelector('iframe');
        if (iframe) {
          iframe.style.width = '100vw';
          iframe.style.height = '100vh';
          iframe.style.position = 'fixed';
          iframe.style.top = '0';
          iframe.style.left = '0';
          iframe.style.border = 'none';
        }
      })();
    ''');
  }

  void _hideInfoAfterDelay() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _showInfo) {
        setState(() => _showInfo = false);
      }
    });
  }

  void _toggleInfo() {
    setState(() => _showInfo = !_showInfo);
    if (_showInfo) {
      _hideInfoAfterDelay();
    }
  }

  @override
  void dispose() {
    _restoreOrientation();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = CameraColors.colorForType(widget.camera.type);

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleInfo,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // WebView com o stream
            if (!_hasError)
              Positioned.fill(
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.center,
                    child: Transform.scale(
                      scale: _viewScale,
                      child: SizedBox.expand(
                        child: WebViewWidget(controller: _controller),
                      ),
                    ),
                  ),
                ),
              ),

            // Tela de erro
            if (_hasError)
              _buildErrorView(),

            // BOTÃO FECHAR - SEMPRE VISÍVEL
            Positioned(
              top: 16,
              left: 16,
              child: SafeArea(
                child: _ExitButton(
                  onTap: () => Navigator.of(context).pop(),
                ),
              ),
            ),

            // Info da câmera (aparece/desaparece com tap)
            AnimatedOpacity(
              opacity: _showInfo ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_showInfo,
                child: Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                        stops: const [0.0, 0.15, 0.85, 1.0],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        children: [
                          // Top bar - info da câmera (ao lado do botão fechar)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: AppSpacing.md,
                              left: 80, // Espaço para o botão fechar
                              right: AppSpacing.md,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.camera.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 3,
                                            ),
                                            decoration: BoxDecoration(
                                              color: color.withValues(alpha: 0.3),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              widget.camera.isFixed ? 'FIXA' : 'MÓVEL',
                                              style: TextStyle(
                                                color: color,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: widget.camera.isOnline
                                                  ? AppColors.success
                                                  : AppColors.textMuted,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            widget.camera.isOnline ? 'AO VIVO' : 'OFFLINE',
                                            style: TextStyle(
                                              color: widget.camera.isOnline
                                                  ? AppColors.success
                                                  : AppColors.textMuted,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Botão reload
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isLoading = true;
                                      _hasError = false;
                                    });
                                    _controller.reload();
                                  },
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      LucideIcons.refreshCw,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Bottom bar
                          Padding(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  LucideIcons.hash,
                                  color: Colors.white.withValues(alpha: 0.5),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Código: ${widget.camera.code}',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            LucideIcons.videoOff,
            color: AppColors.textMuted,
            size: 64,
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Erro ao carregar stream',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(LucideIcons.arrowLeft, size: 18),
                label: Text(AppLocalizations.of(context)!.back),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _hasError = false;
                  });
                  _controller.reload();
                },
                icon: const Icon(LucideIcons.refreshCw, size: 18),
                label: Text(AppLocalizations.of(context)!.retry),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Botão de sair - sempre visível
class _ExitButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ExitButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.7),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Icon(
          LucideIcons.x,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}
