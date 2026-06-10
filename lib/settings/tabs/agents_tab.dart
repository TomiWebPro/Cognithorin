import 'package:flutter/material.dart';
import '../../services/api_service/models.dart';

const _statusColor = <String, Color>{
  'active': Colors.green,
  'paused': Colors.red,
  'idle': Colors.orange,
};

class AgentsTab extends StatelessWidget {
  final List<AgentRecord> agents;
  final Future<void> Function(String agentId) onDelete;
  final VoidCallback onAdd;
  final void Function(AgentRecord agent) onEditContextWindow;
  final void Function(AgentRecord agent) onEditPastActions;
  final Future<void> Function(String agentId, Map<String, dynamic> fields) onToggleField;
  final void Function(AgentRecord agent, {required bool backup}) onLinkModel;
  final Future<void> Function(AgentRecord agent) onViewDiary;

  const AgentsTab({
    super.key,
    required this.agents,
    required this.onDelete,
    required this.onAdd,
    required this.onEditContextWindow,
    required this.onEditPastActions,
    required this.onToggleField,
    required this.onLinkModel,
    required this.onViewDiary,
  });

  @override
  Widget build(BuildContext context) {
    if (agents.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('No agents configured'),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add Agent'),
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
          itemCount: agents.length,
          itemBuilder: (context, index) {
            final a = agents[index];
            final statusColor = _statusColor[a.status] ?? Colors.grey;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                leading: Icon(Icons.person, size: 24, color: statusColor),
                title: Row(
                  children: [
                    Flexible(child: Text(a.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(a.status,
                          style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                subtitle: Text('ID: ${a.agentId}  |  CW: ${a.contextWindow}',
                    style: const TextStyle(fontSize: 12)),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _agentField('Context Window', a.contextWindow.toString()),
                        _agentField('Past Actions', a.maxPastActions.toString()),
                        _agentField('Primary Model', a.modelRef ?? '(none)'),
                        _agentField('Backup Model', a.backupModelRef ?? '(none)'),
                        const Divider(height: 16),
                        _buildToggle(context, 'CW Tab', a.showContextWindow, (v) {
                          onToggleField(a.agentId, {'show_context_window': v});
                        }),
                        _buildToggle(context, 'Agent Edit PA', a.agentCanChangeMaxPastActions, (v) {
                          onToggleField(a.agentId, {'agent_can_change_max_past_actions': v});
                        }),
                        _buildToggle(context, 'Notes Tab', a.showNotes, (v) {
                          onToggleField(a.agentId, {'show_notes': v});
                        }),
                        _buildToggle(context, 'Diary Tab', a.showDiary, (v) {
                          onToggleField(a.agentId, {'show_diary': v});
                        }),
                        _buildToggle(context, 'Time Tab', a.showTime, (v) {
                          onToggleField(a.agentId, {'show_time': v});
                        }),
                        const Divider(height: 16),
                        _buildPauseToggle(context, a),
                        const Divider(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            ActionChip(
                                label: const Text('CW', style: TextStyle(fontSize: 12)),
                                onPressed: () => onEditContextWindow(a)),
                            ActionChip(
                                label: const Text('Past Actions', style: TextStyle(fontSize: 12)),
                                onPressed: () => onEditPastActions(a)),
                            ActionChip(
                                label: const Text('Primary', style: TextStyle(fontSize: 12)),
                                onPressed: () => onLinkModel(a, backup: false)),
                            ActionChip(
                                label: const Text('Backup', style: TextStyle(fontSize: 12)),
                                onPressed: () => onLinkModel(a, backup: true)),
                            ActionChip(
                                label: const Text('Diary', style: TextStyle(fontSize: 12)),
                                onPressed: () => onViewDiary(a)),
                            ActionChip(
                                label: const Text('Delete', style: TextStyle(fontSize: 12)),
                                onPressed: () => _confirmDelete(context, a)),
                          ],
                        ),
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
            heroTag: 'add_agent',
            onPressed: onAdd,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _agentField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPauseToggle(BuildContext context, AgentRecord agent) {
    final isPaused = agent.status == 'paused';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              size: 18,
              color: isPaused ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(isPaused ? 'Resume Agent' : 'Pause Agent',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
        Switch(
          value: !isPaused,
          activeTrackColor: Colors.green.withValues(alpha: 0.4),
          activeThumbColor: Colors.green,
          onChanged: (v) {
            onToggleField(agent.agentId, {
              'status': v ? 'active' : 'paused',
            });
          },
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }

  Widget _buildToggle(BuildContext context, String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        Switch(value: value, onChanged: onChanged, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
      ],
    );
  }

  void _confirmDelete(BuildContext context, AgentRecord agent) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Agent'),
        content: Text('Delete "${agent.name}" (${agent.agentId})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete(agent.agentId);
            },
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
