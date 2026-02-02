// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'COR.AI';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get languageSectionTitle => 'Idioma';

  @override
  String get languageLabel => 'Idioma de la app';

  @override
  String get languagePortuguese => 'Portugués (Brasil)';

  @override
  String get languageEnglish => 'Inglés';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageChinese => 'Chino (Simplificado)';

  @override
  String get navMap => 'Mapa';

  @override
  String get navCity => 'Ciudad';

  @override
  String get navNetworks => 'Redes';

  @override
  String get navFavorites => 'Favoritos';

  @override
  String get navConfig => 'Config';

  @override
  String get socialTitle => 'Redes Sociales del COR';

  @override
  String get socialXLabel => 'X (Twitter)';

  @override
  String get socialInstagramLabel => 'Instagram';

  @override
  String get socialFacebookLabel => 'Facebook';

  @override
  String get alertsTitle => 'Ciudad';

  @override
  String unreadCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# no leídos',
      one: '# no leído',
    );
    return '$_temp0';
  }

  @override
  String get filterUnread => 'No leídos';

  @override
  String get filterEmergency => 'Emergencia';

  @override
  String get filterAlert => 'Alerta';

  @override
  String get filterInfo => 'Info';

  @override
  String get clear => 'Limpiar';

  @override
  String get emptyAlertsTitle => 'Sin alertas';

  @override
  String get emptyAlertsSubtitle =>
      'No tienes alertas en este momento.\nCuando haya novedades, se te notificará.';

  @override
  String get refresh => 'Actualizar';

  @override
  String get noResultsTitle => 'Sin resultados';

  @override
  String get noResultsSubtitle =>
      'No hay alertas que coincidan con los filtros seleccionados.';

  @override
  String get clearFilters => 'Limpiar filtros';

  @override
  String get favoritesTitle => 'Mis barrios';

  @override
  String get favoritesInstruction =>
      'Agrega tus barrios favoritos para recibir alertas personalizadas, incluso cuando la ubicación no esté disponible.';

  @override
  String get favoritesSearchHint => 'Buscar barrio...';

  @override
  String get favoritesEmptyTitle => 'Sin barrios favoritos';

  @override
  String get favoritesEmptySubtitle =>
      'Usa la búsqueda de arriba para agregar barrios a tu lista de favoritos.';

  @override
  String get favoritesRemoveTitle => '¿Eliminar barrio?';

  @override
  String favoritesRemoveBody(String name) {
    return '¿Eliminar \"$name\" de tus barrios favoritos?';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get remove => 'Eliminar';

  @override
  String get appLinkError => 'No se pudo abrir el enlace de la app.';

  @override
  String get install => 'Instalar';

  @override
  String get sectionPermissions => 'Permisos';

  @override
  String get permissionLocationTitle => 'Ubicación';

  @override
  String get permissionGranted => 'Permiso concedido';

  @override
  String get permissionLocationNeeded =>
      'Permiso necesario para alertas locales';

  @override
  String get permissionNotificationsTitle => 'Notificaciones';

  @override
  String get permissionNotificationsNeeded =>
      'Permiso necesario para recibir alertas';

  @override
  String get sectionAlerts => 'Alertas';

  @override
  String get sectionServer => 'Servidor';

  @override
  String get sectionSystemStatus => 'Estado del sistema';

  @override
  String get sectionDiagnostics => 'Prueba de conexión';

  @override
  String get sectionAbout => 'Acerca de';

  @override
  String get allow => 'Permitir';

  @override
  String get neighborhoodAlertsTitle => 'Alertas por barrio';

  @override
  String get neighborhoodAlertsSubtitle =>
      'Elige los barrios en los que quieres recibir alertas';

  @override
  String get apiUrlLabel => 'URL de la API';

  @override
  String get apiUrlHint => 'http://10.0.2.2:8000';

  @override
  String get invalidUrl => 'URL inválida. Usa http:// o https://';

  @override
  String get save => 'Guardar';

  @override
  String get systemFirebase => 'Firebase';

  @override
  String get statusOk => 'OK';

  @override
  String get statusNotConfigured => 'NO CONFIGURADO';

  @override
  String get systemFcmToken => 'Token FCM';

  @override
  String get statusPresent => 'Presente';

  @override
  String get statusAbsent => 'Ausente';

  @override
  String get systemLastRegister => 'Último registro';

  @override
  String get statusSuccess => 'Éxito';

  @override
  String get statusFailure => 'Fallo';

  @override
  String get statusNever => 'Nunca';

  @override
  String get testConnectionTitle => 'Probar conexión';

  @override
  String get testConnectionSubtitle =>
      'Verifica el estado de la API /v1/health';

  @override
  String get test => 'Probar';

  @override
  String get connectionOk => 'Conexión OK';

  @override
  String get connectionFailed => 'Fallo en la conexión';

  @override
  String get statusLabel => 'Estado';

  @override
  String get versionLabel => 'Versión';

  @override
  String get databaseLabel => 'Base de datos';

  @override
  String get cacheLabel => 'Caché';

  @override
  String get registeredDeviceTitle => 'Dispositivo registrado';

  @override
  String get deviceIdLabel => 'ID';

  @override
  String get devicePlatformLabel => 'Plataforma';

  @override
  String get deviceTokenLabel => 'Token';

  @override
  String get deviceNeighborhoodsLabel => 'Barrios';

  @override
  String get aboutSubtitle => 'Centro de Operaciones de Río';

  @override
  String get developedByLabel => 'Desarrollado por';

  @override
  String get developedByValue => 'Prefeitura do Rio';

  @override
  String get timeAgoNow => 'ahora mismo';

  @override
  String timeAgoMinutes(int minutes) {
    return 'hace $minutes min';
  }

  @override
  String timeAgoHours(int hours) {
    return 'hace ${hours}h';
  }

  @override
  String timeAgoDate(String date, String time) {
    return '$date $time';
  }

  @override
  String get viewOnMap => 'Ver en el mapa';

  @override
  String get watch => 'Ver';

  @override
  String get retry => 'Reintentar';

  @override
  String get back => 'Volver';

  @override
  String get errorGenericTitle => '¡Ups! Algo salió mal';

  @override
  String get neighborhoodsSavedSuccess => '¡Barrios guardados con éxito!';

  @override
  String get neighborhoodsSavedError => 'Error al guardar barrios';

  @override
  String selectedCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# seleccionados',
      one: '# seleccionado',
    );
    return '$_temp0';
  }

  @override
  String get syncWithFavoritesTitle => 'Sincronizar con favoritos';

  @override
  String get syncWithFavoritesSubtitle =>
      'Se actualiza automáticamente cuando agregas lugares favoritos';

  @override
  String get selectAll => 'Seleccionar todos';

  @override
  String get noNeighborhoodsFoundTitle => 'No se encontraron barrios';

  @override
  String get tryAnotherSearch => 'Intenta otra búsqueda';

  @override
  String get saving => 'Guardando...';
}
