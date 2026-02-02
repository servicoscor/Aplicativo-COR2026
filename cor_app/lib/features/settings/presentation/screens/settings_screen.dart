import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/config/locale_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/models.dart';
import '../controllers/settings_controller.dart';
import 'neighborhood_subscriptions_screen.dart';

/// Tela de configurações
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _urlController = TextEditingController();
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _appVersion = '${info.version} (${info.buildNumber})';
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final localeController = ref.read(localeProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Seção: Permissões
          _buildSectionTitle(l10n.sectionPermissions),
          _buildPermissionTile(
            icon: LucideIcons.mapPin,
            title: l10n.permissionLocationTitle,
            subtitle: state.locationPermissionGranted
                ? l10n.permissionGranted
                : l10n.permissionLocationNeeded,
            isGranted: state.locationPermissionGranted,
            isEnabled: state.locationEnabled,
            onToggle: (enabled) => controller.toggleLocationEnabled(enabled),
            onRequest: () => controller.requestLocationPermission(),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildPermissionTile(
            icon: LucideIcons.bell,
            title: l10n.permissionNotificationsTitle,
            subtitle: state.notificationPermissionGranted
                ? l10n.permissionGranted
                : l10n.permissionNotificationsNeeded,
            isGranted: state.notificationPermissionGranted,
            isEnabled: state.notificationsEnabled,
            onToggle: (enabled) => controller.toggleNotificationsEnabled(enabled),
            onRequest: () => controller.requestNotificationPermission(),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Seção: Alertas
          _buildSectionTitle(l10n.sectionAlerts),
          _buildNeighborhoodsTile(),

          const SizedBox(height: AppSpacing.xl),

          // Seção: Idioma
          _buildSectionTitle(l10n.languageSectionTitle),
          _buildLanguageTile(locale, localeController, l10n),

          const SizedBox(height: AppSpacing.xl),

          // Seção: Servidor
          _buildSectionTitle(l10n.sectionServer),
          _buildUrlTile(state, controller),

          const SizedBox(height: AppSpacing.xl),

          // Seção: Status do Sistema
          _buildSectionTitle(l10n.sectionSystemStatus),
          _buildSystemStatusTile(state),

          const SizedBox(height: AppSpacing.xl),

          // Seção: Diagnóstico (Teste de Conexão)
          _buildSectionTitle(l10n.sectionDiagnostics),
          _buildDiagnosticTile(state, controller),

          // Resultado do teste
          if (state.healthResult != null) ...[
            const SizedBox(height: AppSpacing.md),
            _buildHealthResult(state.healthResult!),
          ],

          // Info do dispositivo
          if (state.deviceInfo != null) ...[
            const SizedBox(height: AppSpacing.md),
            _buildDeviceInfo(state.deviceInfo!),
          ],

          const SizedBox(height: AppSpacing.xl),

          // Seção: Sobre
          _buildSectionTitle(l10n.sectionAbout),
          _buildAboutTile(),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.xs,
        bottom: AppSpacing.sm,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isGranted,
    required bool isEnabled,
    required void Function(bool) onToggle,
    required VoidCallback onRequest,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isGranted ? AppColors.success : AppColors.alert).withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              icon,
              color: isGranted ? AppColors.success : AppColors.alert,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (!isGranted)
            TextButton(
              onPressed: onRequest,
              child: Text(AppLocalizations.of(context)!.allow),
            )
          else
            Switch(
              value: isEnabled,
              onChanged: onToggle,
            ),
        ],
      ),
    );
  }

  Widget _buildLanguageTile(
    Locale locale,
    LocaleController controller,
    AppLocalizations l10n,
  ) {
    return GestureDetector(
      onTap: () => _showLanguagePicker(locale, controller, l10n),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(
                LucideIcons.languages,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.languageLabel,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _languageLabel(locale, l10n),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              color: AppColors.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker(
    Locale locale,
    LocaleController controller,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(
                        LucideIcons.languages,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      l10n.languageSectionTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.divider),
              ...supportedAppLocales.map((supportedLocale) {
                final isSelected = supportedLocale.languageCode == locale.languageCode &&
                    supportedLocale.countryCode == locale.countryCode;
                return ListTile(
                  title: Text(_languageLabel(supportedLocale, l10n)),
                  trailing: isSelected
                      ? const Icon(LucideIcons.check, color: AppColors.primary)
                      : null,
                  onTap: () async {
                    Navigator.pop(context);
                    await controller.setLocale(supportedLocale);
                  },
                );
              }),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  String _languageLabel(Locale locale, AppLocalizations l10n) {
    if (locale.languageCode == 'pt') return l10n.languagePortuguese;
    if (locale.languageCode == 'en') return l10n.languageEnglish;
    if (locale.languageCode == 'es') return l10n.languageSpanish;
    if (locale.languageCode == 'zh') return l10n.languageChinese;
    return l10n.languagePortuguese;
  }

  Widget _buildNeighborhoodsTile() {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const NeighborhoodSubscriptionsScreen(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(
                LucideIcons.mapPin,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.neighborhoodAlertsTitle,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AppLocalizations.of(context)!.neighborhoodAlertsSubtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrlTile(SettingsState state, SettingsController controller) {
    if (state.isEditingUrl) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.primary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _urlController..text = state.editingUrl,
              onChanged: controller.updateEditingUrl,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.apiUrlLabel,
                hintText: AppLocalizations.of(context)!.apiUrlHint,
              ),
              keyboardType: TextInputType.url,
              autocorrect: false,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: controller.cancelEditingUrl,
                  child: Text(AppLocalizations.of(context)!.cancel),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton(
                  onPressed: () async {
                    final success = await controller.saveUrl();
                    if (!success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppLocalizations.of(context)!.invalidUrl),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                  child: Text(AppLocalizations.of(context)!.save),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              LucideIcons.server,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.apiUrlLabel,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  state.baseUrl,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.pencil, size: 18),
            onPressed: controller.startEditingUrl,
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatusTile(SettingsState state) {
    final diagnostic = state.diagnostic;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Firebase Status
          _buildStatusRow(
            icon: LucideIcons.flame,
            label: AppLocalizations.of(context)!.systemFirebase,
            status: diagnostic.firebaseOk
                ? AppLocalizations.of(context)!.statusOk
                : AppLocalizations.of(context)!.statusNotConfigured,
            isOk: diagnostic.firebaseOk,
          ),
          const SizedBox(height: AppSpacing.md),

          // FCM Token Status
          _buildStatusRow(
            icon: LucideIcons.key,
            label: AppLocalizations.of(context)!.systemFcmToken,
            status: diagnostic.hasFcmToken
                ? AppLocalizations.of(context)!.statusPresent
                : AppLocalizations.of(context)!.statusAbsent,
            isOk: diagnostic.hasFcmToken,
            subtitle: diagnostic.fcmTokenPreview,
          ),
          const SizedBox(height: AppSpacing.md),

          // Último Register
          _buildStatusRow(
            icon: LucideIcons.cloud,
            label: AppLocalizations.of(context)!.systemLastRegister,
            status: diagnostic.lastRegisterTimestamp != null
                ? (diagnostic.lastRegisterSuccess
                    ? AppLocalizations.of(context)!.statusSuccess
                    : AppLocalizations.of(context)!.statusFailure)
                : AppLocalizations.of(context)!.statusNever,
            isOk: diagnostic.lastRegisterSuccess,
            subtitle: diagnostic.lastRegisterTimestamp != null
                ? _formatTimestamp(
                    diagnostic.lastRegisterTimestamp!,
                    AppLocalizations.of(context)!,
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String label,
    required String status,
    required bool isOk,
    String? subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: (isOk ? AppColors.success : AppColors.error).withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(
            icon,
            color: isOk ? AppColors.success : AppColors.error,
            size: 16,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isOk ? AppColors.success : AppColors.error).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isOk ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 10,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return l10n.timeAgoNow;
    } else if (diff.inMinutes < 60) {
      return l10n.timeAgoMinutes(diff.inMinutes);
    } else if (diff.inHours < 24) {
      return l10n.timeAgoHours(diff.inHours);
    } else {
      final date =
          '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}';
      final time =
          '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
      return l10n.timeAgoDate(date, time);
    }
  }

  Widget _buildDiagnosticTile(SettingsState state, SettingsController controller) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  LucideIcons.activity,
                  color: AppColors.info,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.testConnectionTitle,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(context)!.testConnectionSubtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: state.isTesting ? null : controller.testHealth,
                child: state.isTesting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(AppLocalizations.of(context)!.test),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthResult(HealthTestResult result) {
    final isSuccess = result.success;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: (isSuccess ? AppColors.success : AppColors.error).withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: (isSuccess ? AppColors.success : AppColors.error).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSuccess ? LucideIcons.checkCircle : LucideIcons.xCircle,
                color: isSuccess ? AppColors.success : AppColors.error,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                isSuccess
                    ? AppLocalizations.of(context)!.connectionOk
                    : AppLocalizations.of(context)!.connectionFailed,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSuccess ? AppColors.success : AppColors.error,
                ),
              ),
              const Spacer(),
              if (result.latencyMs != null)
                Text(
                  '${result.latencyMs}ms',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
          if (isSuccess && result.response != null) ...[
            const SizedBox(height: AppSpacing.md),
            _buildInfoRow(
              AppLocalizations.of(context)!.statusLabel,
              result.response!.status,
            ),
            if (result.response!.version != null)
              _buildInfoRow(
                AppLocalizations.of(context)!.versionLabel,
                result.response!.version!,
              ),
            if (result.response!.database != null)
              _buildInfoRow(
                AppLocalizations.of(context)!.databaseLabel,
                result.response!.database!.status,
              ),
            if (result.response!.cache != null)
              _buildInfoRow(
                AppLocalizations.of(context)!.cacheLabel,
                result.response!.cache!.status,
              ),
          ],
          if (!isSuccess && result.error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              result.error!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceInfo(Device device) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.registeredDeviceTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(AppLocalizations.of(context)!.deviceIdLabel, device.id),
          _buildInfoRow(
            AppLocalizations.of(context)!.devicePlatformLabel,
            device.platform.toUpperCase(),
          ),
          if (device.maskedToken != null)
            _buildInfoRow(AppLocalizations.of(context)!.deviceTokenLabel, device.maskedToken!),
          if (device.neighborhoods != null && device.neighborhoods!.isNotEmpty)
            _buildInfoRow(
              AppLocalizations.of(context)!.deviceNeighborhoodsLabel,
              device.neighborhoods!.join(', '),
            ),
        ],
      ),
    );
  }

  Widget _buildAboutTile() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  LucideIcons.shield,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COR.AI',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      AppLocalizations.of(context)!.aboutSubtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(
            AppLocalizations.of(context)!.versionLabel,
            _appVersion.isNotEmpty ? _appVersion : '1.0.0',
          ),
          _buildInfoRow(
            AppLocalizations.of(context)!.developedByLabel,
            AppLocalizations.of(context)!.developedByValue,
          ),
        ],
      ),
    );
  }
}
