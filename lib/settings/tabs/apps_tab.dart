import 'dart:convert';

import 'package:flutter/material.dart';
import '../../services/api_service/api_client.dart';
import '../../services/api_service/app_service.dart';
import '../../services/api_service/models.dart';

class AppsTab extends StatefulWidget {
  final ApiClient apiClient;
  final AppService appService;
  final List<AgentRecord> agents;
  final VoidCallback onRefresh;

  const AppsTab({
    super.key,
    required this.apiClient,
    required this.appService,
    required this.agents,
    required this.onRefresh,
  });

  @override
  State<AppsTab> createState() => _AppsTabState();
}

class _AppsTabState extends State<AppsTab> {
  List<AppRecord> _apps = [];
  Map<String, List<AgentAppRecord>> _agentApps = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final apps = await widget.appService.getApps(all: true);
      final agentApps = <String, List<AgentAppRecord>>{};
      for (final agent in widget.agents) {
        try {
          agentApps[agent.agentId] = await widget.appService.getAgentApps(agent.agentId);
        } catch (_) {
          agentApps[agent.agentId] = [];
        }
      }
      if (!mounted) return;
      setState(() {
        _apps = apps;
        _agentApps = agentApps;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showAppDetails(AppRecord app) {
    Map<String, dynamic> manifest = {};
    if (app.manifest != null && app.manifest!.isNotEmpty) {
      try {
        manifest = jsonDecode(app.manifest!) as Map<String, dynamic>;
      } catch (_) {}
    }
    final params = manifest['parameters'] as List<dynamic>? ?? [];
    final outputs = manifest['outputs'] as List<dynamic>? ?? [];
    final configSchema = manifest['config_schema'] as List<dynamic>? ?? [];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(app.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _detailRow('App ID', app.appId),
              _detailRow('Name', app.name),
              _detailRow('Description', app.description),
              _detailRow('Version', app.version),
              _detailRow('Author', app.author),
              _detailRow('Type', app.type),
              _detailRow('Available', app.isAvailable ? 'Yes' : 'No'),
              _detailRow('Requires Confirm', app.requiresConfirmation ? 'Yes' : 'No'),
              _detailRow('Timeout', '${app.timeoutSeconds}s'),
              _detailRow('Directory', app.directory ?? '—'),
              if (params.isNotEmpty) ...[
                const Divider(),
                Text('Parameters (${params.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ...params.map((p) => Text(
                      '  ${p['name']} (${p['type']})${p['required'] == true ? ' *' : ''} — ${p['description'] ?? ''}',
                      style: const TextStyle(fontSize: 12),
                    )),
              ],
              if (outputs.isNotEmpty) ...[
                const Divider(),
                Text('Outputs (${outputs.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ...outputs.map((o) => Text(
                      '  ${o['name']} (${o['type']}) — ${o['description'] ?? ''}',
                      style: const TextStyle(fontSize: 12),
                    )),
              ],
              if (configSchema.isNotEmpty) ...[
                const Divider(),
                Text('Config Schema (${configSchema.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ...configSchema.map((c) => Text(
                      '  ${c['name']} (${c['type']})${c['required'] == true ? ' *' : ''} — ${c['description'] ?? ''}',
                      style: const TextStyle(fontSize: 12),
                    )),
              ],
            ],
          ),
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          Flexible(child: Text(value, style: const TextStyle(fontSize: 12))),
        ],
      ),
    );
  }

  void _configureApp(AgentRecord agent, AgentAppRecord installed, AppRecord app) {
    Map<String, dynamic> manifest = {};
    if (app.manifest != null && app.manifest!.isNotEmpty) {
      try {
        manifest = jsonDecode(app.manifest!) as Map<String, dynamic>;
      } catch (_) {}
    }
    final configSchema = manifest['config_schema'] as List<dynamic>? ?? [];

    if (configSchema.isEmpty) {
      _showError('This app has no configurable settings');
      return;
    }

    Map<String, dynamic> currentConfig = {};
    if (installed.config != null && installed.config!.isNotEmpty) {
      try {
        currentConfig = jsonDecode(installed.config!) as Map<String, dynamic>;
      } catch (_) {}
    }

    final controllers = <String, TextEditingController>{};
    for (final field in configSchema) {
      final fname = field['name'] as String? ?? '';
      final fdefault = field['default'];
      final current = currentConfig[fname] ?? fdefault;
      controllers[fname] = TextEditingController(text: current?.toString() ?? '');
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Configure ${app.name} for ${agent.name}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: configSchema.map<Widget>((field) {
              final fname = field['name'] as String? ?? '';
              final ftype = field['type'] as String? ?? 'string';
              final flabel = field['label'] as String? ?? fname;
              final fdesc = field['description'] as String? ?? '';
              final freq = field['required'] == true;
              final ctrl = controllers[fname]!;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ftype == 'boolean'
                    ? StatefulBuilder(builder: (ctx, setInnerState) {
                        final val = ctrl.text == 'true';
                        return CheckboxListTile(
                          title: Text('$flabel${freq ? ' *' : ''}',
                              style: const TextStyle(fontSize: 13)),
                          subtitle: fdesc.isNotEmpty
                              ? Text(fdesc, style: const TextStyle(fontSize: 11))
                              : null,
                          value: val,
                          onChanged: (v) => setInnerState(() => ctrl.text = v.toString()),
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      })
                    : TextField(
                        controller: ctrl,
                        decoration: InputDecoration(
                          labelText: '$flabel${freq ? ' *' : ''}',
                          hintText: fdesc,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: ftype == 'integer' ? TextInputType.number : null,
                        style: const TextStyle(fontSize: 13),
                      ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final values = <String, dynamic>{};
              for (final field in configSchema) {
                final fname = field['name'] as String? ?? '';
                final ftype = field['type'] as String? ?? 'string';
                final ctrl = controllers[fname]!;
                if (ftype == 'boolean') {
                  values[fname] = ctrl.text == 'true';
                } else if (ftype == 'integer') {
                  values[fname] = int.tryParse(ctrl.text) ?? 0;
                } else {
                  values[fname] = ctrl.text;
                }
              }
              Navigator.pop(ctx);
              try {
                await widget.appService.setAppConfig(agent.agentId, app.appId, values);
                _showSuccess('Configuration saved');
                _load();
              } catch (e) {
                _showError(e.toString());
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_apps.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.apps, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No apps registered'),
            const SizedBox(height: 4),
            const Text('Apps are auto-discovered from server', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: _apps.length,
          itemBuilder: (context, index) {
            final app = _apps[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                leading: Text(app.icon, style: const TextStyle(fontSize: 20)),
                title: Text(app.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${app.appId} v${app.version}',
                    style: const TextStyle(fontSize: 12)),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (app.description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(app.description, style: const TextStyle(fontSize: 13)),
                          ),
                        Text('Author: ${app.author}', style: const TextStyle(fontSize: 12)),
                        Text('Available: ${app.isAvailable ? 'Yes' : 'No'}',
                            style: TextStyle(fontSize: 12, color: app.isAvailable ? Colors.green : Colors.red)),
                        Row(
                          children: [
                            Text('Type: ${app.type}', style: const TextStyle(fontSize: 12)),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => _showAppDetails(app),
                              icon: const Icon(Icons.info_outline, size: 16),
                              label: const Text('Details', style: TextStyle(fontSize: 12)),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (widget.agents.isEmpty)
                          const Text('No agents to install on', style: TextStyle(fontSize: 13, color: Colors.grey))
                        else
                          ...widget.agents.map((agent) {
                            final installedList = _agentApps[agent.agentId]
                                ?.where((a) => a.appId == app.appId)
                                .toList();
                            final installed = (installedList != null && installedList.isNotEmpty)
                                ? installedList.first
                                : null;
                            final isEnabled = installed?.isEnabled ?? false;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    installed != null ? Icons.check_circle : Icons.radio_button_unchecked,
                                    size: 16,
                                    color: installed != null ? Colors.green : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text('${agent.name} (${agent.agentId})',
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: installed != null ? FontWeight.w600 : null)),
                                  ),
                                  if (installed != null) ...[
                                    Text(isEnabled ? 'ON' : 'OFF',
                                        style: TextStyle(fontSize: 11,
                                            color: isEnabled ? Colors.green : Colors.grey)),
                                    IconButton(
                                      icon: const Icon(Icons.settings, size: 18),
                                      onPressed: () => _configureApp(agent, installed, app),
                                      visualDensity: VisualDensity.compact,
                                      tooltip: 'Configure',
                                    ),
                                    IconButton(
                                      icon: Icon(isEnabled ? Icons.toggle_on : Icons.toggle_off_outlined,
                                          size: 20),
                                      onPressed: () => _toggleApp(agent.agentId, app.appId, isEnabled),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18),
                                      onPressed: () => _uninstallApp(agent.agentId, app.appId),
                                      visualDensity: VisualDensity.compact,
                                      color: Colors.red,
                                    ),
                                  ] else ...[
                                    IconButton(
                                      icon: const Icon(Icons.download, size: 18),
                                      onPressed: () => _installApp(agent.agentId, app.appId),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            heroTag: 'refresh_apps',
            onPressed: _load,
            child: const Icon(Icons.refresh),
          ),
        ),
      ],
    );
  }

  Future<void> _installApp(String agentId, String appId) async {
    try {
      await widget.appService.installApp(agentId, appId);
      _showSuccess('App installed');
      _load();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _uninstallApp(String agentId, String appId) async {
    try {
      await widget.appService.uninstallApp(agentId, appId);
      _showSuccess('App uninstalled');
      _load();
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _toggleApp(String agentId, String appId, bool enabled) async {
    try {
      if (enabled) {
        await widget.appService.disableApp(agentId, appId);
      } else {
        await widget.appService.enableApp(agentId, appId);
      }
      _load();
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green.shade600),
    );
  }
}
