import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

import '../encryption_service.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  String _baseUrl;
  String? _token;
  Uint8List? _derivedKey;
  final Duration _timeout;
  void Function()? onUnauthorized;

  ApiClient({this._baseUrl = 'http://localhost:8000', Duration? timeout})
      : _timeout = timeout ?? const Duration(seconds: 60);

  String get baseUrl => _baseUrl;

  void setBaseUrl(String url) {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  void setToken(String? token) {
    _token = token;
    _derivedKey = token != null ? EncryptionService.deriveKey(token) : null;
  }

  String? get token => _token;
  Uint8List? get derivedKey => _derivedKey;

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  Map<String, dynamic> _encryptBody(Map<String, dynamic> body) {
    if (_derivedKey == null) return body;
    final jsonStr = jsonEncode(body);
    return Map<String, dynamic>.from(
      EncryptionService.encrypt(jsonStr, _derivedKey!),
    );
  }

  Future<Map<String, dynamic>> _decryptResponse(http.Response response) async {
    if (_derivedKey == null || response.body.isEmpty) {
      return _handleResponse(response);
    }
    try {
      final encPayload = jsonDecode(response.body) as Map<String, dynamic>;
      final plaintext = EncryptionService.decrypt(encPayload, _derivedKey!);
      return jsonDecode(plaintext) as Map<String, dynamic>;
    } catch (_) {
      return _handleResponse(response);
    }
  }

  Future<Map<String, dynamic>> postRaw(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    final response = await http
        .post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(_timeout);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    final uri =
        Uri.parse('$_baseUrl$path').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: headers).timeout(_timeout);
    return _decryptResponse(response);
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final requestBody = body != null ? _encryptBody(body) : null;
    final response = await http
        .post(
          uri,
          headers: _headers,
          body: requestBody != null ? jsonEncode(requestBody) : null,
        )
        .timeout(_timeout);
    return _decryptResponse(response);
  }

  Future<Map<String, dynamic>> postForm(
    String path, {
    required Map<String, String> fields,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = <String, String>{
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    final response = await http
        .post(
          uri,
          headers: headers,
          body: fields,
        )
        .timeout(_timeout);
    return _decryptResponse(response);
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final requestBody = body != null ? _encryptBody(body) : null;
    final response = await http
        .put(
          uri,
          headers: _headers,
          body: requestBody != null ? jsonEncode(requestBody) : null,
        )
        .timeout(_timeout);
    return _decryptResponse(response);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final uri = Uri.parse('$_baseUrl$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    final response =
        await http.delete(uri, headers: headers).timeout(_timeout);
    return _decryptResponse(response);
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return {};
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    if (response.statusCode == 401) {
      onUnauthorized?.call();
    }

    String message;
    try {
      final body = jsonDecode(response.body);
      message = body['detail'] as String? ??
          response.reasonPhrase ??
          'Unknown error';
    } catch (_) {
      message = response.reasonPhrase ?? 'Unknown error';
    }
    throw ApiException(response.statusCode, message);
  }

  Future<List<dynamic>> getList(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    final uri =
        Uri.parse('$_baseUrl$path').replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: headers).timeout(_timeout);

    if (_derivedKey == null || response.body.isEmpty) {
      return _handleListResponse(response);
    }
    final encPayload = jsonDecode(response.body) as Map<String, dynamic>;
    final plaintext = EncryptionService.decrypt(encPayload, _derivedKey!);
    final data = jsonDecode(plaintext);
    if (data is List) return data;
    return [data];
  }

  List<dynamic> _handleListResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return [];
      return jsonDecode(response.body) as List<dynamic>;
    }

    if (response.statusCode == 401) {
      onUnauthorized?.call();
    }

    String message;
    try {
      final body = jsonDecode(response.body);
      message = body['detail'] as String? ??
          response.reasonPhrase ??
          'Unknown error';
    } catch (_) {
      message = response.reasonPhrase ?? 'Unknown error';
    }
    throw ApiException(response.statusCode, message);
  }
}
