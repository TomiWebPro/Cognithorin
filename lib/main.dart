import 'package:flutter/material.dart';
import 'services/api_service/api_client.dart';
import 'services/backend_service.dart';
import 'services/data_preloader.dart';
import 'onboarding_screens/connect_screen.dart';
import 'reuseable_widgets/setup_dialog.dart';
import 'dashboard/dashboard_screen.dart';

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
    _backendService.setApiClient(_apiClient);
    _backendService.onReconnected = () {
      if (mounted) setState(() {});
    };
    _init();
  }

  Future<void> _init() async {
    await _backendService.loadSavedUrl();
    if (_backendService.savedUrl != null) {
      _apiClient.setBaseUrl(_backendService.savedUrl!);

      final creds = await _backendService.loadCredentials();
      if (creds.$1 != null && creds.$2 != null) {
        final ok = await _backendService.tryConnect(
          _backendService.savedUrl!,
          username: creds.$1,
          password: creds.$2,
        );
        if (ok) {
          _apiClient.setToken(_backendService.token);
          _backendService.startMonitoring();
          if (!mounted) return;
          setState(() => _ready = true);
          _prefetchDashboard();
          return;
        }
      } else {
        final ok = await _backendService.tryConnect(_backendService.savedUrl!);
        if (ok) {
          _backendService.startMonitoring();
        }
      }
    }
    if (!mounted) return;
    setState(() => _ready = true);
  }

  Future<void> _prefetchDashboard() async {
    final preloader = DataPreloader(_apiClient);
    await preloader.preloadDashboardData();
    await preloader.preloadSettingsData();
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
    _prefetchDashboard();
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
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.deepPurple.withValues(alpha: 0.08),
            ),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.3),
          titleMedium: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.2),
          titleSmall: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.1),
          bodyLarge: TextStyle(letterSpacing: 0),
          bodyMedium: TextStyle(letterSpacing: 0),
          labelSmall: TextStyle(fontWeight: FontWeight.w500, letterSpacing: 0.3),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: Colors.deepPurple.withValues(alpha: 0.15),
            ),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 1,
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.3),
          titleMedium: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.2),
          titleSmall: TextStyle(fontWeight: FontWeight.w600, letterSpacing: -0.1),
          bodyLarge: TextStyle(letterSpacing: 0),
          bodyMedium: TextStyle(letterSpacing: 0),
          labelSmall: TextStyle(fontWeight: FontWeight.w500, letterSpacing: 0.3),
        ),
      ),
      themeMode: ThemeMode.system,
      home: !_ready
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
              : _backendService.isConnected
              ? DashboardScreen(
                  apiClient: _apiClient,
                  backendService: _backendService,
                  onDisconnect: _onDisconnect,
                )
              : SetupDialog(
                  child: ConnectContent(
                    backendService: _backendService,
                    onConnected: _onConnected,
                    apiClient: _apiClient,
                    initialUrl: _backendService.savedUrl,
                  ),
                ),
    );
  }
}
