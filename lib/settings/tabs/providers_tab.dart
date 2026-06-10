import 'package:flutter/material.dart';
import '../../services/api_service/models.dart';
import '../../services/api_service/provider_service.dart';

class ProvidersTab extends StatelessWidget {
  final List<ProviderRecord> providers;
  final Future<void> Function(String name) onDelete;
  final void Function(ProviderRecord) onEdit;
  final VoidCallback onAdd;
  final void Function(ProviderRecord) onManageModels;
  final ProviderService? providerService;

  const ProvidersTab({
    super.key,
    required this.providers,
    required this.onDelete,
    required this.onEdit,
    required this.onAdd,
    required this.onManageModels,
    this.providerService,
  });

  @override
  Widget build(BuildContext context) {
    if (providers.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No providers configured'),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Provider'),
              onPressed: onAdd,
            ),
          ],
        ),
      );
    }
    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
          itemCount: providers.length,
          itemBuilder: (context, index) {
            final p = providers[index];
            final anyActive = p.activeModels.values.any((v) => v);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  anyActive || p.isActive ? Icons.check_circle : Icons.cloud,
                  color: anyActive || p.isActive ? Colors.green : null,
                ),
                title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                  '${p.baseUrl}${p.endpointPath}\n'
                  'Auth: ${p.authType} | Models: ${p.models.length}',
                  style: const TextStyle(fontSize: 12),
                ),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (action) {
                    switch (action) {
                      case 'edit':
                        onEdit(p);
                      case 'models':
                        onManageModels(p);
                      case 'test':
                        _testProvider(context, p);
                      case 'delete':
                        _confirmDelete(context, p.name);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'models', child: Text('Manage Models')),
                    const PopupMenuItem(value: 'test', child: Text('Test')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ),
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            heroTag: 'add_provider',
            onPressed: onAdd,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  void _testProvider(BuildContext context, ProviderRecord provider) async {
    if (providerService == null) return;
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Testing Provider...'),
        content: const SizedBox(
          height: 60,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );

    try {
      final result = await providerService!.testProvider(provider.name);
      final available = result['available'] as bool? ?? false;

      if (!context.mounted) return;
      Navigator.of(context).pop();

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
              Text(available ? 'Provider OK' : 'Provider failed',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Provider: ${provider.name}'),
              if (result['latency_ms'] != null)
                Text('Latency: ${(result['latency_ms'] as num).toStringAsFixed(0)} ms'),
              if (result['error'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(result['error'].toString(),
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
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Test failed: $e')),
      );
    }
  }

  void _confirmDelete(BuildContext context, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Provider'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete(name);
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
