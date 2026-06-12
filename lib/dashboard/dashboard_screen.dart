import 'package:flutter/material.dart';
import '../services/api_service/api_client.dart';
import '../services/api_service/agent_service.dart';
import '../services/api_service/runtime_service.dart';
import '../services/api_service/models.dart';
import '../services/backend_service.dart';
import '../settings/settings_screen.dart';
import 'agent_card.dart';
import 'stats_screen.dart';

class DashboardScreen extends StatefulWidget {
  final ApiClient apiClient;
  final BackendConnectionService backendService;
  final VoidCallback onDisconnect;

  const DashboardScreen({
    super.key,
    required this.apiClient,
    required this.backendService,
    required this.onDisconnect,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final RuntimeService _runtimeService;
  late final AgentService _agentService;
  List<AgentRuntime> _runtimes = [];
  bool _loading = true;
  bool _contextDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _runtimeService = RuntimeService(widget.apiClient);
    _agentService = AgentService(widget.apiClient);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final runtimes = await _runtimeService.getAllRuntimes();
      if (!mounted) return;
      setState(() {
        _runtimes = runtimes;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _togglePause(String agentId, bool paused) async {
    try {
      await _agentService.updateAgent(agentId, {
        'status': paused ? 'paused' : 'active',
      });
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(paused ? 'Agent paused' : 'Agent resumed'),
          backgroundColor: Colors.green.shade600,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 36),
          title: const Text('Operation Failed'),
          content: Text('$e'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _viewContext(AgentRuntime runtime) async {
    if (_contextDialogOpen) return;
    _contextDialogOpen = true;
    final a = runtime.agent;
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AgentContextDialog(
        agentName: a.name,
        future: _runtimeService.getAgentContext(a.agentId),
      ),
    ).then((_) {
      if (mounted) _contextDialogOpen = false;
    });
  }

  Future<void> _openStats() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StatsScreen(apiClient: widget.apiClient),
      ),
    );
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          apiClient: widget.apiClient,
          backendService: widget.backendService,
          onDisconnect: widget.onDisconnect,
        ),
      ),
    );
    _load();
  }

  void _showAgentDetail(AgentRuntime runtime) {
    final a = runtime.agent;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(a.name),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow('ID', a.agentId),
                _detailRow('Status', a.status),
                _detailRow('Context Window', '${a.contextWindow}'),
                if (a.modelRef != null) _detailRow('Model', a.modelRef!),
                if (a.backupModelRef != null) _detailRow('Backup', a.backupModelRef!),
                _detailRow('Past Actions', '${a.maxPastActions}'),
                const Divider(),
                _detailRow('Notes', '${runtime.notesCount}'),
                _detailRow('Diary Entries', '${runtime.diaryCount}'),
                _detailRow('Active Alarms', '${runtime.alarmsCount}'),
                _detailRow('Open Tabs', '${runtime.openTabs.length}'),
                _detailRow('Installed Apps', '${runtime.installedAppsCount}'),
                _detailRow('Apps Enabled', '${runtime.enabledAppsCount}'),
                if (runtime.latestDiary != null) ...[
                  const Divider(),
                  Text('Latest Diary',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(runtime.latestDiary!,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cognithor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Token Stats',
            onPressed: _openStats,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _runtimes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.smart_toy_outlined,
                          size: 64, color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 16),
                      Text('No agents configured',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Create agents in Settings to get started',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              )),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        icon: const Icon(Icons.settings),
                        label: const Text('Open Settings'),
                        onPressed: _openSettings,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: _runtimes.length,
                    itemBuilder: (context, index) {
                      final r = _runtimes[index];
                      return AgentCard(
                        runtime: r,
                        onTogglePause: _togglePause,
                        onTap: () => _showAgentDetail(r),
                        onViewContext: () => _viewContext(r),
                      );
                    },
                  ),
                ),
    );
  }
}

class _AgentContextDialog extends StatefulWidget {
  final String agentName;
  final Future<Map<String, dynamic>> future;

  const _AgentContextDialog({
    required this.agentName,
    required this.future,
  });

  @override
  State<_AgentContextDialog> createState() => _AgentContextDialogState();
}

class _AgentContextDialogState extends State<_AgentContextDialog> {
  String? _content;
  String? _lastUpdated;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await widget.future;
      if (!mounted) return;
      setState(() {
        _content = data['context'] as String? ?? '';
        _lastUpdated = data['last_updated'] as String?;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.visibility, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Context — ${widget.agentName}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Flexible(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading context...'),
                        ],
                      ),
                    ),
                  )
                : _error != null
                    ? Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 36),
                            const SizedBox(height: 12),
                            const Text('Failed to load context',
                                style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Text(_error!,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.error)),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      )
                    : _content!.isEmpty
                        ? const Center(child: Text('Context is empty'))
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_lastUpdated != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      'Last updated: ${_lastUpdated!.replaceFirst('T', ' ').replaceFirst(RegExp(r'\..*'), '')}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                SelectableText(
                                  _content!,
                                  style: const TextStyle(fontSize: 13, height: 1.5),
                                ),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
