import 'api_client.dart';
import 'models.dart';

class ProviderService {
  final ApiClient _client;

  ProviderService(this._client);

  Future<List<ProviderRecord>> getProviders() async {
    final list = await _client.getList('/providers');
    return list
        .map((e) => ProviderRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProviderRecord> getProvider(String name) async {
    final data = await _client.get('/providers/$name');
    return ProviderRecord.fromJson(data);
  }

  Future<ProviderRecord> createProvider(ProviderRecord record) async {
    final data = await _client.post('/providers', body: record.toJson());
    return ProviderRecord.fromJson(data);
  }

  Future<ProviderRecord> updateProvider(
      String name, ProviderRecord record) async {
    final data =
        await _client.put('/providers/$name', body: record.toJson());
    return ProviderRecord.fromJson(data);
  }

  Future<void> deleteProvider(String name) async {
    await _client.delete('/providers/$name');
  }

  Future<Map<String, dynamic>> testProvider(String name) async {
    return _client.post('/providers/$name/test', body: <String, dynamic>{});
  }

  Future<Map<String, dynamic>> testModel(String provider, String model) async {
    return _client.post('/providers/$provider/test-model/$model');
  }
}
