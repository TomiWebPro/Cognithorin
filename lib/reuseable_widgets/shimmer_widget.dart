import 'package:flutter/material.dart';

class ShimmerWidget extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerWidget({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  State<ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseColor = theme.brightness == Brightness.light
        ? Colors.grey.shade200
        : Colors.grey.shade800;
    final highlightColor = theme.brightness == Brightness.light
        ? Colors.grey.shade50
        : Colors.grey.shade700;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
                (_animation.value + 0.6).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

class DashboardShimmer extends StatelessWidget {
  const DashboardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const ShimmerWidget(width: 10, height: 10, borderRadius: 5),
                    const SizedBox(width: 10),
                    const Expanded(child: ShimmerWidget(height: 18, borderRadius: 4)),
                    ShimmerWidget(width: 60, height: 22, borderRadius: 8),
                  ],
                ),
                const SizedBox(height: 6),
                const ShimmerWidget(height: 14, borderRadius: 4),
                const SizedBox(height: 2),
                const ShimmerWidget(width: 120, height: 12, borderRadius: 4),
                const SizedBox(height: 12),
                const Divider(height: 8),
                Row(
                  children: [
                    _miniChipShimmer(),
                    const SizedBox(width: 12),
                    _miniChipShimmer(),
                    const SizedBox(width: 12),
                    _miniChipShimmer(),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ShimmerWidget(width: 32, height: 32, borderRadius: 16),
                    const SizedBox(width: 8),
                    ShimmerWidget(width: 32, height: 32, borderRadius: 16),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _miniChipShimmer() {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShimmerWidget(width: 14, height: 14, borderRadius: 7),
        SizedBox(width: 4),
        ShimmerWidget(width: 20, height: 12, borderRadius: 4),
      ],
    );
  }
}

class SettingsShimmer extends StatelessWidget {
  const SettingsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          ShimmerWidget(height: 14, borderRadius: 4),
          SizedBox(height: 24),
          ShimmerWidget(height: 60, borderRadius: 12),
          SizedBox(height: 12),
          ShimmerWidget(height: 60, borderRadius: 12),
          SizedBox(height: 12),
          ShimmerWidget(height: 60, borderRadius: 12),
          SizedBox(height: 12),
          ShimmerWidget(height: 60, borderRadius: 12),
          SizedBox(height: 12),
          ShimmerWidget(height: 60, borderRadius: 12),
        ],
      ),
    );
  }
}
