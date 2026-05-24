import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service/api_client.dart';
import '../services/backend_service.dart';
import '../services/qr_scanner.dart';
import '../reuseable_widgets/qr_scanner_screen.dart';

class ConnectContent extends StatefulWidget {
  final BackendConnectionService backendService;
  final VoidCallback onConnected;
  final ApiClient apiClient;
  final String? initialUrl;

  const ConnectContent({
    super.key,
    required this.backendService,
    required this.onConnected,
    required this.apiClient,
    this.initialUrl,
  });

  @override
  State<ConnectContent> createState() => _ConnectContentState();
}

class _ConnectContentState extends State<ConnectContent> {
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passkeyController = TextEditingController();
  bool _isDetecting = false;
  bool _isLoggingIn = false;
  String? _error;
  String? _detectedUrl;
  OnboardingPasskey? _pendingPasskey;
  bool _showPasskeyInput = false;

  @override
  void initState() {
    super.initState();
    _usernameController.text = 'admin';

    if (widget.initialUrl != null) {
      final uri = Uri.parse(widget.initialUrl!);
      _hostController.text = uri.host;
      _portController.text = uri.port.toString();
      _error = 'Could not reach ${widget.initialUrl}';
    } else {
      _autoDetect();
    }
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _passkeyController.dispose();
    super.dispose();
  }

  Future<void> _autoDetect() async {
    setState(() {
      _isDetecting = true;
      _error = null;
      _detectedUrl = null;
    });

    final detected = await widget.backendService.autoDetect();

    if (!mounted) return;

    setState(() {
      _isDetecting = false;
      if (detected != null) {
        _detectedUrl = detected;
      } else {
        _error =
            'No backend found on common ports. Enter address manually or scan/paste a passkey.';
      }
    });
  }

  void _processQrText(String text) {
    if (text.startsWith('http://') || text.startsWith('https://')) {
      final uri = Uri.parse(text);
      _hostController.text = uri.host;
      _portController.text = uri.port.toString();
      _error = null;
      setState(() => _pendingPasskey = null);
      _testConnection();
    } else {
      final passkey = OnboardingPasskey.decode(text);
      if (passkey != null) {
        _processPasskey(passkey);
      } else {
        setState(() {
          _error = 'Scanned QR does not contain a valid URL or passkey';
        });
      }
    }
  }

  void _processPasskey(OnboardingPasskey passkey) {
    _hostController.text = passkey.host;
    _portController.text = passkey.port.toString();
    _usernameController.text = passkey.username;
    _passwordController.text = passkey.password;
    _pendingPasskey = passkey;
    _error = null;
    setState(() {});
    _testConnection();
  }

  Future<void> _scanWithCamera() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const QrScannerScreen(),
      ),
    );

    if (!mounted || result == null) return;
    _processQrText(result);
  }

  Future<void> _pickAndScanQr() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg'],
    );
    if (result == null || result.files.single.path == null) return;

    final path = result.files.single.path!;
    final text = await decodeQrFromFile(path);

    if (!mounted) return;

    if (text != null) {
      _processQrText(text);
    } else {
      setState(() {
        _error = 'Could not decode QR code from file';
      });
    }
  }

  Future<void> _applyPasskey() async {
    final text = _passkeyController.text.trim();
    if (text.isEmpty) return;

    final passkey = OnboardingPasskey.decode(text);
    if (passkey != null) {
      _processPasskey(passkey);
    } else {
      setState(() {
        _error = 'Invalid passkey format';
      });
    }
  }

  String _buildUrl() {
    final host = _hostController.text.trim();
    final port = _portController.text.trim();
    if (host.isEmpty) return '';
    if (port.isEmpty) return 'http://$host';
    return 'http://$host:$port';
  }

  Future<void> _testConnection() async {
    final url = _buildUrl();
    if (url.isEmpty) return;

    setState(() {
      _isDetecting = true;
      _error = null;
    });

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final creds = username.isNotEmpty && password.isNotEmpty
        ? (username, password)
        : null;
    final success = await widget.backendService.tryConnect(
      url,
      username: creds?.$1,
      password: creds?.$2,
    );

    if (!mounted) return;

    setState(() {
      _isDetecting = false;
      if (success) {
        _detectedUrl = url;
        if (creds != null) {
          widget.backendService.saveUrl(url);
          widget.apiClient.setBaseUrl(url);
          widget.apiClient.setToken(widget.backendService.token);
          widget.onConnected();
        }
      } else {
        _error = widget.backendService.error ?? 'Connection failed';
      }
    });
  }

  Future<void> _login() async {
    final url = _detectedUrl;
    if (url == null) return;

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = 'Username and password are required');
      return;
    }

    setState(() {
      _isLoggingIn = true;
      _error = null;
    });

    final token = await widget.backendService.login(username, password);

    if (!mounted) return;

    if (token != null) {
      widget.backendService.setToken(token);
      widget.apiClient.setToken(token);
      await widget.backendService.saveUrl(url);
      if (!mounted) return;
      widget.onConnected();
    } else {
      setState(() {
        _isLoggingIn = false;
        _error = 'Login failed. Check credentials.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.psychology,
            size: 48,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            'Cognithor',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            'Connect to your backend',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          if (_isDetecting)
            const Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Scanning for backend...'),
              ],
            )
          else if (_detectedUrl != null && widget.backendService.backendInfo != null)
            _buildConnectedCard()
          else
            _buildManualEntry(),
        ],
      ),
    );
  }

  Widget _buildConnectedCard() {
    final info = widget.backendService.backendInfo!;

    return Column(
      children: [
        Icon(Icons.check_circle, color: Colors.green.shade600, size: 48),
        const SizedBox(height: 8),
        Text(
          'Backend Found',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          _detectedUrl!,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        if (_pendingPasskey != null) ...[
          const SizedBox(height: 4),
          Text(
            'Passkey loaded',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.green.shade600,
                ),
          ),
        ],
        const Divider(height: 24),
        _infoRow('Name', info.message),
        _infoRow('Version', info.version),
        _infoRow('Status', info.status),
        _infoRow('Time', info.timestamp),
        const SizedBox(height: 16),
        TextField(
          controller: _usernameController,
          decoration: const InputDecoration(
            labelText: 'Username',
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          decoration: const InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          obscureText: true,
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _isLoggingIn ? null : _login,
          icon: _isLoggingIn
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.login),
          label: Text(_isLoggingIn ? 'Logging in...' : 'Login'),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => setState(() {
            _detectedUrl = null;
            _pendingPasskey = null;
            _error = null;
          }),
          icon: const Icon(Icons.close, size: 18),
          label: const Text('Choose Different'),
        ),
      ],
    );
  }

  Widget _buildManualEntry() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_error != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning,
                  size: 18,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _error!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Text(
          'Manual Entry',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _hostController,
                decoration: const InputDecoration(
                  labelText: 'IP / Host',
                  hintText: '192.168.1.100',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: TextField(
                controller: _portController,
                decoration: const InputDecoration(
                  labelText: 'Port',
                  hintText: '8000',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _testConnection,
          icon: const Icon(Icons.wifi_find, size: 18),
          label: const Text('Test Connection'),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _autoDetect,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Retry Auto-Detect'),
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: _scanWithCamera,
          icon: const Icon(Icons.camera_alt, size: 18),
          label: const Text('Scan with Camera'),
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: _pickAndScanQr,
          icon: const Icon(Icons.folder_open, size: 18),
          label: const Text('Load QR from File'),
        ),
        const SizedBox(height: 4),
        TextButton.icon(
          onPressed: () =>
              setState(() => _showPasskeyInput = !_showPasskeyInput),
          icon: const Icon(Icons.vpn_key, size: 18),
          label: const Text('Paste Passkey'),
        ),
        if (_showPasskeyInput) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _passkeyController,
            decoration: const InputDecoration(
              labelText: 'Paste passkey here',
              hintText: 'Base64-encoded passkey from server',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            maxLines: 3,
            style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _applyPasskey,
            icon: const Icon(Icons.key, size: 18),
            label: const Text('Apply Passkey'),
          ),
        ],
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
