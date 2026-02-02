// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'COR.AI';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get languageSectionTitle => 'Idioma';

  @override
  String get languageLabel => 'Idioma do app';

  @override
  String get languagePortuguese => 'Português (Brasil)';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Español';

  @override
  String get languageChinese => '中文（简体）';

  @override
  String get navMap => 'Mapa';

  @override
  String get navCity => 'Cidade';

  @override
  String get navNetworks => 'Redes';

  @override
  String get navFavorites => 'Favoritos';

  @override
  String get navConfig => 'Config';

  @override
  String get socialTitle => 'Redes Sociais do COR';

  @override
  String get socialXLabel => 'X (Twitter)';

  @override
  String get socialInstagramLabel => 'Instagram';

  @override
  String get socialFacebookLabel => 'Facebook';

  @override
  String get alertsTitle => 'Cidade';

  @override
  String unreadCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# não lidos',
      one: '# não lido',
    );
    return '$_temp0';
  }

  @override
  String get filterUnread => 'Não lidos';

  @override
  String get filterEmergency => 'Emergência';

  @override
  String get filterAlert => 'Alerta';

  @override
  String get filterInfo => 'Info';

  @override
  String get clear => 'Limpar';

  @override
  String get emptyAlertsTitle => 'Nenhum alerta';

  @override
  String get emptyAlertsSubtitle =>
      'Você não possui alertas no momento.\nQuando houver novidades, você será notificado.';

  @override
  String get refresh => 'Atualizar';

  @override
  String get noResultsTitle => 'Nenhum resultado';

  @override
  String get noResultsSubtitle =>
      'Nenhum alerta corresponde aos filtros selecionados.';

  @override
  String get clearFilters => 'Limpar Filtros';

  @override
  String get favoritesTitle => 'Meus Bairros';

  @override
  String get favoritesInstruction =>
      'Adicione seus bairros favoritos para receber alertas personalizados, mesmo quando a localização não estiver disponível.';

  @override
  String get favoritesSearchHint => 'Buscar bairro...';

  @override
  String get favoritesEmptyTitle => 'Nenhum bairro favorito';

  @override
  String get favoritesEmptySubtitle =>
      'Use a busca acima para adicionar bairros à sua lista de favoritos.';

  @override
  String get favoritesRemoveTitle => 'Remover bairro?';

  @override
  String favoritesRemoveBody(String name) {
    return 'Deseja remover \"$name\" dos seus bairros favoritos?';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get remove => 'Remover';

  @override
  String get appLinkError => 'Não foi possível abrir o link do app.';

  @override
  String get install => 'Instalar';

  @override
  String get sectionPermissions => 'Permissões';

  @override
  String get permissionLocationTitle => 'Localização';

  @override
  String get permissionGranted => 'Permissão concedida';

  @override
  String get permissionLocationNeeded =>
      'Permissão necessária para alertas locais';

  @override
  String get permissionNotificationsTitle => 'Notificações';

  @override
  String get permissionNotificationsNeeded =>
      'Permissão necessária para receber alertas';

  @override
  String get sectionAlerts => 'Alertas';

  @override
  String get sectionServer => 'Servidor';

  @override
  String get sectionSystemStatus => 'Status do Sistema';

  @override
  String get sectionDiagnostics => 'Teste de Conexão';

  @override
  String get sectionAbout => 'Sobre';

  @override
  String get allow => 'Permitir';

  @override
  String get neighborhoodAlertsTitle => 'Alertas por bairro';

  @override
  String get neighborhoodAlertsSubtitle =>
      'Escolha os bairros que deseja receber alertas';

  @override
  String get apiUrlLabel => 'URL da API';

  @override
  String get apiUrlHint => 'http://10.0.2.2:8000';

  @override
  String get invalidUrl => 'URL inválida. Use http:// ou https://';

  @override
  String get save => 'Salvar';

  @override
  String get systemFirebase => 'Firebase';

  @override
  String get statusOk => 'OK';

  @override
  String get statusNotConfigured => 'NÃO CONFIGURADO';

  @override
  String get systemFcmToken => 'FCM Token';

  @override
  String get statusPresent => 'Presente';

  @override
  String get statusAbsent => 'Ausente';

  @override
  String get systemLastRegister => 'Último Register';

  @override
  String get statusSuccess => 'Sucesso';

  @override
  String get statusFailure => 'Falha';

  @override
  String get statusNever => 'Nunca';

  @override
  String get testConnectionTitle => 'Testar Conexão';

  @override
  String get testConnectionSubtitle => 'Verifica status da API /v1/health';

  @override
  String get test => 'Testar';

  @override
  String get connectionOk => 'Conexão OK';

  @override
  String get connectionFailed => 'Falha na conexão';

  @override
  String get statusLabel => 'Status';

  @override
  String get versionLabel => 'Versão';

  @override
  String get databaseLabel => 'Database';

  @override
  String get cacheLabel => 'Cache';

  @override
  String get registeredDeviceTitle => 'Dispositivo Registrado';

  @override
  String get deviceIdLabel => 'ID';

  @override
  String get devicePlatformLabel => 'Plataforma';

  @override
  String get deviceTokenLabel => 'Token';

  @override
  String get deviceNeighborhoodsLabel => 'Bairros';

  @override
  String get aboutSubtitle => 'Centro de Operações Rio';

  @override
  String get developedByLabel => 'Desenvolvido por';

  @override
  String get developedByValue => 'Prefeitura do Rio';

  @override
  String get timeAgoNow => 'agora mesmo';

  @override
  String timeAgoMinutes(int minutes) {
    return 'há $minutes min';
  }

  @override
  String timeAgoHours(int hours) {
    return 'há ${hours}h';
  }

  @override
  String timeAgoDate(String date, String time) {
    return '$date $time';
  }

  @override
  String get viewOnMap => 'Ver no mapa';

  @override
  String get watch => 'Assistir';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get back => 'Voltar';

  @override
  String get errorGenericTitle => 'Ops! Algo deu errado';

  @override
  String get neighborhoodsSavedSuccess => 'Bairros salvos com sucesso!';

  @override
  String get neighborhoodsSavedError => 'Erro ao salvar bairros';

  @override
  String selectedCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# selecionados',
      one: '# selecionado',
    );
    return '$_temp0';
  }

  @override
  String get syncWithFavoritesTitle => 'Sincronizar com favoritos';

  @override
  String get syncWithFavoritesSubtitle =>
      'Atualiza automaticamente quando você adiciona locais favoritos';

  @override
  String get selectAll => 'Selecionar todos';

  @override
  String get noNeighborhoodsFoundTitle => 'Nenhum bairro encontrado';

  @override
  String get tryAnotherSearch => 'Tente outra busca';

  @override
  String get saving => 'Salvando...';
}
