// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'COR.AI';

  @override
  String get settingsTitle => '设置';

  @override
  String get languageSectionTitle => '语言';

  @override
  String get languageLabel => '应用语言';

  @override
  String get languagePortuguese => '葡萄牙语（巴西）';

  @override
  String get languageEnglish => '英语';

  @override
  String get languageSpanish => '西班牙语';

  @override
  String get languageChinese => '简体中文';

  @override
  String get navMap => '地图';

  @override
  String get navCity => '城市';

  @override
  String get navNetworks => '社交';

  @override
  String get navFavorites => '收藏';

  @override
  String get navConfig => '设置';

  @override
  String get socialTitle => 'COR 社交媒体';

  @override
  String get socialXLabel => 'X (Twitter)';

  @override
  String get socialInstagramLabel => 'Instagram';

  @override
  String get socialFacebookLabel => 'Facebook';

  @override
  String get alertsTitle => '城市';

  @override
  String unreadCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# 条未读',
      one: '# 条未读',
    );
    return '$_temp0';
  }

  @override
  String get filterUnread => '未读';

  @override
  String get filterEmergency => '紧急';

  @override
  String get filterAlert => '警报';

  @override
  String get filterInfo => '信息';

  @override
  String get clear => '清除';

  @override
  String get emptyAlertsTitle => '暂无警报';

  @override
  String get emptyAlertsSubtitle => '你目前没有警报。\n有新消息时将通知你。';

  @override
  String get refresh => '刷新';

  @override
  String get noResultsTitle => '无结果';

  @override
  String get noResultsSubtitle => '没有与所选筛选条件匹配的警报。';

  @override
  String get clearFilters => '清除筛选';

  @override
  String get favoritesTitle => '我的街区';

  @override
  String get favoritesInstruction => '添加你喜欢的街区以接收个性化警报，即使定位不可用。';

  @override
  String get favoritesSearchHint => '搜索街区...';

  @override
  String get favoritesEmptyTitle => '暂无收藏街区';

  @override
  String get favoritesEmptySubtitle => '使用上方搜索将街区添加到收藏列表。';

  @override
  String get favoritesRemoveTitle => '移除街区？';

  @override
  String favoritesRemoveBody(String name) {
    return '是否将“$name”从收藏街区中移除？';
  }

  @override
  String get cancel => '取消';

  @override
  String get remove => '移除';

  @override
  String get appLinkError => '无法打开应用链接。';

  @override
  String get install => '安装';

  @override
  String get sectionPermissions => '权限';

  @override
  String get permissionLocationTitle => '定位';

  @override
  String get permissionGranted => '权限已授予';

  @override
  String get permissionLocationNeeded => '本地警报需要定位权限';

  @override
  String get permissionNotificationsTitle => '通知';

  @override
  String get permissionNotificationsNeeded => '接收警报需要权限';

  @override
  String get sectionAlerts => '警报';

  @override
  String get sectionServer => '服务器';

  @override
  String get sectionSystemStatus => '系统状态';

  @override
  String get sectionDiagnostics => '连接测试';

  @override
  String get sectionAbout => '关于';

  @override
  String get allow => '允许';

  @override
  String get neighborhoodAlertsTitle => '街区警报';

  @override
  String get neighborhoodAlertsSubtitle => '选择你想接收警报的街区';

  @override
  String get apiUrlLabel => 'API 地址';

  @override
  String get apiUrlHint => 'http://10.0.2.2:8000';

  @override
  String get invalidUrl => '无效的 URL。请使用 http:// 或 https://';

  @override
  String get save => '保存';

  @override
  String get systemFirebase => 'Firebase';

  @override
  String get statusOk => '正常';

  @override
  String get statusNotConfigured => '未配置';

  @override
  String get systemFcmToken => 'FCM Token';

  @override
  String get statusPresent => '已存在';

  @override
  String get statusAbsent => '缺失';

  @override
  String get systemLastRegister => '上次注册';

  @override
  String get statusSuccess => '成功';

  @override
  String get statusFailure => '失败';

  @override
  String get statusNever => '从未';

  @override
  String get testConnectionTitle => '测试连接';

  @override
  String get testConnectionSubtitle => '检查 API /v1/health 状态';

  @override
  String get test => '测试';

  @override
  String get connectionOk => '连接正常';

  @override
  String get connectionFailed => '连接失败';

  @override
  String get statusLabel => '状态';

  @override
  String get versionLabel => '版本';

  @override
  String get databaseLabel => '数据库';

  @override
  String get cacheLabel => '缓存';

  @override
  String get registeredDeviceTitle => '已注册设备';

  @override
  String get deviceIdLabel => 'ID';

  @override
  String get devicePlatformLabel => '平台';

  @override
  String get deviceTokenLabel => 'Token';

  @override
  String get deviceNeighborhoodsLabel => '街区';

  @override
  String get aboutSubtitle => '里约运营中心';

  @override
  String get developedByLabel => '开发者';

  @override
  String get developedByValue => '里约市政府';

  @override
  String get timeAgoNow => '刚刚';

  @override
  String timeAgoMinutes(int minutes) {
    return '$minutes 分钟前';
  }

  @override
  String timeAgoHours(int hours) {
    return '$hours 小时前';
  }

  @override
  String timeAgoDate(String date, String time) {
    return '$date $time';
  }

  @override
  String get viewOnMap => '在地图中查看';

  @override
  String get watch => '观看';

  @override
  String get retry => '重试';

  @override
  String get back => '返回';

  @override
  String get errorGenericTitle => '糟糕！出错了';

  @override
  String get neighborhoodsSavedSuccess => '街区保存成功！';

  @override
  String get neighborhoodsSavedError => '保存街区时出错';

  @override
  String selectedCountLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# 个已选',
      one: '# 个已选',
    );
    return '$_temp0';
  }

  @override
  String get syncWithFavoritesTitle => '与收藏同步';

  @override
  String get syncWithFavoritesSubtitle => '当你添加收藏地点时会自动更新';

  @override
  String get selectAll => '全选';

  @override
  String get noNeighborhoodsFoundTitle => '未找到街区';

  @override
  String get tryAnotherSearch => '尝试其他搜索';

  @override
  String get saving => '保存中...';
}
