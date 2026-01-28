import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/models/models.dart';
import '../../../../main.dart' show firebaseAvailable;
import '../../data/settings_repository.dart';

/// Status de diagnóstico do app
class DiagnosticStatus {
  final bool firebaseOk;
  final bool hasFcmToken;
  final String? fcmTokenPreview;
  final DateTime? lastRegisterTimestamp;
  final bool lastRegisterSuccess;

  const DiagnosticStatus({
    this.firebaseOk = false,
    this.hasFcmToken = false,
    this.fcmTokenPreview,
    this.lastRegisterTimestamp,
    this.lastRegisterSuccess = false,
  });

  DiagnosticStatus copyWith({
    bool? firebaseOk,
    bool? hasFcmToken,
    String? fcmTokenPreview,
    DateTime? lastRegisterTimestamp,
    bool? lastRegisterSuccess,
  }) {
    return DiagnosticStatus(
      firebaseOk: firebaseOk ?? this.firebaseOk,
      hasFcmToken: hasFcmToken ?? this.hasFcmToken,
      fcmTokenPreview: fcmTokenPreview ?? this.fcmTokenPreview,
      lastRegisterTimestamp: lastRegisterTimestamp ?? this.lastRegisterTimestamp,
      lastRegisterSuccess: lastRegisterSuccess ?? this.lastRegisterSuccess,
    );
  }
}

/// Resultado do teste de health
class HealthTestResult {
  final bool success;
  final HealthResponse? response;
  final String? error;
  final int? latencyMs;

  HealthTestResult({
    required this.success,
    this.response,
    this.error,
    this.latencyMs,
  });
}

/// Estado da tela de configurações
class SettingsState {
  final String baseUrl;
  final bool isEditingUrl;
  final String editingUrl;
  final bool isTesting;
  final HealthTestResult? healthResult;
  final bool locationPermissionGranted;
  final bool locationEnabled;
  final bool notificationPermissionGranted;
  final bool notificationsEnabled;
  final Device? deviceInfo;
  final bool isLoadingDevice;
  final DiagnosticStatus diagnostic;

  const SettingsState({
    this.baseUrl = '',
    this.isEditingUrl = false,
    this.editingUrl = '',
    this.isTesting = false,
    this.healthResult,
    this.locationPermissionGranted = false,
    this.locationEnabled = true,
    this.notificationPermissionGranted = false,
    this.notificationsEnabled = true,
    this.deviceInfo,
    this.isLoadingDevice = false,
    this.diagnostic = const DiagnosticStatus(),
  });

  SettingsState copyWith({
    String? baseUrl,
    bool? isEditingUrl,
    String? editingUrl,
    bool? isTesting,
    HealthTestResult? healthResult,
    bool clearHealthResult = false,
    bool? locationPermissionGranted,
    bool? locationEnabled,
    bool? notificationPermissionGranted,
    bool? notificationsEnabled,
    Device? deviceInfo,
    bool? isLoadingDevice,
    DiagnosticStatus? diagnostic,
  }) {
    return SettingsState(
      baseUrl: baseUrl ?? this.baseUrl,
      isEditingUrl: isEditingUrl ?? this.isEditingUrl,
      editingUrl: editingUrl ?? this.editingUrl,
      isTesting: isTesting ?? this.isTesting,
      healthResult: clearHealthResult ? null : (healthResult ?? this.healthResult),
      locationPermissionGranted: locationPermissionGranted ?? this.locationPermissionGranted,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      notificationPermissionGranted: notificationPermissionGranted ?? this.notificationPermissionGranted,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      isLoadingDevice: isLoadingDevice ?? this.isLoadingDevice,
      diagnostic: diagnostic ?? this.diagnostic,
    );
  }
}

/// Controller de configurações
class SettingsController extends StateNotifier<SettingsState> {
  final SettingsRepository _repository;
  final AppConfig _config;
  final Ref _ref;

  SettingsController(this._repository, this._config, this._ref)
      : super(const SettingsState()) {
    _init();
  }

  Future<void> _init() async {
    // Carrega configurações iniciais
    state = state.copyWith(
      baseUrl: _config.baseUrl,
      locationEnabled: _repository.isLocationEnabled,
      notificationsEnabled: _repository.areNotificationsEnabled,
    );

    // Verifica permissões
    await checkPermissions();

    // Carrega diagnóstico
    loadDiagnostic();

    // Carrega info do device
    await loadDeviceInfo();
  }

  /// Verifica permissões de localização e notificações
  Future<void> checkPermissions() async {
    // Localização
    final locationStatus = await Permission.location.status;
    final locationServiceEnabled = await Geolocator.isLocationServiceEnabled();

    // Notificações
    final notificationStatus = await Permission.notification.status;

    state = state.copyWith(
      locationPermissionGranted: locationStatus.isGranted && locationServiceEnabled,
      notificationPermissionGranted: notificationStatus.isGranted,
    );
  }

  /// Carrega status de diagnóstico
  void loadDiagnostic() {
    final token = _repository.pushToken;
    String? tokenPreview;

    if (token != null && token.length > 20) {
      tokenPreview = '${token.substring(0, 10)}...${token.substring(token.length - 10)}';
    } else if (token != null) {
      tokenPreview = token;
    }

    state = state.copyWith(
      diagnostic: DiagnosticStatus(
        firebaseOk: firebaseAvailable,
        hasFcmToken: _repository.hasFcmToken,
        fcmTokenPreview: tokenPreview,
        lastRegisterTimestamp: _repository.lastRegisterTimestamp,
        lastRegisterSuccess: _repository.lastRegisterSuccess,
      ),
    );
  }

  /// Carrega informações do dispositivo
  Future<void> loadDeviceInfo() async {
    state = state.copyWith(isLoadingDevice: true);

    try {
      final device = await _repository.getDeviceInfo();
      state = state.copyWith(
        deviceInfo: device,
        isLoadingDevice: false,
      );
    } catch (e) {
      if (kDebugMode) print('Erro ao carregar device info: $e');
      state = state.copyWith(isLoadingDevice: false);
    }
  }

  /// Inicia edição de URL
  void startEditingUrl() {
    state = state.copyWith(
      isEditingUrl: true,
      editingUrl: state.baseUrl,
    );
  }

  /// Atualiza URL em edição
  void updateEditingUrl(String url) {
    state = state.copyWith(editingUrl: url);
  }

  /// Cancela edição de URL
  void cancelEditingUrl() {
    state = state.copyWith(
      isEditingUrl: false,
      editingUrl: '',
    );
  }

  /// Salva nova URL
  Future<bool> saveUrl() async {
    final url = state.editingUrl.trim();

    // Validação básica
    if (url.isEmpty) return false;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return false;
    }

    try {
      await _config.setBaseUrl(url);
      _ref.read(baseUrlProvider.notifier).state = url;

      state = state.copyWith(
        baseUrl: url,
        isEditingUrl: false,
        editingUrl: '',
        clearHealthResult: true,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Reseta URL para padrão
  Future<void> resetUrl() async {
    await _config.resetBaseUrl();
    final defaultUrl = AppConfig.defaultBaseUrl;
    _ref.read(baseUrlProvider.notifier).state = defaultUrl;

    state = state.copyWith(
      baseUrl: defaultUrl,
      isEditingUrl: false,
      editingUrl: '',
      clearHealthResult: true,
    );
  }

  /// Testa conexão com a API
  Future<void> testHealth() async {
    state = state.copyWith(isTesting: true, clearHealthResult: true);

    final stopwatch = Stopwatch()..start();

    try {
      final response = await _repository.checkHealth();
      stopwatch.stop();

      state = state.copyWith(
        isTesting: false,
        healthResult: HealthTestResult(
          success: true,
          response: response,
          latencyMs: stopwatch.elapsedMilliseconds,
        ),
      );
    } catch (e) {
      stopwatch.stop();

      state = state.copyWith(
        isTesting: false,
        healthResult: HealthTestResult(
          success: false,
          error: e is AppException ? e.message : 'Erro de conexão',
          latencyMs: stopwatch.elapsedMilliseconds,
        ),
      );
    }
  }

  /// Solicita permissão de localização
  Future<void> requestLocationPermission() async {
    // Primeiro verifica se o serviço está habilitado
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    // Solicita permissão
    final status = await Permission.location.request();

    state = state.copyWith(
      locationPermissionGranted: status.isGranted,
    );
  }

  /// Solicita permissão de notificações
  Future<void> requestNotificationPermission() async {
    final status = await Permission.notification.request();

    state = state.copyWith(
      notificationPermissionGranted: status.isGranted,
    );
  }

  /// Toggle localização habilitada
  Future<void> toggleLocationEnabled(bool enabled) async {
    await _repository.setLocationEnabled(enabled);
    state = state.copyWith(locationEnabled: enabled);
  }

  /// Toggle notificações habilitadas
  Future<void> toggleNotificationsEnabled(bool enabled) async {
    await _repository.setNotificationsEnabled(enabled);
    state = state.copyWith(notificationsEnabled: enabled);
  }
}

/// Provider do controller de configurações
final settingsControllerProvider = StateNotifierProvider<SettingsController, SettingsState>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  final config = ref.watch(appConfigProvider);
  return SettingsController(repository, config, ref);
});
