import 'package:flutter/material.dart';
import '../../services/api_service/api_client.dart';

class TimeTab extends StatefulWidget {
  final ApiClient apiClient;

  const TimeTab({super.key, required this.apiClient});

  @override
  State<TimeTab> createState() => _TimeTabState();
}

class _TimeTabState extends State<TimeTab> {
  bool _loading = true;
  bool _saving = false;
  final _realEpochCtrl = TextEditingController();
  final _agentEpochCtrl = TextEditingController();
  final _ratioCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _realEpochCtrl.dispose();
    _agentEpochCtrl.dispose();
    _ratioCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    setState(() => _loading = true);
    try {
      final data = await widget.apiClient.get('/time/config');
      if (!mounted) return;
      setState(() {
        _realEpochCtrl.text = data['real_epoch']?.toString() ?? '';
        _agentEpochCtrl.text = data['agent_epoch']?.toString() ?? '';
        _ratioCtrl.text = data['ratio']?.toString() ?? '';
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{};
      if (_realEpochCtrl.text.trim().isNotEmpty) {
        body['real_epoch'] = _realEpochCtrl.text.trim();
      }
      if (_agentEpochCtrl.text.trim().isNotEmpty) {
        body['agent_epoch'] = _agentEpochCtrl.text.trim();
      }
      if (_ratioCtrl.text.trim().isNotEmpty) {
        body['ratio'] = double.tryParse(_ratioCtrl.text.trim()) ?? 1.0;
      }
      await widget.apiClient.put('/time/config', body: body);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Time config saved'), backgroundColor: Colors.green.shade600),
      );
      _loadConfig();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Theme.of(context).colorScheme.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _resetToDefaults() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Time Config'),
        content: const Text('Reset time configuration to defaults?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Reset')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _saving = true);
    try {
      await widget.apiClient.put('/time/config', body: {
        'real_epoch': '1970-01-01T00:00:00+00:00',
        'agent_epoch': '1970-01-01T00:00:00+00:00',
        'ratio': 1.0,
      });
      await _loadConfig();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Time config reset to defaults'), backgroundColor: Colors.green.shade600),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e'), backgroundColor: Theme.of(context).colorScheme.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule, size: 20, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Simulated Clock', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _realEpochCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Real Epoch (ISO 8601)',
                      border: OutlineInputBorder(),
                      isDense: true),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _agentEpochCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Agent Epoch (ISO 8601)',
                      border: OutlineInputBorder(),
                      isDense: true),
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _ratioCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Ratio (real:agent)',
                      border: OutlineInputBorder(),
                      isDense: true),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _saveConfig,
                    child: _saving
                        ? const SizedBox(
                            width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Save'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _saving ? null : _resetToDefaults,
                    child: const Text('Reset to Defaults'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
