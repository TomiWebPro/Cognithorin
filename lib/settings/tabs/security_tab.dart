import 'package:flutter/material.dart';
import '../../services/api_service/api_client.dart';
import '../../services/api_service/settings_service.dart';

class SecurityTab extends StatefulWidget {
  final SettingsService settingsService;
  final ApiClient apiClient;

  const SecurityTab({
    super.key,
    required this.settingsService,
    required this.apiClient,
  });

  @override
  State<SecurityTab> createState() => _SecurityTabState();
}

class _SecurityTabState extends State<SecurityTab> {
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
            data['access_token_expire_minutes']?.toString() ?? '10';
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
              backgroundColor: Colors.green.shade600),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to refresh token: $e'),
            backgroundColor: Theme.of(context).colorScheme.error),
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
            backgroundColor: Theme.of(context).colorScheme.error),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.settingsService
          .updateSecuritySettings({'access_token_expire_minutes': value.toString()});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('Token expiry saved'),
            backgroundColor: Colors.green.shade600),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Theme.of(context).colorScheme.error),
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
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _togglingEncryption = true);
    try {
      await widget.settingsService
          .updateSecuritySettings({'database_encryption_enabled': enable.toString()});
      _securityData['database_encryption_enabled'] = enable;
      try {
        await _loadSecuritySettings();
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(enable ? 'Database encryption enabled' : 'Database encryption disabled'),
            backgroundColor: Colors.green.shade600),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to change encryption: $e'),
            backgroundColor: Theme.of(context).colorScheme.error),
      );
    } finally {
      if (mounted) setState(() => _togglingEncryption = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

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
                    Text('Token Refresh Time', style: Theme.of(context).textTheme.titleMedium),
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
                            isDense: true),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _saving ? null : _saveTokenExpiry,
                      child: _saving
                          ? const SizedBox(
                              width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
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
                    Text('Force Token Refresh', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _refreshing ? null : _forceRefreshToken,
                    icon: _refreshing
                        ? const SizedBox(
                            width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
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
                    Text('Payload Encryption', style: Theme.of(context).textTheme.titleMedium),
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
                    Text('Database Encryption', style: Theme.of(context).textTheme.titleMedium),
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
                    Text('Keyring Management', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 12),
                _statusRow('Keyring Available', keyringAvail ? 'Yes' : 'No',
                    valueColor: keyringAvail ? Colors.green : Colors.red),
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

  Widget _statusRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
                fontSize: 13, color: valueColor, fontWeight: valueColor != null ? FontWeight.w600 : null),
          ),
        ],
      ),
    );
  }
}
