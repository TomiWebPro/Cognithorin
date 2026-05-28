import 'api_client.dart';
import 'models.dart';

class AgentService {
  final ApiClient _client;

  AgentService(this._client);

  Future<List<AgentRecord>> getAgents() async {
    final list = await _client.getList('/agents');
    return list
        .map((e) => AgentRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AgentRecord> getAgent(String agentId) async {
    final data = await _client.get('/agents/$agentId');
    return AgentRecord.fromJson(data);
  }

  Future<AgentRecord> createAgent(Map<String, dynamic> body) async {
    final data = await _client.post('/agents', body: body);
    return AgentRecord.fromJson(data);
  }

  Future<AgentRecord> updateAgent(
      String agentId, Map<String, dynamic> body) async {
    final data = await _client.put('/agents/$agentId', body: body);
    return AgentRecord.fromJson(data);
  }

  Future<void> deleteAgent(String agentId) async {
    await _client.delete('/agents/$agentId');
  }
}
