import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Seção: Permissões
          _buildSectionTitle('Permissões'),
          _buildPermissionTile(
            icon: LucideIcons.mapPin,
            title: 'Localização',
            subtitle: state.locationPermissionGranted
                ? 'Permissão concedida'
                : 'Permissão necessária para alertas locais',
            isGranted: state.locationPermissionGranted,
            isEnabled: state.locationEnabled,
            onToggle: (enabled) => controller.toggleLocationEnabled(enabled),
            onRequest: () => controller.requestLocationPermission(),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildPermissionTile(
            icon: LucideIcons.bell,
            title: 'Notificações',
            subtitle: state.notificationPermissionGranted
                ? 'Permissão concedida'
                : 'Permissão necessária para receber alertas',
            isGranted: state.notificationPermissionGranted,
            isEnabled: state.notificationsEnabled,
            onToggle: (enabled) => controller.toggleNotificationsEnabled(enabled),
            onRequest: () => controller.requestNotificationPermission(),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Seção: Alertas
          _buildSectionTitle('Alertas'),
          _buildNeighborhoodsTile(),

          const SizedBox(height: AppSpacing.xl),

          // Seção: Servidor
          _buildSectionTitle('Servidor'),
          _buildUrlTile(state, controller),

          const SizedBox(height: AppSpacing.xl),

          // Seção: Status do Sistema
          _buildSectionTitle('Status do Sistema'),
          _buildSystemStatusTile(state),

          const SizedBox(height: AppSpacing.xl),

          // Seção: Diagnóstico (Teste de Conexão)
          _buildSectionTitle('Teste de Conexão'),
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
          _buildSectionTitle('Sobre'),
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
              child: const Text('Permitir'),
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
                    'Alertas por bairro',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Escolha os bairros que deseja receber alertas',
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
              decoration: const InputDecoration(
                labelText: 'URL da API',
                hintText: 'http://10.0.2.2:8000',
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
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: AppSpacing.sm),
                ElevatedButton(
                  onPressed: () async {
                    final success = await controller.saveUrl();
                    if (!success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('URL inválida. Use http:// ou https://'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  },
                  child: const Text('Salvar'),
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
                  'URL da API',
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
            label: 'Firebase',
            status: diagnostic.firebaseOk ? 'OK' : 'NÃO CONFIGURADO',
            isOk: diagnostic.firebaseOk,
          ),
          const SizedBox(height: AppSpacing.md),

          // FCM Token Status
          _buildStatusRow(
            icon: LucideIcons.key,
            label: 'FCM Token',
            status: diagnostic.hasFcmToken ? 'Presente' : 'Ausente',
            isOk: diagnostic.hasFcmToken,
            subtitle: diagnostic.fcmTokenPreview,
          ),
          const SizedBox(height: AppSpacing.md),

          // Último Register
          _buildStatusRow(
            icon: LucideIcons.cloud,
            label: 'Último Register',
            status: diagnostic.lastRegisterTimestamp != null
                ? (diagnostic.lastRegisterSuccess ? 'Sucesso' : 'Falha')
                : 'Nunca',
            isOk: diagnostic.lastRegisterSuccess,
            subtitle: diagnostic.lastRegisterTimestamp != null
                ? _formatTimestamp(diagnostic.lastRegisterTimestamp!)
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

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'agora mesmo';
    } else if (diff.inMinutes < 60) {
      return 'há ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'há ${diff.inHours}h';
    } else {
      return '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
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
                      'Testar Conexão',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Verifica status da API /v1/health',
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
                    : const Text('Testar'),
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
                isSuccess ? 'Conexão OK' : 'Falha na conexão',
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
            _buildInfoRow('Status', result.response!.status),
            if (result.response!.version != null)
              _buildInfoRow('Versão', result.response!.version!),
            if (result.response!.database != null)
              _buildInfoRow('Database', result.response!.database!.status),
            if (result.response!.cache != null)
              _buildInfoRow('Cache', result.response!.cache!.status),
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
            'Dispositivo Registrado',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow('ID', device.id),
          _buildInfoRow('Plataforma', device.platform.toUpperCase()),
          if (device.maskedToken != null)
            _buildInfoRow('Token', device.maskedToken!),
          if (device.neighborhoods != null && device.neighborhoods!.isNotEmpty)
            _buildInfoRow('Bairros', device.neighborhoods!.join(', ')),
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
                      'Centro de Operações Rio',
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
          _buildInfoRow('Versão', _appVersion.isNotEmpty ? _appVersion : '1.0.0'),
          _buildInfoRow('Desenvolvido por', 'Prefeitura do Rio'),
        ],
      ),
    );
  }
}
