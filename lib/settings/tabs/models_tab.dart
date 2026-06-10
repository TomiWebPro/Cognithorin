import 'package:flutter/material.dart';
import '../../services/api_service/provider_service.dart';
import '../../services/api_service/models.dart';

class ModelsTab extends StatelessWidget {
  final List<ProviderRecord> providers;
  final ProviderService providerService;
  final VoidCallback onReload;

  const ModelsTab({
    super.key,
    required this.providers,
    required this.providerService,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    final modelEntries = <_ModelEntry>[];
    for (final p in providers) {
      for (final e in p.models.entries) {
        modelEntries.add(_ModelEntry(
          providerName: p.name,
          modelName: e.key,
          modelId: e.value,
          isActive: p.activeModels[e.key] ?? false,
          providerService: providerService,
          onReload: onReload,
        ));
      }
    }

    if (modelEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.smart_toy, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('No models configured'),
            SizedBox(height: 4),
            Text('Add models via provider settings', style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: modelEntries.length,
      itemBuilder: (context, index) => modelEntries[index],
    );
  }
}

class _ModelEntry extends StatefulWidget {
  final String providerName;
  final String modelName;
  final String modelId;
  final bool isActive;
  final ProviderService providerService;
  final VoidCallback onReload;

  const _ModelEntry({
    required this.providerName,
    required this.modelName,
    required this.modelId,
    required this.isActive,
    required this.providerService,
    required this.onReload,
  });

  @override
  State<_ModelEntry> createState() => _ModelEntryState();
}

class _ModelEntryState extends State<_ModelEntry> {
  late bool _active;
  bool _testing = false;

  @override
  void initState() {
    super.initState();
    _active = widget.isActive;
  }

  @override
  void didUpdateWidget(_ModelEntry old) {
    super.didUpdateWidget(old);
    _active = widget.isActive;
  }

  Future<void> _test() async {
    setState(() => _testing = true);
    try {
      final result = await widget.providerService
          .testModel(widget.providerName, widget.modelName);
      if (!mounted) return;
      final available = result['available'] as bool? ?? false;
      setState(() => _active = available);
      widget.onReload();
      final latency = result['latency_ms'];
      final error = result['error'];
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(available ? 'Model OK' : 'Model failed',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Provider: ${widget.providerName}'),
              Text('Model: ${widget.modelName} (${widget.modelId})'),
              if (latency != null)
                Text('Latency: ${(latency as num).toStringAsFixed(0)} ms'),
              if (result['output_tokens'] != null)
                Text('Output tokens: ${result['output_tokens']}'),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(error.toString(),
                      style: const TextStyle(fontSize: 13, color: Colors.red)),
                ),
            ],
          ),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _active = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(
          _active ? Icons.check_circle : Icons.radio_button_unchecked,
          color: _active ? Colors.green : Colors.grey,
          size: 20,
        ),
        title: Text(widget.modelName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${widget.providerName}  |  ${widget.modelId}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: IconButton(
          icon: _testing
              ? const SizedBox(
                  width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.wifi_find, size: 20),
          tooltip: 'Test connection',
          onPressed: _testing ? null : _test,
        ),
      ),
    );
  }
}
