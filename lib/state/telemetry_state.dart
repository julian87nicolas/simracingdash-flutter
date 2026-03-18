import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../core/telemetry/telemetry_models.dart';
import '../core/telemetry/telemetry_parser.dart';
import '../core/udp/udp_listener.dart';

class TelemetryState extends ChangeNotifier {
  TelemetryState({
    UdpListener? udpListener,
    TelemetryParser? parser,
  })  : _udpListener = udpListener ?? UdpListener(),
        _parser = parser ?? TelemetryParser();

  final UdpListener _udpListener;
  final TelemetryParser _parser;
  StreamSubscription<UdpPacket>? _packetSubscription;

  TelemetrySnapshot _snapshot = TelemetrySnapshot(
    current: TelemetryFrame.empty(),
    previous: TelemetryFrame.empty(),
  );
  int _configuredPort = 20777;
  int _packetsThisSecond = 0;
  DateTime _lastRateTick = DateTime.now();
  double _fpsEstimate = 0;

  TelemetrySnapshot get snapshot => _snapshot;
  TelemetryFrame get current => _snapshot.current;
  TelemetryFrame get previous => _snapshot.previous;
  int get configuredPort => _configuredPort;
  double get fpsEstimate => _fpsEstimate;
  bool get simulationEnabled => _udpListener.simulationEnabled;

  Future<void> start() async {
    await _udpListener.start(port: _configuredPort);
    _packetSubscription?.cancel();
    _packetSubscription = _udpListener.packets.listen(_handlePacket);
  }

  Future<void> setPort(int port) async {
    _configuredPort = port;
    await _udpListener.restart(port);
    notifyListeners();
  }

  bool hasMFDChanged() {
    return current.telemetry?.mfdPanelIndex != previous.telemetry?.mfdPanelIndex;
  }

  bool isInPit() => current.lapData?.isInPit ?? false;

  bool hasERSChanged() {
    return current.status?.ersDeployMode != previous.status?.ersDeployMode ||
        current.status?.ersStoreEnergy != previous.status?.ersStoreEnergy;
  }

  void _handlePacket(UdpPacket packet) {
    final ParsedPacket? parsed = _parser.parse(packet.bytes);
    if (parsed == null) {
      return;
    }

    _packetsThisSecond++;
    final DateTime now = packet.receivedAt;
    final Duration delta = now.difference(_lastRateTick);
    double packetRate = current.packetRate;
    if (delta.inMilliseconds >= 1000) {
      packetRate = (_packetsThisSecond * 1000) / delta.inMilliseconds;
      _fpsEstimate = packetRate;
      _packetsThisSecond = 0;
      _lastRateTick = now;
    }

    TelemetryFrame next = current.merge(
      header: parsed.header,
      packetRate: packetRate,
      timestamp: now,
      source: packet.source.address,
    );

    if (parsed.telemetry != null) {
      final CarTelemetryData previousTelemetry = current.telemetry ?? parsed.telemetry!;
      next = next.merge(
        telemetry: _smoothTelemetry(previousTelemetry, parsed.telemetry!),
      );
    }
    if (parsed.status != null) {
      next = next.merge(status: parsed.status);
    }
    if (parsed.lapData != null) {
      next = next.merge(lapData: parsed.lapData);
    }
    if (parsed.damage != null) {
      next = next.merge(damage: parsed.damage);
    }

    _snapshot = TelemetrySnapshot(current: next, previous: current);
    notifyListeners();
  }

  CarTelemetryData _smoothTelemetry(
    CarTelemetryData previous,
    CarTelemetryData incoming,
  ) {
    double lerp(double a, double b, [double t = 0.35]) => a + (b - a) * t;

    return CarTelemetryData(
      speed: lerp(previous.speed.toDouble(), incoming.speed.toDouble(), 0.4).round(),
      throttle: lerp(previous.throttle, incoming.throttle),
      steer: lerp(previous.steer, incoming.steer),
      brake: lerp(previous.brake, incoming.brake),
      clutch: incoming.clutch,
      gear: incoming.gear,
      engineRpm: lerp(previous.engineRpm.toDouble(), incoming.engineRpm.toDouble(), 0.4).round(),
      drs: incoming.drs,
      revLightsPercent: incoming.revLightsPercent,
      brakesTemperature: List<int>.generate(
        4,
        (index) => lerp(
          previous.brakesTemperature[index].toDouble(),
          incoming.brakesTemperature[index].toDouble(),
          0.25,
        ).round(),
        growable: false,
      ),
      tyresSurfaceTemperature: List<int>.generate(
        4,
        (index) => lerp(
          previous.tyresSurfaceTemperature[index].toDouble(),
          incoming.tyresSurfaceTemperature[index].toDouble(),
          0.3,
        ).round(),
        growable: false,
      ),
      tyresInnerTemperature: List<int>.generate(
        4,
        (index) => lerp(
          previous.tyresInnerTemperature[index].toDouble(),
          incoming.tyresInnerTemperature[index].toDouble(),
          0.3,
        ).round(),
        growable: false,
      ),
      tyresPressure: List<double>.generate(
        4,
        (index) => lerp(previous.tyresPressure[index], incoming.tyresPressure[index], 0.2),
        growable: false,
      ),
      surfaceType: incoming.surfaceType,
      mfdPanelIndex: incoming.mfdPanelIndex,
      mfdPanelSecondaryIndex: incoming.mfdPanelSecondaryIndex,
      suggestedGear: incoming.suggestedGear,
    );
  }

  String formatLapTime(int milliseconds) {
    if (milliseconds <= 0) {
      return '--:--.---';
    }
    final int minutes = milliseconds ~/ 60000;
    final int seconds = (milliseconds % 60000) ~/ 1000;
    final int millis = milliseconds % 1000;
    return '$minutes:${seconds.toString().padLeft(2, '0')}.${millis.toString().padLeft(3, '0')}';
  }

  double tyreWearAverage() {
    final List<double> wear = current.damage?.tyresWear ?? const <double>[0, 0, 0, 0];
    return wear.reduce((double a, double b) => a + b) / math.max(1, wear.length);
  }

  Future<void> shutdown() async {
    await _packetSubscription?.cancel();
    _packetSubscription = null;
    await _udpListener.dispose();
  }

  @override
  void dispose() {
    _packetSubscription?.cancel();
    _udpListener.dispose();
    super.dispose();
  }
}

