import 'api_client.dart';
import 'models.dart';

class RuntimeService {
  final ApiClient _client;
  RuntimeService(this._client);

  Future<List<AgentRuntime>> getAllRuntimes() async {
    final list = await _client.getList('/agents/runtime');
    return list
        .map((e) => AgentRuntime.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AgentRuntime> getAgentRuntime(String agentId) async {
    final data = await _client.get('/agents/$agentId/runtime');
    return AgentRuntime.fromJson(data);
  }

  Future<Map<String, dynamic>> getAgentContext(String agentId) async {
    final data = await _client.get('/agents/$agentId/context');
    return {
      'context': data['context'] as String? ?? '',
      'last_updated': data['last_updated'] as String?,
    };
  }
}
