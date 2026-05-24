import 'package:flutter/material.dart';
import 'services/api_service/api_client.dart';
import 'services/backend_service.dart';
import 'onboarding_screens/connect_screen.dart';
import 'settings/settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _apiClient = ApiClient(baseUrl: 'http://localhost:4464');
  final _backendService = BackendConnectionService();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _backendService.loadSavedUrl();
    if (_backendService.savedUrl != null) {
      _apiClient.setBaseUrl(_backendService.savedUrl!);
      final ok = await _backendService.tryConnect(_backendService.savedUrl!);
      if (ok) {
        _backendService.startMonitoring();
      }
    }
    if (!mounted) return;
    setState(() => _ready = true);
  }

  void _onConnected() {
    final url = _backendService.currentUrl;
    if (url == null) return;

    _apiClient.setBaseUrl(url);
    final token = _backendService.token;
    if (token != null) {
      _apiClient.setToken(token);
    }
    _backendService.startMonitoring();
    if (!mounted) return;
    setState(() {});
  }

  void _onDisconnect() {
    _backendService.disconnect();
    _apiClient.setToken(null);
    _apiClient.setBaseUrl('http://localhost:4464');
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _backendService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cognithor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: !_ready
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : _backendService.isConnected
              ? SettingsScreen(
                  apiClient: _apiClient,
                  backendService: _backendService,
                  onDisconnect: _onDisconnect,
                )
              : Scaffold(
                  appBar: AppBar(title: const Text('Cognithor')),
                  body: Center(
                    child: ConnectContent(
                      backendService: _backendService,
                      onConnected: _onConnected,
                      apiClient: _apiClient,
                      initialUrl: _backendService.savedUrl,
                    ),
                  ),
                ),
    );
  }
}
