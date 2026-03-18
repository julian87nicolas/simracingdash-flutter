import 'package:flutter/material.dart';

class RpmBar extends StatelessWidget {
  const RpmBar({super.key, required this.rpmFraction});

  final double rpmFraction;

  @override
  Widget build(BuildContext context) {
    final double clamped = rpmFraction.clamp(0.0, 1.0);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const int segmentCount = 20;
        final double spacing = 4;
        final double width = (constraints.maxWidth - ((segmentCount - 1) * spacing)) / segmentCount;

        return Row(
          children: List<Widget>.generate(segmentCount, (int index) {
            final double threshold = (index + 1) / segmentCount;
            final bool active = clamped >= threshold;
            final Color color = index > 15
                ? Colors.redAccent
                : index > 11
                    ? Colors.amberAccent
                    : const Color(0xFF00E676);
            return Container(
              width: width,
              height: 18,
              margin: EdgeInsets.only(right: index == segmentCount - 1 ? 0 : spacing),
              decoration: BoxDecoration(
                color: active ? color : const Color(0xFF1B1E27),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }
}
