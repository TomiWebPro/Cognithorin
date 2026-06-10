import 'package:flutter/material.dart';
import '../../services/api_service/api_client.dart';
import '../../services/api_service/models.dart';

class NotesTab extends StatefulWidget {
  final ApiClient apiClient;
  final List<AgentRecord> agents;

  const NotesTab({
    super.key,
    required this.apiClient,
    required this.agents,
  });

  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
  String? _selectedAgentId;
  List<Map<String, dynamic>> _notes = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.agents.isNotEmpty) {
      _selectedAgentId = widget.agents.first.agentId;
      _loadNotes();
    }
  }

  Future<void> _loadNotes() async {
    if (_selectedAgentId == null) return;
    setState(() => _loading = true);
    try {
      final data = await widget.apiClient.get('/agents/$_selectedAgentId/notes');
      final notes = (data['notes'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [];
      if (!mounted) return;
      setState(() {
        _notes = notes;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _createNote() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final maxIntCtrl = TextEditingController(text: '10');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                    labelText: 'Title', border: OutlineInputBorder(), isDense: true)),
            const SizedBox(height: 8),
            TextField(
                controller: contentCtrl,
                decoration: const InputDecoration(
                    labelText: 'Content', border: OutlineInputBorder(), isDense: true),
                maxLines: 3),
            const SizedBox(height: 8),
            TextField(
                controller: maxIntCtrl,
                decoration: const InputDecoration(
                    labelText: 'Max Interactions', border: OutlineInputBorder(), isDense: true),
                keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await widget.apiClient.post('/agents/$_selectedAgentId/notes', body: {
                  'title': titleCtrl.text,
                  'content': contentCtrl.text,
                  'max_interactions': int.tryParse(maxIntCtrl.text) ?? 10,
                });
                _loadNotes();
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

  void _viewNote(Map<String, dynamic> note) {
    final contentCtrl = TextEditingController(text: note['content'] as String? ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(note['title'] as String? ?? 'Note'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                  controller: contentCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Content', border: OutlineInputBorder(), isDense: true),
                  maxLines: 5),
              const SizedBox(height: 8),
              Text('Interactions: ${note['interaction_count']}/${note['max_interactions']}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await widget.apiClient.put('/notes/${note['id']}', body: {
                  'content': contentCtrl.text,
                });
                _loadNotes();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNote(String noteId) async {
    try {
      await widget.apiClient.delete('/notes/$noteId');
      _loadNotes();
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
                    .map((a) => DropdownMenuItem(value: a.agentId, child: Text('${a.name} (${a.agentId})')))
                    .toList(),
                onChanged: (v) {
                  setState(() => _selectedAgentId = v);
                  _loadNotes();
                },
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _notes.isEmpty
                      ? const Center(child: Text('No notes'))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                          itemCount: _notes.length,
                          itemBuilder: (context, index) {
                            final note = _notes[index];
                            return Card(
                              child: ListTile(
                                title: Text(note['title'] as String? ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  '${(note['content'] as String? ?? '').substring(0, ((note['content'] as String?)?.length ?? 0).clamp(0, 80))}${((note['content'] as String?)?.length ?? 0) > 80 ? '...' : ''}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                        icon: const Icon(Icons.edit, size: 18),
                                        onPressed: () => _viewNote(note)),
                                    IconButton(
                                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                        onPressed: () => _deleteNote(note['id'] as String)),
                                  ],
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
            heroTag: 'add_note',
            onPressed: _createNote,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}
