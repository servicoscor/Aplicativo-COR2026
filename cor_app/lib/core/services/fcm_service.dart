import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/settings/data/settings_repository.dart';
import '../../features/favorites/presentation/controllers/favorites_controller.dart';

/// Handler para mensagens em background (top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print('📬 Mensagem em background: ${message.messageId}');
  }
}

/// Serviço de Firebase Cloud Messaging
class FCMService {
  final SettingsRepository _settingsRepository;
  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  /// Verifica se Firebase está disponível
  bool get isAvailable => _messaging != null;

  // Stream controller para notificações que devem abrir alertas
  final StreamController<String?> _alertNavigationController = StreamController<String?>.broadcast();
  Stream<String?> get onAlertNavigation => _alertNavigationController.stream;

  // Último token registrado
  String? _lastRegisteredToken;

  // Configuração de retry exponencial
  static const int _maxRetries = 3;
  static const Duration _initialRetryDelay = Duration(seconds: 2);
  int _currentRetryAttempt = 0;
  Timer? _retryTimer;

  FCMService(this._settingsRepository);

  /// Inicializa o serviço de FCM
  Future<void> initialize() async {
    // Tenta obter instância do FirebaseMessaging
    try {
      _messaging = FirebaseMessaging.instance;
    } catch (e) {
      if (kDebugMode) print('⚠️ Firebase Messaging não disponível: $e');
      // Usa token de desenvolvimento quando Firebase não está disponível
      await _registerWithDevToken();
      return;
    }

    if (_messaging == null) {
      // Usa token de desenvolvimento quando Firebase não está disponível
      await _registerWithDevToken();
      return;
    }

    // Configura handler de background
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Solicita permissão
    await _requestPermission();

    // Configura notificações locais (para foreground)
    await _setupLocalNotifications();

    // Configura listeners
    _setupMessageListeners();

    // Obtém token e registra
    await _getTokenAndRegister();

    // Listener para refresh de token
    _messaging!.onTokenRefresh.listen(_onTokenRefresh);
  }

  /// Solicita permissão de notificações
  Future<void> _requestPermission() async {
    final settings = await _messaging!.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: true, // Para alertas de emergência
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      print('📱 Status de permissão FCM: ${settings.authorizationStatus}');
    }
  }

  /// Configura notificações locais para exibição em foreground
  Future<void> _setupLocalNotifications() async {
    // Canal para Android
    const androidChannel = AndroidNotificationChannel(
      'cor_alerts',
      'Alertas COR',
      description: 'Alertas do Centro de Operações Rio',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    // Cria canal no Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // Inicializa plugin
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      ),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Handler para quando usuário toca na notificação
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      _alertNavigationController.add(payload);
    }
  }

  /// Configura listeners para mensagens FCM
  void _setupMessageListeners() {
    // Mensagem recebida com app em foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // App aberto a partir de notificação (estava em background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Verifica se app foi aberto por notificação (estava terminado)
    _checkInitialMessage();
  }

  /// Processa mensagem em foreground
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      print('📬 Mensagem em foreground: ${message.notification?.title}');
    }

    final notification = message.notification;
    if (notification == null) return;

    // Exibe notificação local
    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'cor_alerts',
          'Alertas COR',
          channelDescription: 'Alertas do Centro de Operações Rio',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF3B82F6),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data['alert_id'],
    );
  }

  /// App foi aberto por notificação (estava em background)
  void _handleMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) {
      print('📬 App aberto por notificação: ${message.data}');
    }

    final alertId = message.data['alert_id'];
    if (alertId != null) {
      _alertNavigationController.add(alertId);
    }
  }

  /// Verifica se app foi aberto por notificação (estava terminado)
  Future<void> _checkInitialMessage() async {
    final message = await _messaging!.getInitialMessage();
    if (message != null) {
      if (kDebugMode) {
        print('📬 App iniciado por notificação: ${message.data}');
      }

      final alertId = message.data['alert_id'];
      if (alertId != null) {
        // Pequeno delay para garantir que o app está pronto
        Future.delayed(const Duration(milliseconds: 500), () {
          _alertNavigationController.add(alertId);
        });
      }
    }
  }

  /// Registra com token de desenvolvimento (quando Firebase não está disponível)
  Future<void> _registerWithDevToken() async {
    try {
      final devToken = await _settingsRepository.getOrCreateDevToken();
      if (kDebugMode) {
        print('🔧 Usando token de desenvolvimento: $devToken');
      }
      await _registerDevice(devToken);
    } catch (e) {
      if (kDebugMode) print('❌ Erro ao registrar com token de dev: $e');
    }
  }

  /// Obtém token FCM e registra dispositivo
  Future<void> _getTokenAndRegister() async {
    if (_messaging == null) return;

    try {
      // Obtém token
      String? token;

      if (Platform.isIOS) {
        // iOS: primeiro obtém APNS token
        final apnsToken = await _messaging!.getAPNSToken();
        if (apnsToken != null) {
          token = await _messaging!.getToken();
        }
      } else {
        token = await _messaging!.getToken();
      }

      if (token == null) {
        if (kDebugMode) print('⚠️ Não foi possível obter token FCM, usando token de dev');
        await _registerWithDevToken();
        return;
      }

      // Verifica se token mudou
      final savedToken = _settingsRepository.pushToken;
      if (savedToken == token && _lastRegisteredToken == token) {
        if (kDebugMode) print('✅ Token já registrado, pulando...');
        return;
      }

      await _registerDevice(token);
    } catch (e) {
      if (kDebugMode) print('❌ Erro ao obter/registrar token: $e');
    }
  }

  /// Registra dispositivo no backend com retry exponencial
  Future<void> _registerDevice(String token, {List<String>? neighborhoods}) async {
    // Validação: só registra se tiver token válido
    if (token.isEmpty) {
      if (kDebugMode) print('⚠️ Token vazio, ignorando registro');
      return;
    }

    // Cancela retry pendente se houver
    _retryTimer?.cancel();
    _currentRetryAttempt = 0;

    await _attemptRegister(token, neighborhoods: neighborhoods);
  }

  /// Tenta registrar com retry exponencial em caso de falha
  Future<void> _attemptRegister(String token, {List<String>? neighborhoods}) async {
    try {
      final device = await _settingsRepository.registerDevice(
        pushToken: token,
        neighborhoods: neighborhoods,
      );

      // Sucesso - reset retry counter
      _currentRetryAttempt = 0;

      if (device != null) {
        // Salva token e ID
        await _settingsRepository.savePushToken(token);
        await _settingsRepository.saveDeviceId(device.id);
        _lastRegisteredToken = token;

        if (kDebugMode) {
          print('✅ Device registrado: ${device.id}');
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erro ao registrar device (tentativa ${_currentRetryAttempt + 1}): $e');

      // Retry exponencial se não atingiu máximo
      if (_currentRetryAttempt < _maxRetries) {
        _currentRetryAttempt++;
        final delay = _initialRetryDelay * (1 << (_currentRetryAttempt - 1)); // 2s, 4s, 8s

        if (kDebugMode) {
          print('🔄 Retry em ${delay.inSeconds}s (tentativa $_currentRetryAttempt/$_maxRetries)');
        }

        _retryTimer = Timer(delay, () {
          _attemptRegister(token, neighborhoods: neighborhoods);
        });
      } else {
        if (kDebugMode) {
          print('❌ Máximo de retries atingido. Backend pode estar offline.');
        }
      }
    }
  }

  /// Callback para refresh de token
  Future<void> _onTokenRefresh(String token) async {
    if (kDebugMode) print('🔄 Token FCM atualizado');
    await _registerDevice(token);
  }

  /// Re-registra dispositivo com novos bairros favoritos
  Future<void> updateNeighborhoods(List<String> neighborhoods) async {
    final token = _settingsRepository.pushToken;
    if (token == null) return;

    await _registerDevice(token, neighborhoods: neighborhoods);
  }

  /// Atualiza localização do dispositivo
  Future<void> updateLocation(double latitude, double longitude) async {
    try {
      await _settingsRepository.updateDeviceLocation(
        latitude: latitude,
        longitude: longitude,
      );
      if (kDebugMode) {
        print('📍 Localização atualizada: $latitude, $longitude');
      }
    } catch (e) {
      if (kDebugMode) print('❌ Erro ao atualizar localização: $e');
    }
  }

  /// Limpa recursos
  void dispose() {
    _retryTimer?.cancel();
    _alertNavigationController.close();
  }
}

/// Provider do FCM Service
final fcmServiceProvider = Provider<FCMService>((ref) {
  final settingsRepo = ref.watch(settingsRepositoryProvider);
  return FCMService(settingsRepo);
});

/// Provider para navegação de alertas via notificação
final alertNavigationProvider = StreamProvider<String?>((ref) {
  final fcmService = ref.watch(fcmServiceProvider);
  return fcmService.onAlertNavigation;
});
