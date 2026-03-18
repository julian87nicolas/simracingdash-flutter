import 'package:flutter/material.dart';

import 'state/dashboard_state.dart';
import 'state/telemetry_state.dart';
import 'ui/screens/dashboard_screen.dart';

class TelemetryDashboardApp extends StatefulWidget {
  const TelemetryDashboardApp({super.key});

  @override
  State<TelemetryDashboardApp> createState() => _TelemetryDashboardAppState();
}

class _TelemetryDashboardAppState extends State<TelemetryDashboardApp> {
  late final TelemetryState telemetryState;
  late final DashboardState dashboardState;

  @override
  void initState() {
    super.initState();
    telemetryState = TelemetryState();
    dashboardState = DashboardState(telemetryState);
    telemetryState.start();
  }

  @override
  void dispose() {
    dashboardState.dispose();
    telemetryState.shutdown();
    telemetryState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sim Racing Dash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF05060A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF1E00),
          secondary: Color(0xFF00E5FF),
          surface: Color(0xFF11131A),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontWeight: FontWeight.w700),
          displayMedium: TextStyle(fontWeight: FontWeight.w700),
          headlineMedium: TextStyle(fontWeight: FontWeight.w700),
          titleLarge: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      home: DashboardScreen(
        telemetryState: telemetryState,
        dashboardState: dashboardState,
      ),
    );
  }
}
