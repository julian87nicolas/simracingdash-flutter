import 'package:flutter/material.dart';

import '../../../core/telemetry/telemetry_models.dart';
import '../components/telemetry_bar.dart';

class TyresDashboardWidget extends StatelessWidget {
  const TyresDashboardWidget({super.key, required this.frame});

  final TelemetryFrame frame;

  static const List<String> _labels = <String>['FL', 'FR', 'RL', 'RR'];

  @override
  Widget build(BuildContext context) {
    final CarTelemetryData telemetry = frame.telemetry!;
    final CarDamageData? damage = frame.damage;

    return GridView.builder(
      itemCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemBuilder: (BuildContext context, int index) {
        final double wear = (damage?.tyresWear[index] ?? 0) / 100;
        final double temp = (telemetry.tyresSurfaceTemperature[index] / 120).clamp(0.0, 1.0);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF10131A),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(_labels[index], style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                Text('Surface ${telemetry.tyresSurfaceTemperature[index]}°C'),
                const SizedBox(height: 10),
                TelemetryBar(label: 'TEMP', value: temp, color: const Color(0xFFFF7043), showPercent: false),
                const SizedBox(height: 12),
                Text('Wear ${(wear * 100).toStringAsFixed(1)}%'),
                const SizedBox(height: 10),
                TelemetryBar(label: 'WEAR', value: wear, color: const Color(0xFFFFCA28), showPercent: false),
              ],
            ),
          ),
        );
      },
    );
  }
}
