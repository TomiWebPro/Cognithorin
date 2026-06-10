import 'package:flutter/material.dart';
import '../services/api_service/models.dart';

class AgentCard extends StatelessWidget {
  final AgentRuntime runtime;
  final void Function(String agentId, bool paused) onTogglePause;
  final VoidCallback onTap;
  final VoidCallback? onViewContext;

  const AgentCard({
    super.key,
    required this.runtime,
    required this.onTogglePause,
    required this.onTap,
    this.onViewContext,
  });

  Color _statusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'paused':
        return Colors.red;
      case 'idle':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Active';
      case 'paused':
        return 'Paused';
      case 'idle':
        return 'Idle';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = runtime.agent;
    final theme = Theme.of(context);
    final statusColor = _statusColor(a.status);
    final isPaused = a.status == 'paused';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      a.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _statusLabel(a.status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'ID: ${a.agentId}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (a.modelRef != null) ...[
                const SizedBox(height: 2),
                Text(
                  a.modelRef!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const Divider(height: 20),
              Row(
                children: [
                  _miniChip(theme, Icons.note, '${runtime.notesCount}'),
                  const SizedBox(width: 12),
                  _miniChip(theme, Icons.book, '${runtime.diaryCount}'),
                  const SizedBox(width: 12),
                  _miniChip(theme, Icons.alarm, '${runtime.alarmsCount}'),
                  const SizedBox(width: 12),
                  _miniChip(theme, Icons.apps, '${runtime.enabledAppsCount}/${runtime.installedAppsCount}'),
                  const Spacer(),
                  Text(
                    'CW: ${a.contextWindow}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              if (runtime.installedAppsCount == 0)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 16, color: Colors.amber.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No apps installed — agent cannot execute commands',
                          style: TextStyle(fontSize: 12, color: Colors.amber.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onViewContext != null)
                    IconButton(
                      icon: const Icon(Icons.visibility_outlined),
                      tooltip: 'View agent context',
                      onPressed: onViewContext,
                    ),
                  IconButton(
                    icon: Icon(
                      isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                      color: isPaused ? Colors.green : Colors.orange,
                    ),
                    tooltip: isPaused ? 'Resume agent' : 'Pause agent',
                    onPressed: () => onTogglePause(a.agentId, !isPaused),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniChip(ThemeData theme, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
