import 'api_client.dart';

class StatsService {
  final ApiClient _client;
  StatsService(this._client);

  Future<Map<String, dynamic>> getTokenUsage({
    List<String>? periods,
    String? agentId,
  }) async {
    final params = <String, String>{};
    if (periods != null && periods.isNotEmpty) {
      params['periods'] = periods.join(',');
    }
    if (agentId != null) {
      params['agent_id'] = agentId;
    }
    final data = await _client.get('/stats/tokens', queryParams: params);
    return data;
  }

  Future<Map<String, dynamic>> getTokenUsageByAgent({
    List<String>? periods,
  }) async {
    final params = <String, String>{};
    if (periods != null && periods.isNotEmpty) {
      params['periods'] = periods.join(',');
    }
    final data = await _client.get('/stats/tokens/by-agent', queryParams: params);
    return data;
  }

  Future<Map<String, dynamic>> getTiming({
    List<String>? periods,
    String? agentId,
  }) async {
    final params = <String, String>{};
    if (periods != null && periods.isNotEmpty) {
      params['periods'] = periods.join(',');
    }
    if (agentId != null) {
      params['agent_id'] = agentId;
    }
    final data = await _client.get('/stats/timing', queryParams: params);
    return data;
  }

  Future<Map<String, dynamic>> getTimingByAgent({
    List<String>? periods,
  }) async {
    final params = <String, String>{};
    if (periods != null && periods.isNotEmpty) {
      params['periods'] = periods.join(',');
    }
    final data = await _client.get('/stats/timing/by-agent', queryParams: params);
    return data;
  }
}
