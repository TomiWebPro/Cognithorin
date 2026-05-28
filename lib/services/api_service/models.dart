class UsageInfo {
  final int inputTokens;
  final int outputTokens;
  final double cost;
  final double durationMs;
  final String model;

  UsageInfo({
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.cost = 0.0,
    this.durationMs = 0.0,
    this.model = '',
  });

  factory UsageInfo.fromJson(Map<String, dynamic> json) => UsageInfo(
        inputTokens: json['input_tokens'] as int? ?? 0,
        outputTokens: json['output_tokens'] as int? ?? 0,
        cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
        durationMs: (json['duration_ms'] as num?)?.toDouble() ?? 0.0,
        model: json['model'] as String? ?? '',
      );
}

class ProviderRecord {
  final int? id;
  final String name;
  final String? apiKey;
  final String baseUrl;
  final String endpointPath;
  final Map<String, String> models;
  final Map<String, bool> activeModels;
  final Map<String, String> headersTemplate;
  final String authType;
  final String? authHeaderName;
  final String bodyTemplate;
  final String responseContentPath;
  final String responseUsageInputPath;
  final String responseUsageOutputPath;
  final String? responseUsageCostPath;
  bool isStreaming;
  bool isActive;
  final int maxRetries;
  final int timeoutSeconds;
  final int maxConcurrent;

  ProviderRecord({
    this.id,
    required this.name,
    this.apiKey,
    required this.baseUrl,
    this.endpointPath = '/chat/completions',
    this.models = const {},
    this.activeModels = const {},
    this.headersTemplate = const {},
    this.authType = 'bearer',
    this.authHeaderName,
    this.bodyTemplate = '{"model": "\${model}", "messages": \${messages_json}, "temperature": \${temperature}, "max_tokens": \${max_tokens}}',
    this.responseContentPath = 'choices.0.message.content',
    this.responseUsageInputPath = 'usage.prompt_tokens',
    this.responseUsageOutputPath = 'usage.completion_tokens',
    this.responseUsageCostPath,
    this.isStreaming = false,
    this.isActive = false,
    this.maxRetries = 3,
    this.timeoutSeconds = 60,
    this.maxConcurrent = 5,
  });

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        if (apiKey != null) 'api_key': apiKey,
        'base_url': baseUrl,
        'endpoint_path': endpointPath,
        'models': models,
        'active_models': activeModels,
        'headers_template': headersTemplate,
        'auth_type': authType,
        if (authHeaderName != null) 'auth_header_name': authHeaderName,
        'body_template': bodyTemplate,
        'response_content_path': responseContentPath,
        'response_usage_input_path': responseUsageInputPath,
        'response_usage_output_path': responseUsageOutputPath,
        if (responseUsageCostPath != null)
          'response_usage_cost_path': responseUsageCostPath,
        'is_streaming': isStreaming,
        'is_active': isActive,
        'max_retries': maxRetries,
        'timeout_seconds': timeoutSeconds,
        'max_concurrent': maxConcurrent,
      };

  factory ProviderRecord.fromJson(Map<String, dynamic> json) => ProviderRecord(
        id: json['id'] as int?,
        name: json['name'] as String,
        apiKey: json['api_key'] as String?,
        baseUrl: json['base_url'] as String? ?? '',
        endpointPath: json['endpoint_path'] as String? ?? '/chat/completions',
        models: (json['models'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as String)) ??
            {},
        activeModels: (json['active_models'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v == true)) ??
            {},
        headersTemplate: (json['headers_template'] as Map<String, dynamic>?)
                ?.map((k, v) => MapEntry(k, v as String)) ??
            {},
        authType: json['auth_type'] as String? ?? 'bearer',
        authHeaderName: json['auth_header_name'] as String?,
        bodyTemplate: json['body_template'] as String? ?? '',
        responseContentPath:
            json['response_content_path'] as String? ?? 'choices.0.message.content',
        responseUsageInputPath:
            json['response_usage_input_path'] as String? ?? 'usage.prompt_tokens',
        responseUsageOutputPath:
            json['response_usage_output_path'] as String? ?? 'usage.completion_tokens',
        responseUsageCostPath: json['response_usage_cost_path'] as String?,
        isStreaming: json['is_streaming'] as bool? ?? false,
        isActive: json['is_active'] as bool? ?? false,
        maxRetries: json['max_retries'] as int? ?? 3,
        timeoutSeconds: json['timeout_seconds'] as int? ?? 60,
        maxConcurrent: json['max_concurrent'] as int? ?? 5,
      );
}

class AgentRecord {
  final int? id;
  final String agentId;
  final String name;
  final int contextWindow;
  final String? modelRef;
  final String? backupModelRef;
  final String? createdAt;
  final String? updatedAt;

  AgentRecord({
    this.id,
    required this.agentId,
    required this.name,
    this.contextWindow = 4096,
    this.modelRef,
    this.backupModelRef,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'context_window': contextWindow,
        if (modelRef != null) 'model_ref': modelRef,
        if (backupModelRef != null) 'backup_model_ref': backupModelRef,
      };

  factory AgentRecord.fromJson(Map<String, dynamic> json) => AgentRecord(
        id: json['id'] as int?,
        agentId: json['agent_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        contextWindow: json['context_window'] as int? ?? 4096,
        modelRef: json['model_ref'] as String?,
        backupModelRef: json['backup_model_ref'] as String?,
        createdAt: json['created_at'] as String?,
        updatedAt: json['updated_at'] as String?,
      );
}

class EndpointStatus {
  final String provider;
  final bool available;
  final double? latencyMs;
  final String? error;

  EndpointStatus({
    required this.provider,
    this.available = false,
    this.latencyMs,
    this.error,
  });

  factory EndpointStatus.fromJson(Map<String, dynamic> json) => EndpointStatus(
        provider: json['provider'] as String? ?? '',
        available: json['available'] as bool? ?? false,
        latencyMs: (json['latency_ms'] as num?)?.toDouble(),
        error: json['error'] as String?,
      );
}
