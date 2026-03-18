import 'package:flutter/material.dart';

import '../../../core/telemetry/telemetry_models.dart';
import '../components/telemetry_bar.dart';

class DamageDashboardWidget extends StatelessWidget {
  const DamageDashboardWidget({super.key, required this.frame});

  final TelemetryFrame frame;

  @override
  Widget build(BuildContext context) {
    final CarDamageData damage = frame.damage!;
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _DamageTile(label: 'FL WING', value: damage.frontLeftWingDamage / 100),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DamageTile(label: 'FR WING', value: damage.frontRightWingDamage / 100),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _DamageTile(label: 'REAR', value: damage.rearWingDamage / 100),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _DamagePanel(label: 'ENGINE', entries: <MapEntry<String, double>>[
          MapEntry<String, double>('Overall', damage.engineDamage / 100),
          MapEntry<String, double>('MGU-H', damage.engineMGUHWear / 100),
          MapEntry<String, double>('ES', damage.engineESWear / 100),
          MapEntry<String, double>('CE', damage.engineCEWear / 100),
          MapEntry<String, double>('ICE', damage.engineICEWear / 100),
          MapEntry<String, double>('MGU-K', damage.engineMGUKWear / 100),
          MapEntry<String, double>('TC', damage.engineTCWear / 100),
        ]),
        const SizedBox(height: 16),
        _DamagePanel(label: 'TYRES', entries: List<MapEntry<String, double>>.generate(
          4,
          (int index) => MapEntry<String, double>('Tyre ${index + 1}', damage.tyresWear[index] / 100),
          growable: false,
        )),
      ],
    );
  }
}

class _DamageTile extends StatelessWidget {
  const _DamageTile({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF10131A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 12),
            Text('${(value * 100).round()}%', style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}

class _DamagePanel extends StatelessWidget {
  const _DamagePanel({required this.label, required this.entries});

  final String label;
  final List<MapEntry<String, double>> entries;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF10131A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            ...entries.map((MapEntry<String, double> entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TelemetryBar(
                    label: entry.key,
                    value: entry.value,
                    color: const Color(0xFFFF5252),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
