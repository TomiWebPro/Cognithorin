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
  final int maxPastActions;
  final bool agentCanChangeMaxPastActions;
  final bool showContextWindow;
  final bool showNotes;
  final bool showDiary;
  final bool showTime;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  AgentRecord({
    this.id,
    required this.agentId,
    required this.name,
    this.contextWindow = 4096,
    this.modelRef,
    this.backupModelRef,
    this.maxPastActions = 15,
    this.agentCanChangeMaxPastActions = false,
    this.showContextWindow = true,
    this.showNotes = true,
    this.showDiary = true,
    this.showTime = true,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'context_window': contextWindow,
        if (modelRef != null) 'model_ref': modelRef,
        if (backupModelRef != null) 'backup_model_ref': backupModelRef,
        'max_past_actions': maxPastActions,
        'agent_can_change_max_past_actions': agentCanChangeMaxPastActions,
        'show_context_window': showContextWindow,
        'show_notes': showNotes,
        'show_diary': showDiary,
        'show_time': showTime,
        'status': status,
      };

  factory AgentRecord.fromJson(Map<String, dynamic> json) => AgentRecord(
        id: json['id'] as int?,
        agentId: json['agent_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        contextWindow: json['context_window'] as int? ?? 4096,
        modelRef: json['model_ref'] as String?,
        backupModelRef: json['backup_model_ref'] as String?,
        maxPastActions: json['max_past_actions'] as int? ?? 15,
        agentCanChangeMaxPastActions:
            json['agent_can_change_max_past_actions'] as bool? ?? false,
        showContextWindow: json['show_context_window'] as bool? ?? true,
        showNotes: json['show_notes'] as bool? ?? true,
        showDiary: json['show_diary'] as bool? ?? true,
        showTime: json['show_time'] as bool? ?? true,
        status: json['status'] as String? ?? 'active',
        createdAt: json['created_at'] as String?,
        updatedAt: json['updated_at'] as String?,
      );
}

class DiaryEntry {
  final String date;
  final String content;
  final String? createdAt;
  final String? updatedAt;

  DiaryEntry({
    required this.date,
    required this.content,
    this.createdAt,
    this.updatedAt,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) => DiaryEntry(
        date: json['date'] as String? ?? '',
        content: json['content'] as String? ?? '',
        createdAt: json['created_at'] as String?,
        updatedAt: json['updated_at'] as String?,
      );
}

class AppParameter {
  final String name;
  final String type;
  final String description;
  final bool required;
  final String? defaultValue;
  final List<String> enumValues;

  AppParameter({
    this.name = '',
    this.type = 'string',
    this.description = '',
    this.required = false,
    this.defaultValue,
    this.enumValues = const [],
  });

  factory AppParameter.fromJson(Map<String, dynamic> json) => AppParameter(
        name: json['name'] as String? ?? '',
        type: json['type'] as String? ?? 'string',
        description: json['description'] as String? ?? '',
        required: json['required'] as bool? ?? false,
        defaultValue: json['default'] as String?,
        enumValues: (json['enum'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
      );
}

class AppRecord {
  final int? id;
  final String appId;
  final String name;
  final String description;
  final String version;
  final String author;
  final String type;
  final String icon;
  final String? manifest;
  final String? directory;
  final bool isAvailable;
  final bool requiresConfirmation;
  final int timeoutSeconds;
  final String? createdAt;
  final String? updatedAt;

  AppRecord({
    this.id,
    required this.appId,
    required this.name,
    this.description = '',
    this.version = '1.0.0',
    this.author = 'system',
    this.type = 'builtin',
    this.icon = '◆',
    this.manifest,
    this.directory,
    this.isAvailable = true,
    this.requiresConfirmation = false,
    this.timeoutSeconds = 30,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'app_id': appId,
        'name': name,
        'description': description,
        'version': version,
        'author': author,
        'type': type,
        'icon': icon,
        if (manifest != null) 'manifest': manifest,
        if (directory != null) 'directory': directory,
        'is_available': isAvailable,
        'requires_confirmation': requiresConfirmation,
        'timeout_seconds': timeoutSeconds,
      };

  factory AppRecord.fromJson(Map<String, dynamic> json) => AppRecord(
        id: json['id'] as int?,
        appId: json['app_id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        version: json['version'] as String? ?? '1.0.0',
        author: json['author'] as String? ?? 'system',
        type: json['type'] as String? ?? 'builtin',
        icon: json['icon'] as String? ?? '◆',
        manifest: json['manifest'] as String?,
        directory: json['directory'] as String?,
        isAvailable: json['is_available'] as bool? ?? true,
        requiresConfirmation: json['requires_confirmation'] as bool? ?? false,
        timeoutSeconds: json['timeout_seconds'] as int? ?? 30,
        createdAt: json['created_at'] as String?,
        updatedAt: json['updated_at'] as String?,
      );
}

class AgentAppRecord {
  final int? id;
  final String agentId;
  final String appId;
  final bool isEnabled;
  final String? config;
  final String? installedAt;
  final String? updatedAt;

  AgentAppRecord({
    this.id,
    required this.agentId,
    required this.appId,
    this.isEnabled = true,
    this.config,
    this.installedAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'agent_id': agentId,
        'app_id': appId,
        'is_enabled': isEnabled,
        if (config != null) 'config': config,
      };

  factory AgentAppRecord.fromJson(Map<String, dynamic> json) => AgentAppRecord(
        id: json['id'] as int?,
        agentId: json['agent_id'] as String? ?? '',
        appId: json['app_id'] as String? ?? '',
        isEnabled: json['is_enabled'] as bool? ?? true,
        config: json['config'] as String?,
        installedAt: json['installed_at'] as String?,
        updatedAt: json['updated_at'] as String?,
      );
}

class AgentRuntime {
  final AgentRecord agent;
  final List<Map<String, dynamic>> recentActions;
  final List<Map<String, dynamic>> notes;
  final int notesCount;
  final int diaryCount;
  final String? latestDiary;
  final int alarmsCount;
  final List<Map<String, dynamic>> alarms;
  final List<Map<String, dynamic>> openTabs;
  final int installedAppsCount;
  final int enabledAppsCount;
  final int contextWindow;

  AgentRuntime({
    required this.agent,
    this.recentActions = const [],
    this.notes = const [],
    this.notesCount = 0,
    this.diaryCount = 0,
    this.latestDiary,
    this.alarmsCount = 0,
    this.alarms = const [],
    this.openTabs = const [],
    this.installedAppsCount = 0,
    this.enabledAppsCount = 0,
    this.contextWindow = 4096,
  });

  factory AgentRuntime.fromJson(Map<String, dynamic> json) {
    final agentJson = json['agent'] as Map<String, dynamic>? ?? {};
    return AgentRuntime(
      agent: AgentRecord.fromJson(agentJson),
      recentActions: (json['recent_actions'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      notes: (json['notes'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      notesCount: json['notes_count'] as int? ?? 0,
      diaryCount: json['diary_count'] as int? ?? 0,
      latestDiary: json['latest_diary'] as String?,
      alarmsCount: json['alarms_count'] as int? ?? 0,
      alarms: (json['alarms'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      openTabs: (json['open_tabs'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      installedAppsCount: json['installed_apps_count'] as int? ?? 0,
      enabledAppsCount: json['enabled_apps_count'] as int? ?? 0,
      contextWindow: json['context_window'] as int? ?? 4096,
    );
  }
}

class PeriodTokenUsage {
  final int inputTokens;
  final int outputTokens;
  final double cost;
  final int runs;

  PeriodTokenUsage({
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.cost = 0.0,
    this.runs = 0,
  });

  factory PeriodTokenUsage.fromJson(Map<String, dynamic> json) =>
      PeriodTokenUsage(
        inputTokens: json['input_tokens'] as int? ?? 0,
        outputTokens: json['output_tokens'] as int? ?? 0,
        cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
        runs: json['runs'] as int? ?? 0,
      );
}

class AgentTokenSummary {
  final String name;
  final Map<String, PeriodTokenUsage> periods;

  AgentTokenSummary({required this.name, required this.periods});

  factory AgentTokenSummary.fromJson(
          String agentId, Map<String, dynamic> json) =>
      AgentTokenSummary(
        name: json['_name'] as String? ?? agentId,
        periods: json.entries
            .where((e) => e.key != '_name')
            .fold<Map<String, PeriodTokenUsage>>({}, (map, e) {
          map[e.key] = PeriodTokenUsage.fromJson(
              e.value as Map<String, dynamic>);
          return map;
        }),
      );
}

class TimingBreakdown {
  final double generatingMs;
  final double harnessMs;
  final double waitRequestedMs;
  final double totalMs;
  final int runs;

  TimingBreakdown({
    this.generatingMs = 0.0,
    this.harnessMs = 0.0,
    this.waitRequestedMs = 0.0,
    this.totalMs = 0.0,
    this.runs = 0,
  });

  factory TimingBreakdown.fromJson(Map<String, dynamic> json) =>
      TimingBreakdown(
        generatingMs: (json['generating_ms'] as num?)?.toDouble() ?? 0.0,
        harnessMs: (json['harness_ms'] as num?)?.toDouble() ?? 0.0,
        waitRequestedMs:
            (json['wait_requested_ms'] as num?)?.toDouble() ?? 0.0,
        totalMs: (json['total_ms'] as num?)?.toDouble() ?? 0.0,
        runs: json['runs'] as int? ?? 0,
      );

  double get remainingMs => totalMs - generatingMs - harnessMs;
  double get generatingPct =>
      totalMs > 0 ? (generatingMs / totalMs) * 100 : 0;
  double get harnessPct => totalMs > 0 ? (harnessMs / totalMs) * 100 : 0;
  double get waitPct =>
      totalMs > 0 ? (waitRequestedMs / totalMs) * 100 : 0;
  double get idlePct {
    final accounted = generatingMs + harnessMs + waitRequestedMs;
    return totalMs > 0
        ? ((totalMs - accounted) / totalMs).clamp(0, 1) * 100
        : 0;
  }

  String get generatingLabel => _fmtMs(generatingMs);
  String get harnessLabel => _fmtMs(harnessMs);
  String get waitLabel => _fmtMs(waitRequestedMs);
  String get idleLabel => _fmtMs(remainingMs);
  String get totalLabel => _fmtMs(totalMs);

  static String _fmtMs(double ms) {
    if (ms >= 60000) return '${(ms / 60000).toStringAsFixed(1)}m';
    if (ms >= 1000) return '${(ms / 1000).toStringAsFixed(1)}s';
    return '${ms.toStringAsFixed(0)}ms';
  }
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
