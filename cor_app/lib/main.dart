import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';

import 'core/config/app_config.dart';
import 'core/config/locale_config.dart';
import 'core/theme/app_theme.dart';
import 'core/services/fcm_service.dart';
import 'core/services/location_service.dart';
import 'core/services/cache_service.dart';
import 'app_shell.dart';

/// Flag global para verificar se Firebase está disponível
bool firebaseAvailable = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configura orientação (apenas portrait)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Configura estilo da status bar
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Inicializa locale pt_BR
  await initializeDateFormatting('pt_BR', null);

  // Inicializa SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Inicializa CacheService (Hive)
  final cacheService = CacheService();
  try {
    await cacheService.initialize();
    if (kDebugMode) print('✅ CacheService inicializado com sucesso');
  } catch (e) {
    if (kDebugMode) print('⚠️ Erro ao inicializar CacheService: $e');
  }

  // Inicializa Firebase (com tratamento de erro para desenvolvimento)
  try {
    await Firebase.initializeApp();
    firebaseAvailable = true;
    if (kDebugMode) print('✅ Firebase inicializado com sucesso');
  } catch (e) {
    firebaseAvailable = false;
    if (kDebugMode) print('⚠️ Firebase não disponível: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        // Injeta SharedPreferences
        sharedPreferencesProvider.overrideWithValue(prefs),
        // Injeta CacheService inicializado
        cacheServiceProvider.overrideWithValue(cacheService),
      ],
      child: const CorApp(),
    ),
  );
}

class CorApp extends ConsumerStatefulWidget {
  const CorApp({super.key});

  @override
  ConsumerState<CorApp> createState() => _CorAppState();
}

class _CorAppState extends ConsumerState<CorApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Inicializa serviços
    _initializeServices();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initializeServices() async {
    // Inicializa FCM (sempre - usa token de dev se Firebase não disponível)
    try {
      final fcmService = ref.read(fcmServiceProvider);
      await fcmService.initialize();
    } catch (e) {
      if (kDebugMode) print('⚠️ Erro ao inicializar FCM: $e');
    }

    // Inicializa Location Service
    final locationService = ref.read(locationServiceProvider);
    await locationService.initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Atualiza localização quando app volta ao foreground
    if (state == AppLifecycleState.resumed) {
      final locationService = ref.read(locationServiceProvider);
      locationService.updateLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      locale: locale,
      supportedLocales: supportedAppLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      home: const AppShell(),
    );
  }
}
