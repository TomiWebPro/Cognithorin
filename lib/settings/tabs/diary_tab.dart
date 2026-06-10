import 'package:flutter/material.dart';
import '../../services/api_service/api_client.dart';
import '../../services/api_service/models.dart';

class DiaryTab extends StatefulWidget {
  final ApiClient apiClient;
  final List<AgentRecord> agents;

  const DiaryTab({
    super.key,
    required this.apiClient,
    required this.agents,
  });

  @override
  State<DiaryTab> createState() => _DiaryTabState();
}

class _DiaryTabState extends State<DiaryTab> {
  String? _selectedAgentId;
  List<DiaryEntry> _entries = [];
  bool _loading = false;
  final _dateCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.agents.isNotEmpty) {
      _selectedAgentId = widget.agents.first.agentId;
      _loadEntries();
    }
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    if (_selectedAgentId == null) return;
    setState(() => _loading = true);
    try {
      var path = '/agents/$_selectedAgentId/diary';
      final dateFilter = _dateCtrl.text.trim();
      if (dateFilter.isNotEmpty) {
        path += '?date=$dateFilter';
      }
      final data = await widget.apiClient.get(path);
      final entries = (data['entries'] as List<dynamic>?)
              ?.map((e) => DiaryEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.agents.isEmpty) {
      return const Center(child: Text('No agents available'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(
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
                    _loadEntries();
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _dateCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Date filter (YYYY-MM-DD)',
                      border: OutlineInputBorder(),
                      isDense: true),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _loadEntries,
                child: const Text('Filter'),
              ),
              if (_dateCtrl.text.isNotEmpty)
                TextButton(
                  onPressed: () {
                    _dateCtrl.clear();
                    _loadEntries();
                  },
                  child: const Text('Clear'),
                ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _entries.isEmpty
                  ? const Center(child: Text('No diary entries'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _entries.length,
                      itemBuilder: (context, index) {
                        final e = _entries[index];
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(e.date,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold, fontSize: 12)),
                                    const Spacer(),
                                    if (e.updatedAt != null)
                                      Text(e.updatedAt!,
                                          style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(e.content, style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
