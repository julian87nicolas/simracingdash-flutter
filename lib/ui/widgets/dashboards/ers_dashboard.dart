import 'package:flutter/material.dart';

import '../../../core/telemetry/telemetry_models.dart';
import '../components/telemetry_bar.dart';

class ERSDashboardWidget extends StatelessWidget {
  const ERSDashboardWidget({super.key, required this.frame});

  final TelemetryFrame frame;

  static const Map<int, String> _deployModes = <int, String>{
    0: 'NONE',
    1: 'MEDIUM',
    2: 'HOTLAP',
    3: 'OVERTAKE',
  };

  @override
  Widget build(BuildContext context) {
    final CarStatusData status = frame.status!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF10131A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.35)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('ERS STORE', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                TelemetryBar(
                  label: 'BATTERY',
                  value: status.ersFraction,
                  color: const Color(0xFF00E5FF),
                  height: 28,
                ),
                const SizedBox(height: 20),
                Text(
                  '${(status.ersFraction * 100).round()}%',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(fontSize: 64),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: Row(
            children: <Widget>[
              Expanded(
                child: _InfoCard(
                  label: 'MODE',
                  value: _deployModes[status.ersDeployMode] ?? 'MODE ${status.ersDeployMode}',
                  accent: const Color(0xFF00E5FF),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _InfoCard(
                  label: 'DEPLOYED',
                  value: '${(status.ersDeployedThisLap / 1000).toStringAsFixed(1)} kJ',
                  accent: const Color(0xFFFF4081),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.value, required this.accent});

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF10131A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: accent)),
            const SizedBox(height: 12),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}
