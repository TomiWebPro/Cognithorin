import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class BackendInfo {
  final String message;
  final String status;
  final String version;
  final String timestamp;

  BackendInfo({
    required this.message,
    required this.status,
    required this.version,
    required this.timestamp,
  });

  factory BackendInfo.fromJson(Map<String, dynamic> json) => BackendInfo(
        message: json['message'] as String? ?? '',
        status: json['status'] as String? ?? '',
        version: json['version'] as String? ?? '',
        timestamp: json['timestamp'] as String? ?? '',
      );
}

class OnboardingPasskey {
  final String host;
  final int port;
  final String username;
  final String password;
  final bool encryptionAvailable;

  OnboardingPasskey({
    required this.host,
    required this.port,
    required this.username,
    required this.password,
    this.encryptionAvailable = true,
  });

  factory OnboardingPasskey.fromJson(Map<String, dynamic> json) =>
      OnboardingPasskey(
        host: json['host'] as String? ?? '',
        port: json['port'] as int? ?? 8000,
        username: json['username'] as String? ?? '',
        password: json['password'] as String? ?? '',
        encryptionAvailable: json['encryption_available'] as bool? ?? true,
      );

  static OnboardingPasskey? decode(String input) {
    try {
      final decoded = utf8.decode(base64.decode(input));
      final json = jsonDecode(decoded) as Map<String, dynamic>;
      return OnboardingPasskey.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  static bool isPasskeyFormat(String input) {
    try {
      base64.decode(input);
      return true;
    } catch (_) {
      return false;
    }
  }
}

enum ConnectionStatus { disconnected, connecting, connected, failed }

class BackendConnectionService extends ChangeNotifier {
  static const _keySavedUrl = 'backend_url';
  static const _defaultUrls = [
    'http://localhost:4464',
    'http://localhost:8000',
    'http://127.0.0.1:4464',
    'http://127.0.0.1:8000',
    'http://localhost:8080',
    'http://127.0.0.1:8080',
  ];

  String? _savedUrl;
  String? _currentUrl;
  ConnectionStatus _status = ConnectionStatus.disconnected;
  BackendInfo? _backendInfo;
  String? _error;
  String? _token;

  String? get savedUrl => _savedUrl;
  String? get currentUrl => _currentUrl;
  ConnectionStatus get status => _status;
  BackendInfo? get backendInfo => _backendInfo;
  String? get error => _error;
  bool get isConnected => _status == ConnectionStatus.connected;
  String? get token => _token;

  void setToken(String? token) {
    _token = token;
  }

  Future<void> loadSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    _savedUrl = prefs.getString(_keySavedUrl);
  }

  Future<bool> tryConnect(String url, {String? username, String? password}) async {
    _status = ConnectionStatus.connecting;
    _currentUrl = url;
    _error = null;
    notifyListeners();

    try {
      final uri = Uri.parse(url);
      final response = await http.get(uri).timeout(
        const Duration(seconds: 5),
      );

      if (response.statusCode != 200) {
        _status = ConnectionStatus.failed;
        _error = 'Server returned status ${response.statusCode}';
        notifyListeners();
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      _backendInfo = BackendInfo.fromJson(data);

      if (username != null && password != null) {
        final token = await login(username, password);
        if (token == null) {
          _status = ConnectionStatus.failed;
          _error = 'Authentication failed';
          notifyListeners();
          return false;
        }
        _token = token;

        final authUri = Uri.parse('$url/users/me');
        final authResponse = await http.get(
          authUri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ).timeout(const Duration(seconds: 5));

        if (authResponse.statusCode != 200) {
          _status = ConnectionStatus.failed;
          _error = 'Authenticated channel not available';
          notifyListeners();
          return false;
        }
      }

      _status = ConnectionStatus.connected;
      notifyListeners();
      return true;
    } catch (e) {
      _status = ConnectionStatus.failed;
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<String?> autoDetect() async {
    for (final url in _defaultUrls) {
      final success = await tryConnect(url);
      if (success) return url;
    }
    return null;
  }

  Future<void> saveUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySavedUrl, url);
    _savedUrl = url;
    _currentUrl = url;
  }

  Future<void> clearSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySavedUrl);
    _savedUrl = null;
  }

  Timer? _monitorTimer;

  void startMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkHealth(),
    );
  }

  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
  }

  void _setDisconnected() {
    _status = ConnectionStatus.disconnected;
    _backendInfo = null;
    _error = 'Connection lost';
    notifyListeners();
  }

  Future<void> _checkHealth() async {
    if (_currentUrl == null || _status != ConnectionStatus.connected) return;

    try {
      final healthUri = Uri.parse('$_currentUrl/health');
      final healthResponse = await http.get(healthUri).timeout(
        const Duration(seconds: 3),
      );

      if (healthResponse.statusCode != 200) {
        _setDisconnected();
        return;
      }

      final authUri = Uri.parse('$_currentUrl/users/me');
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (_token != null) {
        headers['Authorization'] = 'Bearer $_token';
      }
      final authResponse = await http.get(authUri, headers: headers).timeout(
        const Duration(seconds: 3),
      );

      if (authResponse.statusCode != 200) {
        _setDisconnected();
        return;
      }
    } catch (_) {
      _setDisconnected();
    }
  }

  Future<String?> login(String username, String password) async {
    if (_currentUrl == null) return null;
    try {
      final body = <String, dynamic>{'username': username, 'password': password};
      final headers = <String, String>{'Content-Type': 'application/json'};

      final uri = Uri.parse('$_currentUrl/token');
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['access_token'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  void disconnect() {
    stopMonitoring();
    _status = ConnectionStatus.disconnected;
    _currentUrl = null;
    _backendInfo = null;
    _error = null;
    _token = null;
    notifyListeners();
  }
}
