import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service/api_client.dart';
import '../services/api_service/provider_service.dart';
import '../services/api_service/agent_service.dart';
import '../services/api_service/settings_service.dart';
import '../services/api_service/app_service.dart';
import '../services/api_service/models.dart';
import '../services/backend_service.dart';
import 'provider_form_screen.dart';
import 'model_management_screen.dart';
import 'tabs/connection_tab.dart';
import 'tabs/providers_tab.dart';
import 'tabs/models_tab.dart';
import 'tabs/agents_tab.dart';
import 'tabs/apps_tab.dart';
import 'tabs/notes_tab.dart';
import 'tabs/diary_tab.dart';
import 'tabs/alarms_tab.dart';
import 'tabs/time_tab.dart';
import 'tabs/security_tab.dart';

class SettingsScreen extends StatefulWidget {
  final ApiClient apiClient;
  final BackendConnectionService backendService;
  final VoidCallback onDisconnect;

  const SettingsScreen({
    super.key,
    required this.apiClient,
    required this.backendService,
    required this.onDisconnect,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late final ProviderService _providerService;
  late final AgentService _agentService;
  late final SettingsService _settingsService;
  late final AppService _appService;
  late final TabController _tabController;

  final List<ProviderRecord> _providers = [];
  final List<AgentRecord> _agents = [];
  final List<AppRecord> _apps = [];
  bool _loading = true;
  bool _sidebarExpanded = true;

  @override
  void initState() {
    super.initState();
    _providerService = ProviderService(widget.apiClient);
    _agentService = AgentService(widget.apiClient);
    _settingsService = SettingsService(widget.apiClient);
    _appService = AppService(widget.apiClient);
    _tabController = TabController(length: 10, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadAll();
    widget.backendService.addListener(_onBackendChanged);
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.backendService.removeListener(_onBackendChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onBackendChanged() {
    if (widget.backendService.isConnected) {
      _loadAll();
    }
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    await Future.wait([_loadProviders(), _loadAgents(), _loadApps()]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadProviders() async {
    try {
      final providers = await _providerService.getProviders();
      if (!mounted) return;
      setState(() => _providers..clear()..addAll(providers));
    } catch (_) {}
  }

  Future<void> _loadAgents() async {
    try {
      final agents = await _agentService.getAgents();
      if (!mounted) return;
      setState(() => _agents..clear()..addAll(agents));
    } catch (_) {}
  }

  Future<void> _loadApps() async {
    try {
      final apps = await _appService.getApps(all: true);
      if (!mounted) return;
      setState(() => _apps..clear()..addAll(apps));
    } catch (_) {}
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green.shade600),
    );
  }

  Future<void> _deleteAgent(String agentId) async {
    try {
      await _agentService.deleteAgent(agentId);
      setState(() => _agents.removeWhere((a) => a.agentId == agentId));
      _showSuccess('Agent deleted');
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _addAgent() {
    final nameCtrl = TextEditingController();
    final cwCtrl = TextEditingController(text: '4096');
    final paCtrl = TextEditingController(text: '15');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Agent'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Name', border: OutlineInputBorder(), isDense: true),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cwCtrl,
              decoration: const InputDecoration(
                  labelText: 'Context Window', border: OutlineInputBorder(), isDense: true),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: paCtrl,
              decoration: const InputDecoration(
                  labelText: 'Past Actions Limit (min 3)', border: OutlineInputBorder(), isDense: true),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final cw = int.tryParse(cwCtrl.text) ?? 4096;
              final pa = int.tryParse(paCtrl.text) ?? 15;
              Navigator.pop(ctx);
              try {
                final agent = await _agentService.createAgent({
                  'name': name,
                  'context_window': cw,
                  'max_past_actions': pa < 3 ? 3 : pa,
                  'show_context_window': true,
                  'show_notes': true,
                  'show_diary': true,
                  'show_time': true,
                });
                if (!mounted) return;
                setState(() => _agents.add(agent));
                _showSuccess('Agent $name created');
              } catch (e) {
                _showError(e.toString());
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateAgentField(String agentId, Map<String, dynamic> fields) async {
    try {
      final updated = await _agentService.updateAgent(agentId, fields);
      if (!mounted) return;
      setState(() {
        final idx = _agents.indexWhere((a) => a.agentId == agentId);
        if (idx >= 0) _agents[idx] = updated;
      });
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _editContextWindow(AgentRecord agent) {
    final cwCtrl = TextEditingController(text: agent.contextWindow.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Context Window — ${agent.agentId}'),
        content: TextField(
          controller: cwCtrl,
          decoration: const InputDecoration(
              labelText: 'Context Window', border: OutlineInputBorder(), isDense: true),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final cw = int.tryParse(cwCtrl.text);
              if (cw == null) return;
              Navigator.pop(ctx);
              await _updateAgentField(agent.agentId, {'context_window': cw});
              _showSuccess('Context window updated');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editPastActions(AgentRecord agent) {
    final paCtrl = TextEditingController(text: agent.maxPastActions.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Past Actions Limit — ${agent.agentId}'),
        content: TextField(
          controller: paCtrl,
          decoration: const InputDecoration(
              labelText: 'Past Actions (min 3)', border: OutlineInputBorder(), isDense: true),
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final pa = int.tryParse(paCtrl.text);
              if (pa == null || pa < 3) return;
              Navigator.pop(ctx);
              await _updateAgentField(agent.agentId, {'max_past_actions': pa});
              _showSuccess('Past actions limit updated');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _linkModel(AgentRecord agent, {required bool backup}) {
    final modelRefs = <String>[];
    for (final p in _providers) {
      for (final m in p.models.keys) {
        modelRefs.add('${p.name}::$m');
      }
    }
    if (modelRefs.isEmpty) {
      _showError('No models available. Add a provider first.');
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(backup ? 'Link Backup Model' : 'Link Primary Model'),
        children: [
          SizedBox(
            height: 300,
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: modelRefs.length,
              itemBuilder: (ctx, i) => ListTile(
                dense: true,
                title: Text(modelRefs[i], style: const TextStyle(fontSize: 14)),
                selected: (backup ? agent.backupModelRef : agent.modelRef) == modelRefs[i],
                onTap: () async {
                  Navigator.pop(ctx);
                  await _updateAgentField(
                    agent.agentId,
                    backup ? {'backup_model_ref': modelRefs[i]} : {'model_ref': modelRefs[i]},
                  );
                  _showSuccess('Model linked');
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _viewDiary(AgentRecord agent) async {
    try {
      final data = await widget.apiClient.get('/agents/${agent.agentId}/diary');
      final entries = (data['entries'] as List<dynamic>?)
              ?.map((e) => DiaryEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Diary — ${agent.name}'),
          content: SizedBox(
            width: double.maxFinite,
            child: entries.isEmpty
                ? const Text('No diary entries')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: entries.length,
                    itemBuilder: (ctx, i) {
                      final e = entries[i];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.date,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(e.content, style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        ),
      );
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _deleteProvider(String name) async {
    try {
      await _providerService.deleteProvider(name);
      setState(() => _providers.removeWhere((p) => p.name == name));
      _showSuccess('$name deleted');
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _saveProvider(ProviderRecord record) async {
    try {
      final isNew = record.id == null;
      if (isNew) {
        final created = await _providerService.createProvider(record);
        setState(() => _providers.add(created));
      } else {
        final updated = await _providerService.updateProvider(record.name, record);
        setState(() {
          final idx = _providers.indexWhere((p) => p.name == record.name);
          if (idx >= 0) _providers[idx] = updated;
        });
      }
      _showSuccess('${record.name} saved');
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _manageModels(ProviderRecord provider) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => ModelManagementScreen(
          providerName: provider.name,
          models: provider.models,
          activeModels: provider.activeModels,
          providerService: _providerService,
          onSave: _updateProviderModels,
        ),
      ),
    );
    if (result != null && mounted) {
      final models = result['models'] as Map<String, String>;
      final activeModels = result['activeModels'] as Map<String, bool>;
      setState(() {
        final idx = _providers.indexWhere((p) => p.name == provider.name);
        if (idx >= 0) {
          _providers[idx].models..clear()..addAll(models);
          _providers[idx].activeModels..clear()..addAll(activeModels);
        }
      });
      _loadProviders();
    }
  }

  Future<void> _updateProviderModels(
      String name, Map<String, String> models, Map<String, bool> activeModels) async {
    final idx = _providers.indexWhere((p) => p.name == name);
    if (idx < 0) return;
    final updated = ProviderRecord(
      id: _providers[idx].id,
      name: _providers[idx].name,
      apiKey: _providers[idx].apiKey,
      baseUrl: _providers[idx].baseUrl,
      endpointPath: _providers[idx].endpointPath,
      models: models,
      activeModels: activeModels,
      headersTemplate: _providers[idx].headersTemplate,
      authType: _providers[idx].authType,
      authHeaderName: _providers[idx].authHeaderName,
      bodyTemplate: _providers[idx].bodyTemplate,
      responseContentPath: _providers[idx].responseContentPath,
      responseUsageInputPath: _providers[idx].responseUsageInputPath,
      responseUsageOutputPath: _providers[idx].responseUsageOutputPath,
      responseUsageCostPath: _providers[idx].responseUsageCostPath,
      isStreaming: _providers[idx].isStreaming,
      isActive: _providers[idx].isActive,
      maxRetries: _providers[idx].maxRetries,
      timeoutSeconds: _providers[idx].timeoutSeconds,
      maxConcurrent: _providers[idx].maxConcurrent,
    );
    await _providerService.updateProvider(name, updated);
  }

  Future<void> _openProviderForm(ProviderRecord? existing) async {
    final result = await Navigator.push<ProviderRecord>(
      context,
      MaterialPageRoute(
        builder: (_) => ProviderFormScreen(
          existing: existing,
          providerService: _providerService,
        ),
      ),
    );
    if (result != null) {
      await _saveProvider(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      ConnectionTab(
                        apiClient: widget.apiClient,
                        backendService: widget.backendService,
                        onDisconnect: widget.onDisconnect,
                      ),
                      ProvidersTab(
                        providers: _providers,
                        providerService: _providerService,
                        onDelete: _deleteProvider,
                        onEdit: (p) => _openProviderForm(p),
                        onAdd: () => _openProviderForm(null),
                        onManageModels: _manageModels,
                      ),
                      ModelsTab(
                        providers: _providers,
                        providerService: _providerService,
                        onReload: _loadProviders,
                      ),
                      AgentsTab(
                        agents: _agents,
                        onDelete: _deleteAgent,
                        onAdd: _addAgent,
                        onEditContextWindow: _editContextWindow,
                        onEditPastActions: _editPastActions,
                        onToggleField: _updateAgentField,
                        onLinkModel: _linkModel,
                        onViewDiary: _viewDiary,
                      ),
                      AppsTab(
                        apiClient: widget.apiClient,
                        appService: _appService,
                        agents: _agents,
                        onRefresh: _loadApps,
                      ),
                      NotesTab(
                        apiClient: widget.apiClient,
                        agents: _agents,
                      ),
                      DiaryTab(
                        apiClient: widget.apiClient,
                        agents: _agents,
                      ),
                      AlarmsTab(
                        apiClient: widget.apiClient,
                        agents: _agents,
                      ),
                      TimeTab(
                        apiClient: widget.apiClient,
                      ),
                      SecurityTab(
                        settingsService: _settingsService,
                        apiClient: widget.apiClient,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    const tabItems = <_TabItem>[
      _TabItem(icon: Icons.info_outline, label: 'Connection'),
      _TabItem(icon: Icons.cloud, label: 'Providers'),
      _TabItem(icon: Icons.smart_toy, label: 'Models'),
      _TabItem(icon: Icons.person, label: 'Agents'),
      _TabItem(icon: Icons.apps, label: 'Apps'),
      _TabItem(icon: Icons.note, label: 'Notes'),
      _TabItem(icon: Icons.book, label: 'Diary'),
      _TabItem(icon: Icons.alarm, label: 'Alarms'),
      _TabItem(icon: Icons.schedule, label: 'Time'),
      _TabItem(icon: Icons.lock, label: 'Security'),
    ];
    final theme = Theme.of(context);
    return Material(
      elevation: 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _sidebarExpanded ? 200 : 56,
        color: theme.colorScheme.surfaceContainerLow,
        child: Column(
          children: [
            SizedBox(
              height: 44,
              child: InkWell(
                onTap: () =>
                    setState(() => _sidebarExpanded = !_sidebarExpanded),
                child: Container(
                  alignment: Alignment.center,
                  child: AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _sidebarExpanded ? 0.0 : 0.5,
                    child: Icon(
                      Icons.chevron_left,
                      size: 22,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: [
                  for (int i = 0; i < tabItems.length; i++)
                    _SidebarItem(
                      icon: tabItems[i].icon,
                      label: tabItems[i].label,
                      selected: _tabController.index == i,
                      expanded: _sidebarExpanded,
                      onTap: () => _tabController.animateTo(i),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem({required this.icon, required this.label});
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool expanded;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: Material(
        color:
            selected ? theme.colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: expanded
                ? Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(icon,
                          size: 20,
                          color: selected
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          color: selected
                              ? theme.colorScheme.onPrimaryContainer
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Icon(icon,
                        size: 20,
                        color: selected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurfaceVariant),
                  ),
          ),
        ),
      ),
    );
  }
}
