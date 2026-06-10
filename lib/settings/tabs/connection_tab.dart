import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service/api_client.dart';
import '../../services/backend_service.dart';
import '../../onboarding_screens/connect_screen.dart';

class ConnectionTab extends StatefulWidget {
  final ApiClient apiClient;
  final BackendConnectionService backendService;
  final VoidCallback onDisconnect;

  const ConnectionTab({
    super.key,
    required this.apiClient,
    required this.backendService,
    required this.onDisconnect,
  });

  @override
  State<ConnectionTab> createState() => _ConnectionTabState();
}

class _ConnectionTabState extends State<ConnectionTab> {
  Map<String, dynamic>? _passkeyData;
  String? _passkeyString;
  bool _loadingPasskey = false;

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
    if (widget.backendService.isConnected) {
      _fetchPasskey();
    } else {
      _passkeyData = null;
      _passkeyString = null;
    }
  }

  Future<void> _fetchPasskey() async {
    setState(() => _loadingPasskey = true);
    try {
      final data = await widget.apiClient.get('/onboarding/passkey');
      final passkeyStr = data['passkey'] as String?;
      Map<String, dynamic>? decoded;
      if (passkeyStr != null) {
        try {
          final raw = utf8.decode(base64.decode(passkeyStr));
          decoded = jsonDecode(raw) as Map<String, dynamic>;
        } catch (_) {}
      }
      if (!mounted) return;
      setState(() {
        _passkeyString = passkeyStr;
        _passkeyData = decoded;
        _loadingPasskey = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _passkeyData = null;
          _passkeyString = null;
          _loadingPasskey = false;
        });
      }
    }
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

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard'), backgroundColor: Colors.green.shade600),
    );
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
                              style: TextStyle(
                                  fontSize: 12, color: Theme.of(context).colorScheme.onErrorContainer)),
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
                                    child: const Text('Cancel')),
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
        if (connected) ...[
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
                      Text('Connection Info', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  if (_loadingPasskey)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: LinearProgressIndicator(),
                    )
                  else if (_passkeyData != null) ...[
                    const SizedBox(height: 12),
                    _infoRow('Host', '${_passkeyData!['host'] ?? '-'}:${_passkeyData!['port'] ?? '-'}'),
                    _infoRow('Username', _passkeyData!['username']?.toString() ?? '-'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        TextButton.icon(
                          onPressed: () => _copyToClipboard(_passkeyData!['password']?.toString() ?? '', 'Password'),
                          icon: const Icon(Icons.copy, size: 14),
                          label: const Text('Copy', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    if (_passkeyString != null) ...[
                      const Text('Passkey', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: SelectableText(
                          _passkeyString!,
                          style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _copyToClipboard(_passkeyString!, 'Passkey'),
                          icon: const Icon(Icons.copy, size: 14),
                          label: const Text('Copy Passkey', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ] else
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Could not load passkey', style: TextStyle(fontSize: 13, color: Colors.grey)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
