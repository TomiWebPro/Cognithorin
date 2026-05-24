import 'api_client.dart';

class AuthService {
  final ApiClient _client;

  AuthService(this._client);

  Future<bool> login(String username, String password) async {
    try {
      final response = await _client.post(
        '/token',
        body: {
          'username': username,
          'password': password,
        },
      );
      final token = response['access_token'] as String?;
      if (token != null) {
        _client.setToken(token);
        return true;
      }
      return false;
    } on ApiException {
      return false;
    }
  }

  void logout() {
    _client.setToken(null);
  }

  bool get isLoggedIn => _client.token != null;

  Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      return await _client.get('/users/me');
    } on ApiException {
      return null;
    }
  }
}
