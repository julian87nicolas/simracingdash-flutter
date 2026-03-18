import 'package:flutter/material.dart';

class TelemetryBar extends StatelessWidget {
  const TelemetryBar({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.backgroundColor = const Color(0xFF1B1E27),
    this.height = 16,
    this.showPercent = true,
  });

  final String label;
  final double value;
  final Color color;
  final Color backgroundColor;
  final double height;
  final bool showPercent;

  @override
  Widget build(BuildContext context) {
    final double clamped = value.clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(label, style: Theme.of(context).textTheme.labelLarge),
            const Spacer(),
            if (showPercent)
              Text('${(clamped * 100).round()}%', style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ColoredBox(color: backgroundColor),
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: clamped,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: <Color>[color.withValues(alpha: 0.7), color],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
