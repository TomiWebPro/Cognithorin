import 'api_client.dart';
import 'models.dart';

class AppService {
  final ApiClient _client;

  AppService(this._client);

  Future<List<AppRecord>> getApps({bool all = false}) async {
    final path = all ? '/apps/all' : '/apps';
    final list = await _client.getList(path);
    return list
        .map((e) => AppRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AppRecord> getApp(String appId) async {
    final data = await _client.get('/apps/$appId');
    return AppRecord.fromJson(data);
  }

  Future<AppRecord> registerApp(Map<String, dynamic> body) async {
    final data = await _client.post('/apps', body: body);
    return AppRecord.fromJson(data);
  }

  Future<void> unregisterApp(String appId) async {
    await _client.delete('/apps/$appId');
  }

  Future<AppRecord> updateApp(String appId, Map<String, dynamic> body) async {
    final data = await _client.put('/apps/$appId', body: body);
    return AppRecord.fromJson(data);
  }

  Future<List<AgentAppRecord>> getAgentApps(String agentId,
      {bool enabledOnly = false}) async {
    final path = enabledOnly
        ? '/agents/$agentId/apps/enabled'
        : '/agents/$agentId/apps';
    final list = await _client.getList(path);
    return list
        .map((e) => AgentAppRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AgentAppRecord> installApp(
    String agentId,
    String appId, {
    String? config,
  }) async {
    final data = await _client.post(
      '/agents/$agentId/apps',
      body: {
        'app_id': appId,
        'config': config,
      },
    );
    return AgentAppRecord.fromJson(data);
  }

  Future<AgentAppRecord> getAgentApp(String agentId, String appId) async {
    final data = await _client.get('/agents/$agentId/apps/$appId');
    return AgentAppRecord.fromJson(data);
  }

  Future<void> uninstallApp(String agentId, String appId) async {
    await _client.delete('/agents/$agentId/apps/$appId');
  }

  Future<AgentAppRecord> enableApp(String agentId, String appId) async {
    final data =
        await _client.put('/agents/$agentId/apps/$appId/enable');
    return AgentAppRecord.fromJson(data);
  }

  Future<AgentAppRecord> disableApp(String agentId, String appId) async {
    final data =
        await _client.put('/agents/$agentId/apps/$appId/disable');
    return AgentAppRecord.fromJson(data);
  }

  Future<AgentAppRecord> setAppConfig(
    String agentId,
    String appId,
    Map<String, dynamic> config,
  ) async {
    final data = await _client.put(
      '/agents/$agentId/apps/$appId/config',
      body: {'config': config},
    );
    return AgentAppRecord.fromJson(data);
  }
}
