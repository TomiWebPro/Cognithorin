import 'api_client.dart';

class SettingsService {
  final ApiClient _client;

  SettingsService(this._client);

  Future<Map<String, String>> getSettings() async {
    final data = await _client.get('/settings');
    return data.map((k, v) => MapEntry(k, v.toString()));
  }

  Future<Map<String, String>> updateSettings(Map<String, String> values) async {
    final data = await _client.put('/settings', body: values);
    return data.map((k, v) => MapEntry(k, v.toString()));
  }

  Future<List<Map<String, dynamic>>> getUsers() async {
    final list = await _client.getList('/settings/users');
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createUser(
      String username, String password) async {
    return _client.post('/settings/users', body: {
      'username': username,
      'password': password,
    });
  }

  Future<Map<String, dynamic>> changePassword(
      String oldPassword, String newPassword) async {
    return _client.put('/settings/users/me/password', body: {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }

  Future<Map<String, dynamic>> getSecuritySettings() async {
    return _client.get('/settings/security');
  }

  Future<void> updateSecuritySettings(Map<String, String> values) async {
    await _client.put('/settings/security', body: values);
  }

  Future<Map<String, dynamic>> refreshToken() async {
    return _client.post('/settings/token/refresh');
  }
}
