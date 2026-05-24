import 'package:flutter/material.dart';
import '../services/api_service/models.dart';
import '../services/api_service/provider_service.dart';

class ProviderFormScreen extends StatefulWidget {
  final ProviderRecord? existing;
  final ProviderService providerService;

  const ProviderFormScreen({
    super.key,
    this.existing,
    required this.providerService,
  });

  @override
  State<ProviderFormScreen> createState() => _ProviderFormScreenState();
}

class _ProviderFormScreenState extends State<ProviderFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _apiKeyCtrl;
  late final TextEditingController _baseUrlCtrl;
  late final TextEditingController _endpointPathCtrl;
  late final TextEditingController _bodyTemplateCtrl;
  late final TextEditingController _contentPathCtrl;
  late final TextEditingController _usageInputPathCtrl;
  late final TextEditingController _usageOutputPathCtrl;
  late final TextEditingController _usageCostPathCtrl;
  late final TextEditingController _headerTemplateCtrl;
  late final TextEditingController _authHeaderNameCtrl;
  late final TextEditingController _maxRetriesCtrl;
  late final TextEditingController _timeoutCtrl;
  late final TextEditingController _maxConcurrentCtrl;

  String _authType = 'bearer';
  bool _isStreaming = false;
  bool _saving = false;
  bool _testing = false;
  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _apiKeyCtrl = TextEditingController(text: e?.apiKey ?? '');
    _baseUrlCtrl = TextEditingController(text: e?.baseUrl ?? '');
    _endpointPathCtrl = TextEditingController(
      text: e?.endpointPath ?? '/chat/completions',
    );
    _bodyTemplateCtrl = TextEditingController(
      text: e?.bodyTemplate ??
          '{"model": "\${model}", "messages": \${messages_json}, '
              '"temperature": \${temperature}, "max_tokens": \${max_tokens}}',
    );
    _contentPathCtrl = TextEditingController(
      text: e?.responseContentPath ?? 'choices.0.message.content',
    );
    _usageInputPathCtrl = TextEditingController(
      text: e?.responseUsageInputPath ?? 'usage.prompt_tokens',
    );
    _usageOutputPathCtrl = TextEditingController(
      text: e?.responseUsageOutputPath ?? 'usage.completion_tokens',
    );
    _usageCostPathCtrl = TextEditingController(text: e?.responseUsageCostPath ?? '');
    _headerTemplateCtrl = TextEditingController(
      text: e?.headersTemplate.entries
              .map((e) => '${e.key}: ${e.value}')
              .join('\n') ??
          '',
    );
    _authHeaderNameCtrl = TextEditingController(text: e?.authHeaderName ?? '');
    _maxRetriesCtrl = TextEditingController(
      text: (e?.maxRetries ?? 3).toString(),
    );
    _timeoutCtrl = TextEditingController(
      text: (e?.timeoutSeconds ?? 60).toString(),
    );
    _maxConcurrentCtrl = TextEditingController(
      text: (e?.maxConcurrent ?? 5).toString(),
    );
    _authType = e?.authType ?? 'bearer';
    _isStreaming = e?.isStreaming ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _apiKeyCtrl.dispose();
    _baseUrlCtrl.dispose();
    _endpointPathCtrl.dispose();
    _bodyTemplateCtrl.dispose();
    _contentPathCtrl.dispose();
    _usageInputPathCtrl.dispose();
    _usageOutputPathCtrl.dispose();
    _usageCostPathCtrl.dispose();
    _headerTemplateCtrl.dispose();
    _authHeaderNameCtrl.dispose();
    _maxRetriesCtrl.dispose();
    _timeoutCtrl.dispose();
    _maxConcurrentCtrl.dispose();
    super.dispose();
  }

  Map<String, String> _parseHeaders() {
    final result = <String, String>{};
    for (final line in _headerTemplateCtrl.text.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      final colon = trimmed.indexOf(':');
      if (colon > 0) {
        result[trimmed.substring(0, colon).trim()] =
            trimmed.substring(colon + 1).trim();
      }
    }
    return result;
  }

  ProviderRecord _buildRecord() {
    return ProviderRecord(
      id: widget.existing?.id,
      name: _nameCtrl.text.trim(),
      apiKey: _apiKeyCtrl.text.trim().isEmpty
          ? null
          : _apiKeyCtrl.text.trim(),
      baseUrl: _baseUrlCtrl.text.trim(),
      endpointPath: _endpointPathCtrl.text.trim(),
      models: widget.existing?.models ?? {},
      activeModels: widget.existing?.activeModels ?? {},
      headersTemplate: _parseHeaders(),
      authType: _authType,
      authHeaderName: _authHeaderNameCtrl.text.trim().isEmpty
          ? null
          : _authHeaderNameCtrl.text.trim(),
      bodyTemplate: _bodyTemplateCtrl.text.trim(),
      responseContentPath: _contentPathCtrl.text.trim(),
      responseUsageInputPath: _usageInputPathCtrl.text.trim(),
      responseUsageOutputPath: _usageOutputPathCtrl.text.trim(),
      responseUsageCostPath: _usageCostPathCtrl.text.trim().isEmpty
          ? null
          : _usageCostPathCtrl.text.trim(),
      isStreaming: _isStreaming,
      isActive: widget.existing?.isActive ?? false,
      maxRetries: int.tryParse(_maxRetriesCtrl.text) ?? 3,
      timeoutSeconds: int.tryParse(_timeoutCtrl.text) ?? 60,
      maxConcurrent: int.tryParse(_maxConcurrentCtrl.text) ?? 5,
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final record = _buildRecord();
      if (_isNew) {
        await widget.providerService.createProvider(record);
      } else {
        await widget.providerService.updateProvider(record.name, record);
      }
      if (!mounted) return;
      Navigator.pop(context, record);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _test() async {
    setState(() => _testing = true);
    try {
      final result = await widget.providerService.testProvider(
        _nameCtrl.text.trim(),
      );
      if (!mounted) return;
      final available = result['available'] as bool? ?? false;
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
            children: [
              Text(
                available ? 'Connection successful' : 'Connection failed',
              ),
              if (latency != null)
                Text('Latency: ${(latency as num).toStringAsFixed(0)} ms'),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    error.toString(),
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Add Provider' : 'Edit Provider'),
        actions: [
          if (!_isNew)
            TextButton.icon(
              onPressed: _testing ? null : _test,
              icon: _testing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_find, size: 18),
              label: const Text('Test'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('General', [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name *'),
                readOnly: !_isNew,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _baseUrlCtrl,
                decoration: const InputDecoration(labelText: 'Base URL *'),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _endpointPathCtrl,
                decoration: const InputDecoration(
                  labelText: 'Endpoint Path',
                ),
              ),
              TextFormField(
                controller: _apiKeyCtrl,
                decoration: const InputDecoration(labelText: 'API Key'),
                obscureText: true,
              ),
            ]),
            _section('Authentication', [
              DropdownButtonFormField<String>(
                initialValue: _authType,
                decoration: const InputDecoration(labelText: 'Auth Type'),
                items: const [
                  DropdownMenuItem(value: 'bearer', child: Text('Bearer Token')),
                  DropdownMenuItem(value: 'header', child: Text('Custom Header')),
                  DropdownMenuItem(value: 'none', child: Text('None')),
                  DropdownMenuItem(value: 'basic', child: Text('Basic Auth')),
                ],
                onChanged: (v) => setState(() => _authType = v ?? 'bearer'),
              ),
              if (_authType == 'header')
                TextFormField(
                  controller: _authHeaderNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Auth Header Name',
                    hintText: 'x-api-key',
                  ),
                ),
            ]),

            _section('Advanced', [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _maxRetriesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Max Retries',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _timeoutCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Timeout (sec)',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _maxConcurrentCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Max Concurrent',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                title: const Text('Streaming'),
                value: _isStreaming,
                onChanged: (v) => setState(() => _isStreaming = v),
                contentPadding: EdgeInsets.zero,
              ),
            ]),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isNew ? 'Add Provider' : 'Save Changes'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          ...children.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: w,
              )),
        ],
      ),
    );
  }
}
