import 'package:flutter/material.dart';
import '../services/api_service/provider_service.dart';

class ModelManagementScreen extends StatefulWidget {
  final String providerName;
  final Map<String, String> models;
  final Map<String, bool> activeModels;
  final ProviderService providerService;
  final Future<void> Function(
    String name,
    Map<String, String> models,
    Map<String, bool> activeModels,
  ) onSave;

  const ModelManagementScreen({
    super.key,
    required this.providerName,
    required this.models,
    required this.activeModels,
    required this.providerService,
    required this.onSave,
  });

  @override
  State<ModelManagementScreen> createState() => _ModelManagementScreenState();
}

class _ModelManagementScreenState extends State<ModelManagementScreen> {
  late List<_ModelEntry> _entries;
  late Map<String, bool> _activeModels;

  bool _saving = false;
  String? _testingModel;

  @override
  void initState() {
    super.initState();
    _entries = widget.models.entries
        .map((e) => _ModelEntry(label: e.key, value: e.value))
        .toList();
    _activeModels = Map.from(widget.activeModels);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final models = {for (final e in _entries) e.label: e.value};
    try {
      await widget.onSave(widget.providerName, models, _activeModels);
      if (!mounted) return;
      Navigator.pop(context, {
        'models': models,
        'activeModels': _activeModels,
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _add() {
    setState(() => _entries.add(_ModelEntry(label: '', value: '')));
  }

  void _remove(int index) {
    final removed = _entries[index];
    setState(() {
      _entries.removeAt(index);
      _activeModels.remove(removed.label);
    });
  }

  Future<void> _testModel(_ModelEntry entry) async {
    final name = entry.label.trim();
    if (name.isEmpty) return;
    setState(() => _testingModel = name);
    try {
      final result = await widget.providerService.testModel(
        widget.providerName,
        name,
      );
      if (!mounted) return;
      final available = result['available'] as bool? ?? false;
      setState(() => _activeModels[name] = available);
      _showTestResult(available, result);
    } catch (e) {
      if (!mounted) return;
      setState(() => _activeModels[name] = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _testingModel = null);
    }
  }

  void _showTestResult(bool available, Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Icon(
          available ? Icons.check_circle : Icons.error,
          color: available ? Colors.green : Colors.red,
          size: 40,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(available ? 'Model OK' : 'Model failed'),
            if (result['latency_ms'] != null)
              Text(
                'Latency: ${(result['latency_ms'] as num).toStringAsFixed(0)} ms',
              ),
            if (result['output_tokens'] != null)
              Text('Output tokens: ${result['output_tokens']}'),
            if (result['error'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  result['error'].toString(),
                  style: const TextStyle(fontSize: 13, color: Colors.red),
                ),
              ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Models — ${widget.providerName}'),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save, size: 18),
            label: const Text('Save'),
          ),
        ],
      ),
      body: _entries.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No models configured'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Model'),
                    onPressed: _add,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: _entries.length,
              itemBuilder: (context, index) {
                final entry = _entries[index];
                final isActive = _activeModels[entry.label] ?? false;
                final isTesting = _testingModel == entry.label;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isActive
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: isActive ? Colors.green : Colors.grey,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Model Name',
                                  hintText: 'gpt-4o',
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                ),
                                controller: entry.labelCtrl,
                                style: const TextStyle(fontSize: 14),
                                onChanged: (v) => entry.label = v,
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: isTesting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.wifi_find, size: 20),
                              tooltip: 'Test model',
                              onPressed: isTesting
                                  ? null
                                  : () => _testModel(entry),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              onPressed: () => _remove(index),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Model ID',
                            hintText: 'gpt-4o-2024-05-13',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          controller: entry.valueCtrl,
                          style: const TextStyle(fontSize: 14),
                          onChanged: (v) => entry.value = v,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_model',
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _ModelEntry {
  String label;
  String value;
  late final TextEditingController labelCtrl;
  late final TextEditingController valueCtrl;

  _ModelEntry({required this.label, required this.value}) {
    labelCtrl = TextEditingController(text: label);
    valueCtrl = TextEditingController(text: value);
  }
}
