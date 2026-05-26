import 'package:flutter/material.dart';
import '../services/api_service/api_client.dart';
import '../services/api_service/provider_service.dart';
import '../services/api_service/settings_service.dart';
import '../services/api_service/models.dart';
import '../services/backend_service.dart';
import '../onboarding_screens/connect_screen.dart';
import 'provider_form_screen.dart';
import 'model_management_screen.dart';

class SettingsScreen extends StatefulWidget {
  final ApiClient apiClient;
  final BackendConnectionService backendService;
  final VoidCallback onDisconnect;

  const SettingsScreen({
    super.key,
    required this.apiClient,
    required this.backendService,
    required this.onDisconnect,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late final ProviderService _providerService;
  late final SettingsService _settingsService;
  late final TabController _tabController;

  final List<ProviderRecord> _providers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _providerService = ProviderService(widget.apiClient);
    _settingsService = SettingsService(widget.apiClient);
    _tabController = TabController(length: 4, vsync: this);
    _loadProviders();
    widget.backendService.addListener(_onBackendChanged);
  }

  @override
  void dispose() {
    widget.backendService.removeListener(_onBackendChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onBackendChanged() {
    if (widget.backendService.isConnected) {
      _loadProviders();
    }
  }

  Future<void> _loadProviders() async {
    setState(() => _loading = true);
    try {
      final providers = await _providerService.getProviders();
      if (!mounted) return;
      setState(() {
        _providers
          ..clear()
          ..addAll(providers);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green.shade600),
    );
  }

  Future<void> _deleteProvider(String name) async {
    try {
      await _providerService.deleteProvider(name);
      setState(() => _providers.removeWhere((p) => p.name == name));
      _showSuccess('$name deleted');
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _saveProvider(ProviderRecord record) async {
    try {
      final isNew = record.id == null;
      if (isNew) {
        final created = await _providerService.createProvider(record);
        setState(() => _providers.add(created));
      } else {
        final updated =
            await _providerService.updateProvider(record.name, record);
        setState(() {
          final idx = _providers.indexWhere((p) => p.name == record.name);
          if (idx >= 0) _providers[idx] = updated;
        });
      }
      _showSuccess('${record.name} saved');
    } catch (e) {
      _showError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline), text: 'Connection'),
            Tab(icon: Icon(Icons.cloud), text: 'Providers'),
            Tab(icon: Icon(Icons.smart_toy), text: 'Models'),
            Tab(icon: Icon(Icons.lock), text: 'Security'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _ConnectionTab(
                  apiClient: widget.apiClient,
                  backendService: widget.backendService,
                  onDisconnect: widget.onDisconnect,
                ),
                _ProvidersTab(
                  providers: _providers,
                  onDelete: _deleteProvider,
                  onEdit: (p) => _openProviderForm(p),
                  onAdd: () => _openProviderForm(null),
                  onManageModels: _manageModels,
                ),
                _ModelsTab(
                  providers: _providers,
                  providerService: _providerService,
                  onReload: _loadProviders,
                ),
                _SecurityTab(
                  settingsService: _settingsService,
                  apiClient: widget.apiClient,
                ),
              ],
            ),
    );
  }

  Future<void> _manageModels(ProviderRecord provider) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => ModelManagementScreen(
          providerName: provider.name,
          models: provider.models,
          activeModels: provider.activeModels,
          providerService: _providerService,
          onSave: _updateProviderModels,
        ),
      ),
    );
    if (result != null && mounted) {
      final models = result['models'] as Map<String, String>;
      final activeModels = result['activeModels'] as Map<String, bool>;
      setState(() {
        final idx = _providers.indexWhere((p) => p.name == provider.name);
        if (idx >= 0) {
          _providers[idx].models
            ..clear()
            ..addAll(models);
          _providers[idx].activeModels
            ..clear()
            ..addAll(activeModels);
        }
      });
      _loadProviders();
    }
  }

  Future<void> _updateProviderModels(String name, Map<String, String> models, Map<String, bool> activeModels) async {
    final idx = _providers.indexWhere((p) => p.name == name);
    if (idx < 0) return;
    final updated = ProviderRecord(
      id: _providers[idx].id,
      name: _providers[idx].name,
      apiKey: _providers[idx].apiKey,
      baseUrl: _providers[idx].baseUrl,
      endpointPath: _providers[idx].endpointPath,
      models: models,
      activeModels: activeModels,
      headersTemplate: _providers[idx].headersTemplate,
      authType: _providers[idx].authType,
      authHeaderName: _providers[idx].authHeaderName,
      bodyTemplate: _providers[idx].bodyTemplate,
      responseContentPath: _providers[idx].responseContentPath,
      responseUsageInputPath: _providers[idx].responseUsageInputPath,
      responseUsageOutputPath: _providers[idx].responseUsageOutputPath,
      responseUsageCostPath: _providers[idx].responseUsageCostPath,
      isStreaming: _providers[idx].isStreaming,
      isActive: _providers[idx].isActive,
      maxRetries: _providers[idx].maxRetries,
      timeoutSeconds: _providers[idx].timeoutSeconds,
      maxConcurrent: _providers[idx].maxConcurrent,
    );
    await _providerService.updateProvider(name, updated);
  }

  Future<void> _openProviderForm(ProviderRecord? existing) async {
    final result = await Navigator.push<ProviderRecord>(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderFormScreen(
          existing: existing,
          providerService: _providerService,
        ),
      ),
    );
    if (result != null) {
      await _saveProvider(result);
    }
  }
}

class _ConnectionTab extends StatefulWidget {
  final ApiClient apiClient;
  final BackendConnectionService backendService;
  final VoidCallback onDisconnect;

  const _ConnectionTab({
    required this.apiClient,
    required this.backendService,
    required this.onDisconnect,
  });

  @override
  State<_ConnectionTab> createState() => _ConnectionTabState();
}

class _ConnectionTabState extends State<_ConnectionTab> {
  @override
  void initState() {
    super.initState();
    widget.backendService.addListener(_onServiceChanged);
    widget.backendService.startMonitoring();
  }

  @override
  void dispose() {
    widget.backendService.removeListener(_onServiceChanged);
    widget.backendService.stopMonitoring();
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _doReconnect() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Reconnect')),
          body: Center(
            child: ConnectContent(
              backendService: widget.backendService,
              apiClient: widget.apiClient,
              onConnected: () {
                if (!mounted) return;
                final url = widget.backendService.currentUrl;
                if (url != null) {
                  widget.apiClient.setBaseUrl(url);
                  final token = widget.backendService.token;
                  if (token != null) {
                    widget.apiClient.setToken(token);
                  }
                  widget.backendService.saveUrl(url);
                  widget.backendService.startMonitoring();
                }
                Navigator.pop(context, true);
              },
              initialUrl: widget.backendService.currentUrl,
            ),
          ),
        ),
      ),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.backendService;
    final connected = service.isConnected;
    final info = service.backendInfo;
    final url = service.currentUrl;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      connected ? Icons.check_circle : Icons.cloud_off,
                      color: connected ? Colors.green.shade600 : Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      connected ? 'Connected' : 'Disconnected',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                if (info != null) ...[
                  const SizedBox(height: 12),
                  _infoRow('Backend URL', url ?? '-'),
                  _infoRow('Name', info.message),
                  _infoRow('Version', info.version),
                  _infoRow('Status', info.status),
                  _infoRow('Server Time', info.timestamp),
                ] else if (url != null) ...[
                  const SizedBox(height: 12),
                  _infoRow('Stored URL', url),
                ],
                if (service.error != null && !connected) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning, size: 16, color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(service.error!,
                              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onErrorContainer)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _doReconnect,
                        icon: const Icon(Icons.wifi_find, size: 18),
                        label: const Text('Reconnect'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Disconnect'),
                              content: const Text('Clear backend connection?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    widget.onDisconnect();
                                  },
                                  child: const Text('Disconnect'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.link_off, size: 18),
                        label: const Text('Disconnect'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _ProvidersTab extends StatelessWidget {
  final List<ProviderRecord> providers;
  final Future<void> Function(String name) onDelete;
  final void Function(ProviderRecord) onEdit;
  final VoidCallback onAdd;
  final void Function(ProviderRecord) onManageModels;

  const _ProvidersTab({
    required this.providers,
    required this.onDelete,
    required this.onEdit,
    required this.onAdd,
    required this.onManageModels,
  });

  @override
  Widget build(BuildContext context) {
    if (providers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No providers configured'),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Provider'),
              onPressed: onAdd,
            ),
          ],
        ),
      );
    }
    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: providers.length,
          itemBuilder: (context, index) {
            final p = providers[index];
            final anyActive = p.activeModels.values.any((v) => v);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  anyActive || p.isActive
                      ? Icons.check_circle
                      : Icons.cloud,
                  color: anyActive || p.isActive ? Colors.green : null,
                ),
                title: Text(p.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  '${p.baseUrl}${p.endpointPath}\n'
                  'Auth: ${p.authType} | Models: ${p.models.length}',
                  style: const TextStyle(fontSize: 12),
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (action) {
                    switch (action) {
                      case 'edit':
                        onEdit(p);
                      case 'models':
                        onManageModels(p);
                      case 'delete':
                        _confirmDelete(context, p.name);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(
                        value: 'models', child: Text('Manage Models')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ),
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            heroTag: 'add_provider',
            onPressed: onAdd,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Provider'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete(name);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _SecurityTab extends StatefulWidget {
  final SettingsService settingsService;
  final ApiClient apiClient;

  const _SecurityTab({
    required this.settingsService,
    required this.apiClient,
  });

  @override
  State<_SecurityTab> createState() => _SecurityTabState();
}

class _SecurityTabState extends State<_SecurityTab> {
  Map<String, dynamic> _securityData = {};
  bool _loading = true;
  bool _refreshing = false;
  bool _saving = false;
  bool _togglingEncryption = false;
  late TextEditingController _tokenExpiryController;

  @override
  void initState() {
    super.initState();
    _tokenExpiryController = TextEditingController();
    _loadSecuritySettings().catchError((_) {});
  }

  @override
  void dispose() {
    _tokenExpiryController.dispose();
    super.dispose();
  }

  Future<void> _loadSecuritySettings() async {
    setState(() => _loading = true);
    try {
      final data = await widget.settingsService.getSecuritySettings();
      if (!mounted) return;
      setState(() {
        _securityData = data;
        _tokenExpiryController.text =
            data['access_token_expire_minutes']?.toString() ?? '60';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      rethrow;
    }
  }

  Future<void> _forceRefreshToken() async {
    setState(() => _refreshing = true);
    try {
      final result = await widget.settingsService.refreshToken();
      final newToken = result['access_token'] as String?;
      if (newToken != null) {
        widget.apiClient.setToken(newToken);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Token refreshed successfully'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to refresh token: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _saveTokenExpiry() async {
    final value = double.tryParse(_tokenExpiryController.text);
    if (value == null || value < 0.5 || value > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Token expiry must be between 0.5 and 10 minutes'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.settingsService.updateSecuritySettings({
        'access_token_expire_minutes': value.toString(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Token expiry saved'),
          backgroundColor: Colors.green.shade600,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleDbEncryption(bool enable) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Database Encryption'),
        content: Text(
          enable
              ? 'This will encrypt all existing database files. '
                  'The service will be temporarily unavailable during this process. Continue?'
              : 'This will decrypt all existing database files. '
                  'The service will be temporarily unavailable during this process. Continue?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _togglingEncryption = true);
    try {
      await widget.settingsService.updateSecuritySettings({
        'database_encryption_enabled': enable.toString(),
      });
      _securityData['database_encryption_enabled'] = enable;
      try {
        await _loadSecuritySettings();
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(enable ? 'Database encryption enabled' : 'Database encryption disabled'),
          backgroundColor: Colors.green.shade600,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to change encryption: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _togglingEncryption = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final dbEncrypted = _securityData['database_encryption_enabled'] == true;
    final dbCipherAvail = _securityData['database_encryption_available'] == true;
    final keyringAvail = _securityData['keyring_available'] == true;
    final keyringService = _securityData['keyring_service_name'] ?? 'Cognithor';
    final keyringKey = _securityData['keyring_key_name'] ?? 'db_key';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.timer, size: 20, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Token Refresh Time',
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tokenExpiryController,
                        decoration: const InputDecoration(
                          labelText: 'Expiry (minutes)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _saving ? null : _saveTokenExpiry,
                      child: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.refresh, size: 20, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Force Token Refresh',
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _refreshing ? null : _forceRefreshToken,
                    icon: _refreshing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 18),
                    label: Text(_refreshing ? 'Refreshing...' : 'Refresh Token Now'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lock, size: 20, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Payload Encryption',
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 12),
                _statusRow(
                  'Status',
                  widget.apiClient.token != null ? 'Enabled' : 'Disabled (no token)',
                  valueColor: widget.apiClient.token != null ? Colors.green : Colors.orange,
                ),
                const SizedBox(height: 4),
                _statusRow('Algorithm', 'AES-256-GCM'),
                const SizedBox(height: 4),
                _statusRow('Key Derivation', 'SHA-256(JWT)'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.storage, size: 20, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Database Encryption',
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Encryption Enabled',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Switch(
                      value: dbEncrypted,
                      onChanged: dbCipherAvail && !_togglingEncryption ? _toggleDbEncryption : null,
                    ),
                  ],
                ),
                if (_togglingEncryption)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(),
                  ),
                const SizedBox(height: 4),
                _statusRow(
                  'Cipher Available',
                  dbCipherAvail ? 'Yes' : 'No',
                  valueColor: dbCipherAvail ? Colors.green : Colors.red,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.vpn_key, size: 20, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Keyring Management',
                        style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 12),
                _statusRow(
                  'Keyring Available',
                  keyringAvail ? 'Yes' : 'No',
                  valueColor: keyringAvail ? Colors.green : Colors.red,
                ),
                const SizedBox(height: 4),
                _statusRow('Service Name', keyringService),
                const SizedBox(height: 4),
                _statusRow('Key Name', keyringKey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusRow(
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              color: valueColor,
              fontWeight: valueColor != null ? FontWeight.w600 : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelsTab extends StatelessWidget {
  final List<ProviderRecord> providers;
  final ProviderService providerService;
  final VoidCallback onReload;

  const _ModelsTab({
    required this.providers,
    required this.providerService,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    final modelEntries = <_ModelEntry>[];
    for (final p in providers) {
      for (final e in p.models.entries) {
        modelEntries.add(_ModelEntry(
          providerName: p.name,
          modelName: e.key,
          modelId: e.value,
          isActive: p.activeModels[e.key] ?? false,
          providerService: providerService,
          onReload: onReload,
        ));
      }
    }

    if (modelEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.smart_toy, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('No models configured'),
            SizedBox(height: 4),
            Text('Add models via provider settings',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: modelEntries.length,
      itemBuilder: (context, index) => modelEntries[index],
    );
  }
}

class _ModelEntry extends StatefulWidget {
  final String providerName;
  final String modelName;
  final String modelId;
  final bool isActive;
  final ProviderService providerService;
  final VoidCallback onReload;

  const _ModelEntry({
    required this.providerName,
    required this.modelName,
    required this.modelId,
    required this.isActive,
    required this.providerService,
    required this.onReload,
  });

  @override
  State<_ModelEntry> createState() => _ModelEntryState();
}

class _ModelEntryState extends State<_ModelEntry> {
  late bool _active;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    _active = widget.isActive;
  }

  @override
  void didUpdateWidget(_ModelEntry old) {
    super.didUpdateWidget(old);
    _active = widget.isActive;
  }

  Future<void> _test() async {
    setState(() => _testing = true);
    try {
      final result = await widget.providerService.testModel(
        widget.providerName,
        widget.modelName,
      );
      if (!mounted) return;
      final available = result['available'] as bool? ?? false;
      setState(() => _active = available);
      widget.onReload();
      final latency = result['latency_ms'];
      final error = result['error'];
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Icon(
            available ? Icons.check_circle : Icons.error,
            color: available ? Colors.green : Colors.red,
            size: 40,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(available ? 'Model OK' : 'Model failed',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Provider: ${widget.providerName}'),
              Text('Model: ${widget.modelName} (${widget.modelId})'),
              if (latency != null)
                Text('Latency: ${(latency as num).toStringAsFixed(0)} ms'),
              if (result['output_tokens'] != null)
                Text('Output tokens: ${result['output_tokens']}'),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(error.toString(),
                      style: const TextStyle(fontSize: 13, color: Colors.red)),
                ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _active = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _active ? Icons.check_circle : Icons.radio_button_unchecked,
          color: _active ? Colors.green : Colors.grey,
          size: 20,
        ),
        title: Text(widget.modelName,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${widget.providerName}  |  ${widget.modelId}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: IconButton(
          icon: _testing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.wifi_find, size: 20),
          tooltip: 'Test connection',
          onPressed: _testing ? null : _test,
        ),
      ),
    );
  }
}
