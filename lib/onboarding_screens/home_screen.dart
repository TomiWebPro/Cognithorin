import 'package:flutter/material.dart';
import '../services/backend_service.dart';
import '../services/api_service/api_client.dart';
import '../settings/settings_screen.dart';

class HomeContent extends StatelessWidget {
  final BackendConnectionService backendService;
  final VoidCallback onDisconnect;
  final ApiClient apiClient;

  const HomeContent({
    super.key,
    required this.backendService,
    required this.onDisconnect,
    required this.apiClient,
  });

  void _confirmDisconnect(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect'),
        content: const Text('Are you sure you want to disconnect from the backend?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDisconnect();
            },
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = backendService.backendInfo;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(
              Icons.cloud_done,
              size: 24,
              color: Colors.green.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              'Connected',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.settings, size: 20),
              tooltip: 'Settings',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(apiClient: apiClient, backendService: backendService, onDisconnect: () {}),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.link_off, size: 20),
              tooltip: 'Disconnect',
              onPressed: () => _confirmDisconnect(context),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          backendService.currentUrl ?? '',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        const Divider(height: 24),
        if (info != null) ...[
          _infoRow('Name', info.message),
          _infoRow('Version', info.version),
          _infoRow('Status', info.status),
          _infoRow('Server Time', info.timestamp),
        ],
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
