import 'dart:async';
import 'dart:math';
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
  bool _initialized = false;
  Timer? _autoSaveTimer;
  final _realEpochCtrl = TextEditingController();
  final _agentEpochCtrl = TextEditingController();
  double _ratioSliderValue = 0.5;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _realEpochCtrl.dispose();
    _agentEpochCtrl.dispose();
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
        final ratio = (data['ratio'] as num?)?.toDouble() ?? 1.0;
        _ratioSliderValue = ((log(ratio) / ln10) + 2) / 4;
        _loading = false;
        _initialized = true;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _initialized = true;
        });
      }
    }
  }

  void _scheduleAutoSave() {
    if (!_initialized) return;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) _saveConfig(showSnack: false);
    });
  }

  Future<void> _saveConfig({bool showSnack = true}) async {
    setState(() => _saving = true);
    try {
      final body = <String, dynamic>{};
      if (_realEpochCtrl.text.trim().isNotEmpty) {
        body['real_epoch'] = _realEpochCtrl.text.trim();
      }
      if (_agentEpochCtrl.text.trim().isNotEmpty) {
        body['agent_epoch'] = _agentEpochCtrl.text.trim();
      }
      body['ratio'] = pow(10, (_ratioSliderValue * 4) - 2).toDouble();
      await widget.apiClient.put('/time/config', body: body);
      if (!mounted) return;
      if (showSnack) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('Time config saved'), backgroundColor: Colors.green.shade600),
        );
      }
      _silentRefresh();
    } catch (e) {
      if (!mounted) return;
      if (showSnack) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _silentRefresh() async {
    try {
      final data = await widget.apiClient.get('/time/config');
      if (!mounted) return;
      setState(() {
        _realEpochCtrl.text = data['real_epoch']?.toString() ?? '';
        _agentEpochCtrl.text = data['agent_epoch']?.toString() ?? '';
        final ratio = (data['ratio'] as num?)?.toDouble() ?? 1.0;
        _ratioSliderValue = ((log(ratio) / ln10) + 2) / 4;
      });
    } catch (_) {}
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

    _autoSaveTimer?.cancel();
    setState(() => _saving = true);
    try {
      await widget.apiClient.put('/time/config', body: {
        'real_epoch': '1970-01-01T00:00:00+00:00',
        'agent_epoch': '1970-01-01T00:00:00+00:00',
        'ratio': 1.0,
      });
      await _silentRefresh();
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

  Future<void> _pickEpoch(TextEditingController controller) async {
    final current = DateTime.tryParse(controller.text) ?? DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(1970),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null) return;
    final picked = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    controller.text = picked.toUtc().toIso8601String();
    _scheduleAutoSave();
  }

  String _formatEpoch(String iso) {
    if (iso.isEmpty) return 'Not set';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final y = dt.year.toString();
    final mo = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$y-$mo-$d  $h:$mi:$s UTC';
  }

  Widget _buildEpochPicker({
    required TextEditingController controller,
    required String label,
  }) {
    return InkWell(
      onTap: () => _pickEpoch(controller),
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(Icons.edit_calendar, size: 20),
          ),
        ),
        child: Text(
          _formatEpoch(controller.text),
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildRatioSlider() {
    final ratio = pow(10, (_ratioSliderValue * 4) - 2).toDouble();
    String label;
    if (ratio < 0.99) {
      label = '${ratio.toStringAsFixed(2)}× slower';
    } else if (ratio > 1.01) {
      label = '${ratio.toStringAsFixed(2)}× faster';
    } else {
      label = '1.0× normal';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Time Ratio (real:agent)', style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 4),
        Row(
          children: [
            const Text('0.01', style: TextStyle(fontSize: 11)),
            Expanded(
              child: Slider(
                value: _ratioSliderValue.clamp(0.0, 1.0),
                min: 0.0,
                max: 1.0,
                divisions: 200,
                onChanged: (v) {
                  setState(() => _ratioSliderValue = v);
                  _scheduleAutoSave();
                },
              ),
            ),
            const Text('100', style: TextStyle(fontSize: 11)),
          ],
        ),
        Center(child: Text(label, style: const TextStyle(fontSize: 13))),
      ],
    );
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
                _buildEpochPicker(controller: _realEpochCtrl, label: 'Real Epoch'),
                const SizedBox(height: 12),
                _buildEpochPicker(controller: _agentEpochCtrl, label: 'Agent Epoch'),
                const SizedBox(height: 16),
                _buildRatioSlider(),
                const SizedBox(height: 16),
                if (_saving)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 8),
                          Text('Saving...', style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ),
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
