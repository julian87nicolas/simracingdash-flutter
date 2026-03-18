import 'dart:math' as math;

enum F1PacketType {
  motion(0),
  session(1),
  lapData(2),
  event(3),
  participants(4),
  carSetups(5),
  carTelemetry(6),
  carStatus(7),
  finalClassification(8),
  lobbyInfo(9),
  carDamage(10),
  sessionHistory(11),
  tyreSets(12),
  motionEx(13),
  timeTrial(14),
  unknown(-1);

  const F1PacketType(this.id);
  final int id;

  static F1PacketType fromId(int id) {
    return F1PacketType.values.firstWhere(
      (value) => value.id == id,
      orElse: () => F1PacketType.unknown,
    );
  }
}

class PacketHeader {
  const PacketHeader({
    required this.packetFormat,
    required this.packetVersion,
    required this.packetId,
    required this.sessionTime,
    required this.frameIdentifier,
    required this.playerCarIndex,
  });

  final int packetFormat;
  final int packetVersion;
  final F1PacketType packetId;
  final double sessionTime;
  final int frameIdentifier;
  final int playerCarIndex;
}

class CarTelemetryData {
  const CarTelemetryData({
    required this.speed,
    required this.throttle,
    required this.steer,
    required this.brake,
    required this.clutch,
    required this.gear,
    required this.engineRpm,
    required this.drs,
    required this.revLightsPercent,
    required this.brakesTemperature,
    required this.tyresSurfaceTemperature,
    required this.tyresInnerTemperature,
    required this.tyresPressure,
    required this.surfaceType,
    required this.mfdPanelIndex,
    required this.mfdPanelSecondaryIndex,
    required this.suggestedGear,
  });

  final int speed;
  final double throttle;
  final double steer;
  final double brake;
  final int clutch;
  final int gear;
  final int engineRpm;
  final bool drs;
  final int revLightsPercent;
  final List<int> brakesTemperature;
  final List<int> tyresSurfaceTemperature;
  final List<int> tyresInnerTemperature;
  final List<double> tyresPressure;
  final List<int> surfaceType;
  final int mfdPanelIndex;
  final int mfdPanelSecondaryIndex;
  final int suggestedGear;
}

class CarStatusData {
  const CarStatusData({
    required this.fuelInTank,
    required this.fuelRemainingLaps,
    required this.brakeBias,
    required this.ersStoreEnergy,
    required this.ersDeployMode,
    required this.ersHarvestedThisLapMGUK,
    required this.ersHarvestedThisLapMGUH,
    required this.ersDeployedThisLap,
  });

  final double fuelInTank;
  final double fuelRemainingLaps;
  final int brakeBias;
  final double ersStoreEnergy;
  final int ersDeployMode;
  final double ersHarvestedThisLapMGUK;
  final double ersHarvestedThisLapMGUH;
  final double ersDeployedThisLap;

  double get ersFraction => (ersStoreEnergy / 4_000_000.0).clamp(0.0, 1.0);
}

class LapData {
  const LapData({
    required this.lastLapTimeMs,
    required this.currentLapTimeMs,
    required this.sector1TimeMs,
    required this.sector2TimeMs,
    required this.lapDistance,
    required this.totalDistance,
    required this.position,
    required this.pitStatus,
    required this.currentLapInvalid,
  });

  final int lastLapTimeMs;
  final int currentLapTimeMs;
  final int sector1TimeMs;
  final int sector2TimeMs;
  final double lapDistance;
  final double totalDistance;
  final int position;
  final int pitStatus;
  final bool currentLapInvalid;

  bool get isInPit => pitStatus != 0;
}

class CarDamageData {
  const CarDamageData({
    required this.tyresWear,
    required this.frontLeftWingDamage,
    required this.frontRightWingDamage,
    required this.rearWingDamage,
    required this.engineDamage,
    required this.gearBoxDamage,
    required this.engineMGUHWear,
    required this.engineESWear,
    required this.engineCEWear,
    required this.engineICEWear,
    required this.engineMGUKWear,
    required this.engineTCWear,
  });

  final List<double> tyresWear;
  final int frontLeftWingDamage;
  final int frontRightWingDamage;
  final int rearWingDamage;
  final int engineDamage;
  final int gearBoxDamage;
  final int engineMGUHWear;
  final int engineESWear;
  final int engineCEWear;
  final int engineICEWear;
  final int engineMGUKWear;
  final int engineTCWear;

  int get averageTyreWear => tyresWear.isEmpty
      ? 0
      : tyresWear.reduce((a, b) => a + b) ~/ math.max(1, tyresWear.length);
}

class TelemetryFrame {
  const TelemetryFrame({
    required this.header,
    this.telemetry,
    this.status,
    this.lapData,
    this.damage,
    required this.packetRate,
    required this.timestamp,
    required this.source,
  });

  final PacketHeader header;
  final CarTelemetryData? telemetry;
  final CarStatusData? status;
  final LapData? lapData;
  final CarDamageData? damage;
  final double packetRate;
  final DateTime timestamp;
  final String source;

  static TelemetryFrame empty() {
    return TelemetryFrame(
      header: const PacketHeader(
        packetFormat: 2025,
        packetVersion: 1,
        packetId: F1PacketType.unknown,
        sessionTime: 0,
        frameIdentifier: 0,
        playerCarIndex: 0,
      ),
      packetRate: 0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(0),
      source: 'simulation',
    );
  }

  TelemetryFrame merge({
    PacketHeader? header,
    CarTelemetryData? telemetry,
    CarStatusData? status,
    LapData? lapData,
    CarDamageData? damage,
    double? packetRate,
    DateTime? timestamp,
    String? source,
  }) {
    return TelemetryFrame(
      header: header ?? this.header,
      telemetry: telemetry ?? this.telemetry,
      status: status ?? this.status,
      lapData: lapData ?? this.lapData,
      damage: damage ?? this.damage,
      packetRate: packetRate ?? this.packetRate,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
    );
  }
}

class TelemetrySnapshot {
  const TelemetrySnapshot({required this.current, required this.previous});

  final TelemetryFrame current;
  final TelemetryFrame previous;
}
