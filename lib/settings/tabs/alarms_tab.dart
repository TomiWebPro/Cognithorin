import 'package:flutter/material.dart';
import '../../services/api_service/api_client.dart';
import '../../services/api_service/models.dart';

class AlarmsTab extends StatefulWidget {
  final ApiClient apiClient;
  final List<AgentRecord> agents;

  const AlarmsTab({
    super.key,
    required this.apiClient,
    required this.agents,
  });

  @override
  State<AlarmsTab> createState() => _AlarmsTabState();
}

class _AlarmsTabState extends State<AlarmsTab> {
  String? _selectedAgentId;
  List<Map<String, dynamic>> _alarms = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.agents.isNotEmpty) {
      _selectedAgentId = widget.agents.first.agentId;
      _loadAlarms();
    }
  }

  Future<void> _loadAlarms() async {
    if (_selectedAgentId == null) return;
    setState(() => _loading = true);
    try {
      final data = await widget.apiClient.get('/agents/$_selectedAgentId/alarms');
      final alarms = (data['alarms'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [];
      if (!mounted) return;
      setState(() {
        _alarms = alarms;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _createAlarm() {
    final timeCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    String timeType = 'agent';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Alarm'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: timeCtrl,
                decoration: const InputDecoration(
                    labelText: 'Time', hintText: '2026-06-09T10:00:00+00:00',
                    border: OutlineInputBorder(), isDense: true)),
            const SizedBox(height: 8),
            TextField(
                controller: msgCtrl,
                decoration: const InputDecoration(
                    labelText: 'Message', border: OutlineInputBorder(), isDense: true)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: timeType,
              decoration: const InputDecoration(
                  labelText: 'Time Type', border: OutlineInputBorder(), isDense: true),
              items: const [
                DropdownMenuItem(value: 'agent', child: Text('Agent Time')),
                DropdownMenuItem(value: 'real', child: Text('Real Time')),
              ],
              onChanged: (v) => timeType = v ?? 'agent',
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await widget.apiClient.post('/agents/$_selectedAgentId/alarms', body: {
                  'time': timeCtrl.text,
                  'message': msgCtrl.text,
                  'time_type': timeType,
                });
                _loadAlarms();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelAlarm(String alarmId) async {
    try {
      await widget.apiClient.delete('/alarms/$alarmId');
      _loadAlarms();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.agents.isEmpty) {
      return const Center(child: Text('No agents available'));
    }

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedAgentId,
                decoration: const InputDecoration(
                    labelText: 'Agent', border: OutlineInputBorder(), isDense: true),
                items: widget.agents
                    .map((a) => DropdownMenuItem(
                        value: a.agentId, child: Text('${a.name} (${a.agentId})')))
                    .toList(),
                onChanged: (v) {
                  setState(() => _selectedAgentId = v);
                  _loadAlarms();
                },
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _alarms.isEmpty
                      ? const Center(child: Text('No alarms'))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                          itemCount: _alarms.length,
                          itemBuilder: (context, index) {
                            final alarm = _alarms[index];
                            final triggered = alarm['triggered'] == true;
                            return Card(
                              child: ListTile(
                                leading: Icon(
                                  triggered ? Icons.alarm_off : Icons.alarm,
                                  color: triggered ? Colors.grey : Colors.orange,
                                ),
                                title: Text(alarm['message'] as String? ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  '${alarm['alarm_time'] ?? alarm['time'] ?? ''}  |  ${alarm['time_type'] ?? 'agent'}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: triggered
                                    ? const Text('Triggered',
                                        style: TextStyle(fontSize: 12, color: Colors.grey))
                                    : IconButton(
                                        icon: const Icon(Icons.cancel, color: Colors.red),
                                        onPressed: () => _cancelAlarm(alarm['id'] as String),
                                      ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            heroTag: 'add_alarm',
            onPressed: _createAlarm,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
