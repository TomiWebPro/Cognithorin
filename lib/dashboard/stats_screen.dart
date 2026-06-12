import 'package:flutter/material.dart';
import '../services/api_service/api_client.dart';
import '../services/api_service/stats_service.dart';
import '../services/api_service/models.dart';

class StatsScreen extends StatefulWidget {
  final ApiClient apiClient;
  const StatsScreen({super.key, required this.apiClient});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late final StatsService _statsService;
  String _selectedPeriod = '24h';
  static const _allPeriods = ['1h', '3h', '12h', '24h', '7d', 'all'];

  PeriodTokenUsage? _tokenUsage;
  TimingBreakdown? _timing;
  List<_AgentStat> _agents = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _statsService = StatsService(widget.apiClient);
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final tokRes = await _statsService.getTokenUsage(periods: _allPeriods);
      final timRes = await _statsService.getTiming(periods: _allPeriods);
      final agentRes = await _statsService.getTokenUsageByAgent(periods: _allPeriods);

      if (!mounted) return;

      final tokPeriods = (tokRes['periods'] as Map<String, dynamic>?) ?? {};
      final timPeriods = (timRes['periods'] as Map<String, dynamic>?) ?? {};
      final agentMap = (agentRes['agents'] as Map<String, dynamic>?) ?? {};

      setState(() {
        _tokenUsage = tokPeriods[_selectedPeriod] != null
            ? PeriodTokenUsage.fromJson(
                tokPeriods[_selectedPeriod] as Map<String, dynamic>)
            : null;
        _timing = timPeriods[_selectedPeriod] != null
            ? TimingBreakdown.fromJson(
                timPeriods[_selectedPeriod] as Map<String, dynamic>)
            : null;
        _agents = agentMap.entries.map((e) {
          final v = e.value as Map<String, dynamic>;
          return _AgentStat(
            name: v['_name'] as String? ?? e.key,
            agentId: e.key,
            tokenUsage: v[_selectedPeriod] != null
                ? PeriodTokenUsage.fromJson(
                    v[_selectedPeriod] as Map<String, dynamic>)
                : PeriodTokenUsage(),
          );
        }).toList()
          ..sort(
              (a, b) => (b.tokenUsage.inputTokens + b.tokenUsage.outputTokens)
                  .compareTo(a.tokenUsage.inputTokens + a.tokenUsage.outputTokens));
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _selectPeriod(String period) {
    setState(() => _selectedPeriod = period);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Token Usage Stats'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _periodSelector(),
                      const SizedBox(height: 16),
                      _tokenUsageCard(),
                      const SizedBox(height: 16),
                      _timingCard(),
                      const SizedBox(height: 16),
                      _perAgentCard(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.amber, size: 48),
            const SizedBox(height: 16),
            const Text('Failed to load stats',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
            const SizedBox(height: 8),
            Text(_error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: _load,
            ),
          ],
        ),
      ),
    );
  }

  Widget _periodSelector() {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _allPeriods.map((p) {
          final selected = p == _selectedPeriod;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(p.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  )),
              selected: selected,
              onSelected: (_) => _selectPeriod(p),
              selectedColor: theme.colorScheme.primaryContainer,
              checkmarkColor: theme.colorScheme.onPrimaryContainer,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _tokenUsageCard() {
    final usage = _tokenUsage;
    if (usage == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text('No token usage data for this period',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        ),
      );
    }
    final maxVal = [usage.inputTokens, usage.outputTokens]
        .reduce((a, b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Token Usage',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            _tokenBar('Input', usage.inputTokens, maxVal,
                Theme.of(context).colorScheme.primary),
            const SizedBox(height: 10),
            _tokenBar('Output', usage.outputTokens, maxVal,
                Theme.of(context).colorScheme.tertiary),
            const SizedBox(height: 10),
            _tokenBar('Total', usage.inputTokens + usage.outputTokens,
                maxVal, Theme.of(context).colorScheme.secondary),
            const Divider(height: 24),
            _infoRow('Cost', '\$${usage.cost.toStringAsFixed(4)}'),
            _infoRow('Runs', '${usage.runs}'),
          ],
        ),
      ),
    );
  }

  Widget _tokenBar(String label, int value, int maxVal, Color color) {
    final pct = maxVal > 0 ? value / maxVal : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            Text(_fmtTokens(value),
                style: const TextStyle(fontSize: 13)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: CustomPaint(
            size: const Size(double.infinity, 14),
            painter: _TokenBarPainter(pct: pct, color: color),
          ),
        ),
      ],
    );
  }

  Widget _timingCard() {
    final timing = _timing;
    if (timing == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text('No timing data for this period',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Timing Breakdown',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            SizedBox(
              height: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: CustomPaint(
                  size: const Size(double.infinity, 20),
                  painter: _TimingStackPainter(
                    genPct: timing.generatingPct / 100,
                    harnessPct: timing.harnessPct / 100,
                    waitPct: timing.waitPct / 100,
                    idlePct: timing.idlePct / 100,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _timingLegend('Generating', timing.generatingLabel,
                timing.generatingPct, Colors.blue),
            _timingLegend('Harness', timing.harnessLabel,
                timing.harnessPct, Colors.green),
            _timingLegend('Waiting', timing.waitLabel,
                timing.waitPct, Colors.orange),
            _timingLegend('Idle', timing.idleLabel,
                timing.idlePct, Colors.grey),
            const Divider(height: 24),
            _infoRow('Total Duration', timing.totalLabel),
            _infoRow('Total Runs', '${timing.runs}'),
          ],
        ),
      ),
    );
  }

  Widget _timingLegend(
      String label, String value, double pct, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13)),
          ),
          Text('${pct.toStringAsFixed(1)}%',
              style: TextStyle(
                  fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _perAgentCard() {
    if (_agents.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text('No agent data for this period',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Per Agent Breakdown',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ..._agents.map((a) => _agentTile(a)),
          ],
        ),
      ),
    );
  }

  Widget _agentTile(_AgentStat agent) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 0),
        childrenPadding: const EdgeInsets.only(left: 8, bottom: 8),
        title: Row(
          children: [
            Icon(Icons.person, size: 18,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(agent.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ),
            Text(_fmtTokens(agent.tokenUsage.inputTokens + agent.tokenUsage.outputTokens),
                style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
        children: [
          _infoRow('Input', _fmtTokens(agent.tokenUsage.inputTokens)),
          _infoRow('Output', _fmtTokens(agent.tokenUsage.outputTokens)),
          _infoRow('Cost', '\$${agent.tokenUsage.cost.toStringAsFixed(4)}'),
          _infoRow('Runs', '${agent.tokenUsage.runs}'),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  String _fmtTokens(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _AgentStat {
  final String name;
  final String agentId;
  final PeriodTokenUsage tokenUsage;
  _AgentStat({
    required this.name,
    required this.agentId,
    required this.tokenUsage,
  });
}

class _TokenBarPainter extends CustomPainter {
  final double pct;
  final Color color;
  _TokenBarPainter({required this.pct, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = Colors.grey.withValues(alpha: 0.15);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, size.width, size.height),
            const Radius.circular(4)),
        bgPaint);

    if (pct <= 0) return;
    final fillPaint = Paint()..color = color;
    final fillWidth = size.width * pct.clamp(0.0, 1.0);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, fillWidth, size.height),
            const Radius.circular(4)),
        fillPaint);
  }

  @override
  bool shouldRepaint(covariant _TokenBarPainter old) =>
      old.pct != pct || old.color != color;
}

class _TimingStackPainter extends CustomPainter {
  final double genPct;
  final double harnessPct;
  final double waitPct;
  final double idlePct;
  _TimingStackPainter({
    required this.genPct,
    required this.harnessPct,
    required this.waitPct,
    required this.idlePct,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final total = genPct + harnessPct + waitPct + idlePct;
    if (total <= 0) {
      final bgPaint = Paint()..color = Colors.grey.withValues(alpha: 0.15);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(0, 0, size.width, size.height),
              const Radius.circular(6)),
          bgPaint);
      return;
    }

    final segments = [
      (genPct / total, Colors.blue),
      (harnessPct / total, Colors.green),
      (waitPct / total, Colors.orange),
      (idlePct / total, Colors.grey),
    ];

    double dx = 0;
    final r = const Radius.circular(6);
    for (var i = 0; i < segments.length; i++) {
      final frac = segments[i].$1;
      if (frac <= 0) continue;
      final w = size.width * frac;
      final isFirst = i == 0;
      final isLast = i == segments.length - 1 || _remainingIsZero(segments, i);
      final paint = Paint()..color = segments[i].$2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(dx, 0, w, size.height),
          Radius.elliptical(
              isFirst ? r.x : 0, isLast || isFirst ? r.y : 0),
        ),
        paint,
      );
      dx += w;
    }
  }

  bool _remainingIsZero(List<(double, Color)> segs, int idx) {
    for (var i = idx + 1; i < segs.length; i++) {
      if (segs[i].$1 > 0) return false;
    }
    return true;
  }

  @override
  bool shouldRepaint(covariant _TimingStackPainter old) =>
      old.genPct != genPct ||
      old.harnessPct != harnessPct ||
      old.waitPct != waitPct ||
      old.idlePct != idlePct;
}
