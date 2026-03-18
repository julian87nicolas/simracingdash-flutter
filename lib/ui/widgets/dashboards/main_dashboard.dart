import 'package:flutter/material.dart';

import '../../../core/telemetry/telemetry_models.dart';
import '../components/rpm_bar.dart';
import '../components/telemetry_bar.dart';

class MainDashboardWidget extends StatelessWidget {
  const MainDashboardWidget({super.key, required this.frame});

  final TelemetryFrame frame;

  @override
  Widget build(BuildContext context) {
    final CarTelemetryData telemetry = frame.telemetry!;
    final CarStatusData? status = frame.status;
    final String gear = telemetry.gear == 0
        ? 'N'
        : telemetry.gear == -1
            ? 'R'
            : telemetry.gear.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(
          child: Row(
            children: <Widget>[
              Expanded(
                child: _StatCard(
                  label: 'SPEED',
                  value: '${telemetry.speed}',
                  unit: 'km/h',
                  accent: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatCard(
                  label: 'POS',
                  value: '${frame.lapData?.position ?? '--'}',
                  unit: 'race',
                  accent: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            gear,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 120,
                  height: 0.9,
                  color: Colors.white,
                ),
          ),
        ),
        const SizedBox(height: 16),
        RpmBar(rpmFraction: telemetry.engineRpm / 15000),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'RPM ${telemetry.engineRpm}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (telemetry.drs)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0xFF00E676)),
                ),
                child: const Text('DRS OPEN'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        TelemetryBar(label: 'THROTTLE', value: telemetry.throttle, color: const Color(0xFF00E676), height: 20),
        const SizedBox(height: 12),
        TelemetryBar(label: 'BRAKE', value: telemetry.brake, color: const Color(0xFFFF3D00), height: 20),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            Expanded(
              child: _StatCard(
                label: 'FUEL',
                value: status == null ? '--' : status.fuelInTank.toStringAsFixed(1),
                unit: 'L',
                accent: const Color(0xFFFFC400),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _StatCard(
                label: 'BRAKE BIAS',
                value: '${status?.brakeBias ?? '--'}',
                unit: '%',
                accent: const Color(0xFF40C4FF),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.accent,
  });

  final String label;
  final String value;
  final String unit;
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: accent)),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                children: <InlineSpan>[
                  TextSpan(
                    text: value,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  TextSpan(
                    text: ' $unit',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
