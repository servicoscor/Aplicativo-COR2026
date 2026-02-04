// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'COR.AI';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageSectionTitle => 'Language';

  @override
  String get languageLabel => 'App language';

  @override
  String get languagePortuguese => 'Portuguese (Brazil)';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSpanish => 'Spanish';

  @override
  String get languageChinese => 'Chinese (Simplified)';

  @override
  String get navMap => 'Map';

  @override
  String get navCity => 'City';

  @override
  String get navNetworks => 'Networks';

  @override
  String get navFavorites => 'Favorites';

  @override
  String get navConfig => 'Settings';

  @override
  String get socialTitle => 'COR Social Networks';

  @override
  String get socialXLabel => 'X (Twitter)';

  @override
  String get socialInstagramLabel => 'Instagram';

  @override
  String get socialFacebookLabel => 'Facebook';

  @override
  String get alertsTitle => 'City';

  @override
  String unreadCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# unread',
      one: '# unread',
    );
    return '$_temp0';
  }

  @override
  String get filterUnread => 'Unread';

  @override
  String get filterEmergency => 'Emergency';

  @override
  String get filterAlert => 'Alert';

  @override
  String get filterInfo => 'Info';

  @override
  String get clear => 'Clear';

  @override
  String get emptyAlertsTitle => 'No alerts';

  @override
  String get emptyAlertsSubtitle =>
      'You have no alerts right now.\nWhen there is news, you will be notified.';

  @override
  String get refresh => 'Refresh';

  @override
  String get noResultsTitle => 'No results';

  @override
  String get noResultsSubtitle => 'No alerts match the selected filters.';

  @override
  String get clearFilters => 'Clear Filters';

  @override
  String get favoritesTitle => 'My Neighborhoods';

  @override
  String get favoritesInstruction =>
      'Add your favorite neighborhoods to receive personalized alerts, even when location is not available.';

  @override
  String get favoritesSearchHint => 'Search neighborhood...';

  @override
  String get favoritesEmptyTitle => 'No favorite neighborhoods';

  @override
  String get favoritesEmptySubtitle =>
      'Use the search above to add neighborhoods to your favorites list.';

  @override
  String get favoritesRemoveTitle => 'Remove neighborhood?';

  @override
  String favoritesRemoveBody(String name) {
    return 'Remove \"$name\" from your favorite neighborhoods?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get remove => 'Remove';

  @override
  String get appLinkError => 'Unable to open the app link.';

  @override
  String get install => 'Install';

  @override
  String get sectionPermissions => 'Permissions';

  @override
  String get permissionLocationTitle => 'Location';

  @override
  String get permissionGranted => 'Permission granted';

  @override
  String get permissionLocationNeeded => 'Permission required for local alerts';

  @override
  String get permissionNotificationsTitle => 'Notifications';

  @override
  String get permissionNotificationsNeeded =>
      'Permission required to receive alerts';

  @override
  String get sectionAlerts => 'Alerts';

  @override
  String get sectionServer => 'Server';

  @override
  String get sectionSystemStatus => 'System Status';

  @override
  String get sectionDiagnostics => 'Connection Test';

  @override
  String get sectionAbout => 'About';

  @override
  String get allow => 'Allow';

  @override
  String get neighborhoodAlertsTitle => 'Neighborhood alerts';

  @override
  String get neighborhoodAlertsSubtitle =>
      'Choose the neighborhoods you want to receive alerts for';

  @override
  String get apiUrlLabel => 'API URL';

  @override
  String get apiUrlHint => 'http://187.111.99.18:8001/api';

  @override
  String get invalidUrl => 'Invalid URL. Use http:// or https://';

  @override
  String get save => 'Save';

  @override
  String get systemFirebase => 'Firebase';

  @override
  String get statusOk => 'OK';

  @override
  String get statusNotConfigured => 'NOT CONFIGURED';

  @override
  String get systemFcmToken => 'FCM Token';

  @override
  String get statusPresent => 'Present';

  @override
  String get statusAbsent => 'Absent';

  @override
  String get systemLastRegister => 'Last Register';

  @override
  String get statusSuccess => 'Success';

  @override
  String get statusFailure => 'Failure';

  @override
  String get statusNever => 'Never';

  @override
  String get testConnectionTitle => 'Test Connection';

  @override
  String get testConnectionSubtitle => 'Checks API status /v1/health';

  @override
  String get test => 'Test';

  @override
  String get connectionOk => 'Connection OK';

  @override
  String get connectionFailed => 'Connection failed';

  @override
  String get statusLabel => 'Status';

  @override
  String get versionLabel => 'Version';

  @override
  String get databaseLabel => 'Database';

  @override
  String get cacheLabel => 'Cache';

  @override
  String get registeredDeviceTitle => 'Registered Device';

  @override
  String get deviceIdLabel => 'ID';

  @override
  String get devicePlatformLabel => 'Platform';

  @override
  String get deviceTokenLabel => 'Token';

  @override
  String get deviceNeighborhoodsLabel => 'Neighborhoods';

  @override
  String get aboutSubtitle => 'Rio Operations Center';

  @override
  String get developedByLabel => 'Developed by';

  @override
  String get developedByValue => 'City of Rio';

  @override
  String get timeAgoNow => 'just now';

  @override
  String timeAgoMinutes(int minutes) {
    return '$minutes min ago';
  }

  @override
  String timeAgoHours(int hours) {
    return '${hours}h ago';
  }

  @override
  String timeAgoDate(String date, String time) {
    return '$date $time';
  }

  @override
  String get viewOnMap => 'View on map';

  @override
  String get watch => 'Watch';

  @override
  String get retry => 'Try again';

  @override
  String get back => 'Back';

  @override
  String get errorGenericTitle => 'Oops! Something went wrong';

  @override
  String get neighborhoodsSavedSuccess => 'Neighborhoods saved successfully!';

  @override
  String get neighborhoodsSavedError => 'Error saving neighborhoods';

  @override
  String selectedCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# selected',
      one: '# selected',
    );
    return '$_temp0';
  }

  @override
  String get syncWithFavoritesTitle => 'Sync with favorites';

  @override
  String get syncWithFavoritesSubtitle =>
      'Automatically updates when you add favorite places';

  @override
  String get selectAll => 'Select all';

  @override
  String get noNeighborhoodsFoundTitle => 'No neighborhoods found';

  @override
  String get tryAnotherSearch => 'Try another search';

  @override
  String get saving => 'Saving...';
}
