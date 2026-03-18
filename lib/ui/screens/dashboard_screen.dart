import 'package:flutter/material.dart';

import '../../state/dashboard_state.dart';
import '../../state/telemetry_state.dart';
import '../widgets/dashboards/damage_dashboard.dart';
import '../widgets/dashboards/ers_dashboard.dart';
import '../widgets/dashboards/main_dashboard.dart';
import '../widgets/dashboards/tyres_dashboard.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.telemetryState,
    required this.dashboardState,
  });

  final TelemetryState telemetryState;
  final DashboardState dashboardState;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final TextEditingController _portController;

  @override
  void initState() {
    super.initState();
    _portController = TextEditingController(text: widget.telemetryState.configuredPort.toString());
  }

  @override
  void dispose() {
    _portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('F1 2025 Telemetry'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[widget.telemetryState, widget.dashboardState]),
          builder: (BuildContext context, Widget? child) {
            final DashboardType dashboard = widget.dashboardState.value;
            final telemetry = widget.telemetryState.current.telemetry;
            final status = widget.telemetryState.current.status;
            final damage = widget.telemetryState.current.damage;
            final bool hasMinimumData = telemetry != null;

            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _DebugOverlay(
                    telemetryState: widget.telemetryState,
                    dashboardType: dashboard,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: !hasMinimumData
                          ? const _WaitingForTelemetry()
                          : _buildDashboard(
                              dashboard,
                              telemetryAvailable: telemetry != null,
                              statusAvailable: status != null,
                              damageAvailable: damage != null,
                            ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDashboard(
    DashboardType dashboard, {
    required bool telemetryAvailable,
    required bool statusAvailable,
    required bool damageAvailable,
  }) {
    final frame = widget.telemetryState.current;
    switch (dashboard) {
      case DashboardType.tyres:
        return TyresDashboardWidget(key: const ValueKey<String>('tyres'), frame: frame);
      case DashboardType.ers:
        return statusAvailable
            ? ERSDashboardWidget(key: const ValueKey<String>('ers'), frame: frame)
            : MainDashboardWidget(key: const ValueKey<String>('main-fallback-ers'), frame: frame);
      case DashboardType.damage:
      case DashboardType.pits:
        return damageAvailable
            ? DamageDashboardWidget(key: ValueKey<String>(dashboard.name), frame: frame)
            : MainDashboardWidget(key: const ValueKey<String>('main-fallback-damage'), frame: frame);
      case DashboardType.main:
        return MainDashboardWidget(key: const ValueKey<String>('main'), frame: frame);
    }
  }

  Future<void> _openSettings() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF11131A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Connection Settings', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: _portController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'UDP Port',
                  hintText: '20777',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final int? port = int.tryParse(_portController.text.trim());
                  if (port != null) {
                    await widget.telemetryState.setPort(port);
                  }
                  if (mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: const Text('Apply'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WaitingForTelemetry extends StatelessWidget {
  const _WaitingForTelemetry();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Waiting for telemetry packets...'),
        ],
      ),
    );
  }
}

class _DebugOverlay extends StatelessWidget {
  const _DebugOverlay({required this.telemetryState, required this.dashboardType});

  final TelemetryState telemetryState;
  final DashboardType dashboardType;

  @override
  Widget build(BuildContext context) {
    final frame = telemetryState.current;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF10131A),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          children: <Widget>[
            _Chip(label: 'Dash', value: dashboardType.name.toUpperCase()),
            _Chip(label: 'Port', value: '${telemetryState.configuredPort}'),
            _Chip(label: 'Packets/s', value: frame.packetRate.toStringAsFixed(1)),
            _Chip(label: 'FPS', value: telemetryState.fpsEstimate.toStringAsFixed(1)),
            _Chip(label: 'Source', value: telemetryState.simulationEnabled ? 'SIM' : frame.source),
            _Chip(label: 'Pit', value: telemetryState.isInPit() ? 'YES' : 'NO'),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.labelLarge,
        children: <InlineSpan>[
          TextSpan(text: '$label: ', style: const TextStyle(color: Colors.white54)),
          TextSpan(text: value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
