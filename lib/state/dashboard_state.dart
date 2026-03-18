import 'package:flutter/foundation.dart';

import '../core/telemetry/telemetry_models.dart';
import 'telemetry_state.dart';

enum DashboardType { main, tyres, ers, damage, pits }

class DashboardState extends ValueNotifier<DashboardType> {
  DashboardState(this._telemetryState) : super(DashboardType.main) {
    _telemetryState.addListener(_handleTelemetryUpdate);
  }

  final TelemetryState _telemetryState;

  void _handleTelemetryUpdate() {
    final TelemetryFrame frame = _telemetryState.current;
    final DashboardType next = _resolveDashboard(frame);
    if (next != value) {
      value = next;
    }
  }

  DashboardType _resolveDashboard(TelemetryFrame frame) {
    final bool pitStatus = frame.lapData?.isInPit ?? false;
    if (pitStatus) {
      return DashboardType.pits;
    }

    final CarDamageData? damage = frame.damage;
    final bool criticalDamage = damage != null &&
        (damage.engineDamage >= 40 ||
            damage.frontLeftWingDamage >= 35 ||
            damage.frontRightWingDamage >= 35);
    if (criticalDamage) {
      return DashboardType.damage;
    }

    switch (frame.telemetry?.mfdPanelIndex ?? 255) {
      case 1:
        return DashboardType.tyres;
      case 2:
        return DashboardType.ers;
      case 3:
        return DashboardType.damage;
      case 4:
        return DashboardType.pits;
      default:
        return DashboardType.main;
    }
  }

  @override
  void dispose() {
    _telemetryState.removeListener(_handleTelemetryUpdate);
    super.dispose();
  }
}
