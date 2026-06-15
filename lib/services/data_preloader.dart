import 'api_service/api_client.dart';
import 'api_service/provider_service.dart';
import 'api_service/agent_service.dart';
import 'api_service/app_service.dart';
import 'api_service/runtime_service.dart';
import 'cache_service.dart';

class DataPreloader {
  final ApiClient _apiClient;
  final DataCache _cache;

  DataPreloader(this._apiClient) : _cache = DataCache.instance;

  Future<void> preloadSettingsData() async {
    final providerService = ProviderService(_apiClient);
    final agentService = AgentService(_apiClient);
    final appService = AppService(_apiClient);

    await Future.wait([
      _preloadProviders(providerService),
      _preloadAgents(agentService),
      _preloadApps(appService),
    ]);
  }

  Future<void> preloadDashboardData() async {
    final runtimeService = RuntimeService(_apiClient);
    try {
      final runtimes = await runtimeService.getAllRuntimes();
      _cache.set('dashboard:runtimes', runtimes, group: 'runtimes');
    } catch (_) {}
  }

  Future<void> _preloadProviders(ProviderService service) async {
    try {
      final providers = await service.getProviders();
      _cache.set('settings:providers', providers, group: 'providers');
    } catch (_) {}
  }

  Future<void> _preloadAgents(AgentService service) async {
    try {
      final agents = await service.getAgents();
      _cache.set('settings:agents', agents, group: 'agents');
    } catch (_) {}
  }

  Future<void> _preloadApps(AppService service) async {
    try {
      final apps = await service.getApps(all: true);
      _cache.set('settings:apps', apps, group: 'apps');
    } catch (_) {}
  }
}
