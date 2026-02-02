import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'COR.AI'**
  String get appTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get settingsTitle;

  /// No description provided for @languageSectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get languageSectionTitle;

  /// No description provided for @languageLabel.
  ///
  /// In pt, this message translates to:
  /// **'Idioma do app'**
  String get languageLabel;

  /// No description provided for @languagePortuguese.
  ///
  /// In pt, this message translates to:
  /// **'Português (Brasil)'**
  String get languagePortuguese;

  /// No description provided for @languageEnglish.
  ///
  /// In pt, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageSpanish.
  ///
  /// In pt, this message translates to:
  /// **'Español'**
  String get languageSpanish;

  /// No description provided for @languageChinese.
  ///
  /// In pt, this message translates to:
  /// **'中文（简体）'**
  String get languageChinese;

  /// No description provided for @navMap.
  ///
  /// In pt, this message translates to:
  /// **'Mapa'**
  String get navMap;

  /// No description provided for @navCity.
  ///
  /// In pt, this message translates to:
  /// **'Cidade'**
  String get navCity;

  /// No description provided for @navNetworks.
  ///
  /// In pt, this message translates to:
  /// **'Redes'**
  String get navNetworks;

  /// No description provided for @navFavorites.
  ///
  /// In pt, this message translates to:
  /// **'Favoritos'**
  String get navFavorites;

  /// No description provided for @navConfig.
  ///
  /// In pt, this message translates to:
  /// **'Config'**
  String get navConfig;

  /// No description provided for @socialTitle.
  ///
  /// In pt, this message translates to:
  /// **'Redes Sociais do COR'**
  String get socialTitle;

  /// No description provided for @socialXLabel.
  ///
  /// In pt, this message translates to:
  /// **'X (Twitter)'**
  String get socialXLabel;

  /// No description provided for @socialInstagramLabel.
  ///
  /// In pt, this message translates to:
  /// **'Instagram'**
  String get socialInstagramLabel;

  /// No description provided for @socialFacebookLabel.
  ///
  /// In pt, this message translates to:
  /// **'Facebook'**
  String get socialFacebookLabel;

  /// No description provided for @alertsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Cidade'**
  String get alertsTitle;

  /// No description provided for @unreadCountLabel.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{# não lido} other{# não lidos}}'**
  String unreadCountLabel(int count);

  /// No description provided for @filterUnread.
  ///
  /// In pt, this message translates to:
  /// **'Não lidos'**
  String get filterUnread;

  /// No description provided for @filterEmergency.
  ///
  /// In pt, this message translates to:
  /// **'Emergência'**
  String get filterEmergency;

  /// No description provided for @filterAlert.
  ///
  /// In pt, this message translates to:
  /// **'Alerta'**
  String get filterAlert;

  /// No description provided for @filterInfo.
  ///
  /// In pt, this message translates to:
  /// **'Info'**
  String get filterInfo;

  /// No description provided for @clear.
  ///
  /// In pt, this message translates to:
  /// **'Limpar'**
  String get clear;

  /// No description provided for @emptyAlertsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum alerta'**
  String get emptyAlertsTitle;

  /// No description provided for @emptyAlertsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Você não possui alertas no momento.\nQuando houver novidades, você será notificado.'**
  String get emptyAlertsSubtitle;

  /// No description provided for @refresh.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar'**
  String get refresh;

  /// No description provided for @noResultsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum resultado'**
  String get noResultsTitle;

  /// No description provided for @noResultsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum alerta corresponde aos filtros selecionados.'**
  String get noResultsSubtitle;

  /// No description provided for @clearFilters.
  ///
  /// In pt, this message translates to:
  /// **'Limpar Filtros'**
  String get clearFilters;

  /// No description provided for @favoritesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Meus Bairros'**
  String get favoritesTitle;

  /// No description provided for @favoritesInstruction.
  ///
  /// In pt, this message translates to:
  /// **'Adicione seus bairros favoritos para receber alertas personalizados, mesmo quando a localização não estiver disponível.'**
  String get favoritesInstruction;

  /// No description provided for @favoritesSearchHint.
  ///
  /// In pt, this message translates to:
  /// **'Buscar bairro...'**
  String get favoritesSearchHint;

  /// No description provided for @favoritesEmptyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum bairro favorito'**
  String get favoritesEmptyTitle;

  /// No description provided for @favoritesEmptySubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Use a busca acima para adicionar bairros à sua lista de favoritos.'**
  String get favoritesEmptySubtitle;

  /// No description provided for @favoritesRemoveTitle.
  ///
  /// In pt, this message translates to:
  /// **'Remover bairro?'**
  String get favoritesRemoveTitle;

  /// No description provided for @favoritesRemoveBody.
  ///
  /// In pt, this message translates to:
  /// **'Deseja remover \"{name}\" dos seus bairros favoritos?'**
  String favoritesRemoveBody(String name);

  /// No description provided for @cancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @remove.
  ///
  /// In pt, this message translates to:
  /// **'Remover'**
  String get remove;

  /// No description provided for @appLinkError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível abrir o link do app.'**
  String get appLinkError;

  /// No description provided for @install.
  ///
  /// In pt, this message translates to:
  /// **'Instalar'**
  String get install;

  /// No description provided for @sectionPermissions.
  ///
  /// In pt, this message translates to:
  /// **'Permissões'**
  String get sectionPermissions;

  /// No description provided for @permissionLocationTitle.
  ///
  /// In pt, this message translates to:
  /// **'Localização'**
  String get permissionLocationTitle;

  /// No description provided for @permissionGranted.
  ///
  /// In pt, this message translates to:
  /// **'Permissão concedida'**
  String get permissionGranted;

  /// No description provided for @permissionLocationNeeded.
  ///
  /// In pt, this message translates to:
  /// **'Permissão necessária para alertas locais'**
  String get permissionLocationNeeded;

  /// No description provided for @permissionNotificationsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Notificações'**
  String get permissionNotificationsTitle;

  /// No description provided for @permissionNotificationsNeeded.
  ///
  /// In pt, this message translates to:
  /// **'Permissão necessária para receber alertas'**
  String get permissionNotificationsNeeded;

  /// No description provided for @sectionAlerts.
  ///
  /// In pt, this message translates to:
  /// **'Alertas'**
  String get sectionAlerts;

  /// No description provided for @sectionServer.
  ///
  /// In pt, this message translates to:
  /// **'Servidor'**
  String get sectionServer;

  /// No description provided for @sectionSystemStatus.
  ///
  /// In pt, this message translates to:
  /// **'Status do Sistema'**
  String get sectionSystemStatus;

  /// No description provided for @sectionDiagnostics.
  ///
  /// In pt, this message translates to:
  /// **'Teste de Conexão'**
  String get sectionDiagnostics;

  /// No description provided for @sectionAbout.
  ///
  /// In pt, this message translates to:
  /// **'Sobre'**
  String get sectionAbout;

  /// No description provided for @allow.
  ///
  /// In pt, this message translates to:
  /// **'Permitir'**
  String get allow;

  /// No description provided for @neighborhoodAlertsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Alertas por bairro'**
  String get neighborhoodAlertsTitle;

  /// No description provided for @neighborhoodAlertsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Escolha os bairros que deseja receber alertas'**
  String get neighborhoodAlertsSubtitle;

  /// No description provided for @apiUrlLabel.
  ///
  /// In pt, this message translates to:
  /// **'URL da API'**
  String get apiUrlLabel;

  /// No description provided for @apiUrlHint.
  ///
  /// In pt, this message translates to:
  /// **'http://10.0.2.2:8000'**
  String get apiUrlHint;

  /// No description provided for @invalidUrl.
  ///
  /// In pt, this message translates to:
  /// **'URL inválida. Use http:// ou https://'**
  String get invalidUrl;

  /// No description provided for @save.
  ///
  /// In pt, this message translates to:
  /// **'Salvar'**
  String get save;

  /// No description provided for @systemFirebase.
  ///
  /// In pt, this message translates to:
  /// **'Firebase'**
  String get systemFirebase;

  /// No description provided for @statusOk.
  ///
  /// In pt, this message translates to:
  /// **'OK'**
  String get statusOk;

  /// No description provided for @statusNotConfigured.
  ///
  /// In pt, this message translates to:
  /// **'NÃO CONFIGURADO'**
  String get statusNotConfigured;

  /// No description provided for @systemFcmToken.
  ///
  /// In pt, this message translates to:
  /// **'FCM Token'**
  String get systemFcmToken;

  /// No description provided for @statusPresent.
  ///
  /// In pt, this message translates to:
  /// **'Presente'**
  String get statusPresent;

  /// No description provided for @statusAbsent.
  ///
  /// In pt, this message translates to:
  /// **'Ausente'**
  String get statusAbsent;

  /// No description provided for @systemLastRegister.
  ///
  /// In pt, this message translates to:
  /// **'Último Register'**
  String get systemLastRegister;

  /// No description provided for @statusSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Sucesso'**
  String get statusSuccess;

  /// No description provided for @statusFailure.
  ///
  /// In pt, this message translates to:
  /// **'Falha'**
  String get statusFailure;

  /// No description provided for @statusNever.
  ///
  /// In pt, this message translates to:
  /// **'Nunca'**
  String get statusNever;

  /// No description provided for @testConnectionTitle.
  ///
  /// In pt, this message translates to:
  /// **'Testar Conexão'**
  String get testConnectionTitle;

  /// No description provided for @testConnectionSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Verifica status da API /v1/health'**
  String get testConnectionSubtitle;

  /// No description provided for @test.
  ///
  /// In pt, this message translates to:
  /// **'Testar'**
  String get test;

  /// No description provided for @connectionOk.
  ///
  /// In pt, this message translates to:
  /// **'Conexão OK'**
  String get connectionOk;

  /// No description provided for @connectionFailed.
  ///
  /// In pt, this message translates to:
  /// **'Falha na conexão'**
  String get connectionFailed;

  /// No description provided for @statusLabel.
  ///
  /// In pt, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @versionLabel.
  ///
  /// In pt, this message translates to:
  /// **'Versão'**
  String get versionLabel;

  /// No description provided for @databaseLabel.
  ///
  /// In pt, this message translates to:
  /// **'Database'**
  String get databaseLabel;

  /// No description provided for @cacheLabel.
  ///
  /// In pt, this message translates to:
  /// **'Cache'**
  String get cacheLabel;

  /// No description provided for @registeredDeviceTitle.
  ///
  /// In pt, this message translates to:
  /// **'Dispositivo Registrado'**
  String get registeredDeviceTitle;

  /// No description provided for @deviceIdLabel.
  ///
  /// In pt, this message translates to:
  /// **'ID'**
  String get deviceIdLabel;

  /// No description provided for @devicePlatformLabel.
  ///
  /// In pt, this message translates to:
  /// **'Plataforma'**
  String get devicePlatformLabel;

  /// No description provided for @deviceTokenLabel.
  ///
  /// In pt, this message translates to:
  /// **'Token'**
  String get deviceTokenLabel;

  /// No description provided for @deviceNeighborhoodsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Bairros'**
  String get deviceNeighborhoodsLabel;

  /// No description provided for @aboutSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Centro de Operações Rio'**
  String get aboutSubtitle;

  /// No description provided for @developedByLabel.
  ///
  /// In pt, this message translates to:
  /// **'Desenvolvido por'**
  String get developedByLabel;

  /// No description provided for @developedByValue.
  ///
  /// In pt, this message translates to:
  /// **'Prefeitura do Rio'**
  String get developedByValue;

  /// No description provided for @timeAgoNow.
  ///
  /// In pt, this message translates to:
  /// **'agora mesmo'**
  String get timeAgoNow;

  /// No description provided for @timeAgoMinutes.
  ///
  /// In pt, this message translates to:
  /// **'há {minutes} min'**
  String timeAgoMinutes(int minutes);

  /// No description provided for @timeAgoHours.
  ///
  /// In pt, this message translates to:
  /// **'há {hours}h'**
  String timeAgoHours(int hours);

  /// No description provided for @timeAgoDate.
  ///
  /// In pt, this message translates to:
  /// **'{date} {time}'**
  String timeAgoDate(String date, String time);

  /// No description provided for @viewOnMap.
  ///
  /// In pt, this message translates to:
  /// **'Ver no mapa'**
  String get viewOnMap;

  /// No description provided for @watch.
  ///
  /// In pt, this message translates to:
  /// **'Assistir'**
  String get watch;

  /// No description provided for @retry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get retry;

  /// No description provided for @back.
  ///
  /// In pt, this message translates to:
  /// **'Voltar'**
  String get back;

  /// No description provided for @errorGenericTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ops! Algo deu errado'**
  String get errorGenericTitle;

  /// No description provided for @neighborhoodsSavedSuccess.
  ///
  /// In pt, this message translates to:
  /// **'Bairros salvos com sucesso!'**
  String get neighborhoodsSavedSuccess;

  /// No description provided for @neighborhoodsSavedError.
  ///
  /// In pt, this message translates to:
  /// **'Erro ao salvar bairros'**
  String get neighborhoodsSavedError;

  /// No description provided for @selectedCountLabel.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =1{# selecionado} other{# selecionados}}'**
  String selectedCountLabel(int count);

  /// No description provided for @syncWithFavoritesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Sincronizar com favoritos'**
  String get syncWithFavoritesTitle;

  /// No description provided for @syncWithFavoritesSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Atualiza automaticamente quando você adiciona locais favoritos'**
  String get syncWithFavoritesSubtitle;

  /// No description provided for @selectAll.
  ///
  /// In pt, this message translates to:
  /// **'Selecionar todos'**
  String get selectAll;

  /// No description provided for @noNeighborhoodsFoundTitle.
  ///
  /// In pt, this message translates to:
  /// **'Nenhum bairro encontrado'**
  String get noNeighborhoodsFoundTitle;

  /// No description provided for @tryAnotherSearch.
  ///
  /// In pt, this message translates to:
  /// **'Tente outra busca'**
  String get tryAnotherSearch;

  /// No description provided for @saving.
  ///
  /// In pt, this message translates to:
  /// **'Salvando...'**
  String get saving;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
