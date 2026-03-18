import 'dart:typed_data';

import 'telemetry_models.dart';

class TelemetryParser {
  static const int _headerSize = 29;
  static const int _carCount = 22;
  static const Endian _endian = Endian.little;

  ParsedPacket? parse(Uint8List bytes) {
    if (bytes.lengthInBytes < _headerSize) {
      return null;
    }

    final ByteData data = ByteData.sublistView(bytes);
    final PacketHeader header = _parseHeader(data);
    switch (header.packetId) {
      case F1PacketType.carTelemetry:
        return ParsedPacket(
          header: header,
          telemetry: _parseCarTelemetry(data, header.playerCarIndex),
        );
      case F1PacketType.carStatus:
        return ParsedPacket(
          header: header,
          status: _parseCarStatus(data, header.playerCarIndex),
        );
      case F1PacketType.lapData:
        return ParsedPacket(
          header: header,
          lapData: _parseLapData(data, header.playerCarIndex),
        );
      case F1PacketType.carDamage:
        return ParsedPacket(
          header: header,
          damage: _parseCarDamage(data, header.playerCarIndex),
        );
      default:
        return ParsedPacket(header: header);
    }
  }

  PacketHeader _parseHeader(ByteData data) {
    return PacketHeader(
      packetFormat: data.getUint16(0, _endian),
      packetVersion: data.getUint8(5),
      packetId: F1PacketType.fromId(data.getUint8(6)),
      sessionTime: data.getFloat32(7, _endian),
      frameIdentifier: data.getUint32(11, _endian),
      playerCarIndex: data.getUint8(21),
    );
  }

  CarTelemetryData _parseCarTelemetry(ByteData data, int playerIndex) {
    const int blockSize = 60;
    final int base = _headerSize + (playerIndex.clamp(0, _carCount - 1) * blockSize);

    final List<int> brakesTemperature = List<int>.generate(
      4,
      (index) => data.getUint16(base + 16 + (index * 2), _endian),
      growable: false,
    );
    final List<int> tyresSurfaceTemperature = List<int>.generate(
      4,
      (index) => data.getUint8(base + 24 + index),
      growable: false,
    );
    final List<int> tyresInnerTemperature = List<int>.generate(
      4,
      (index) => data.getUint8(base + 28 + index),
      growable: false,
    );
    final List<double> tyresPressure = List<double>.generate(
      4,
      (index) => data.getFloat32(base + 32 + (index * 4), _endian),
      growable: false,
    );
    final List<int> surfaceType = List<int>.generate(
      4,
      (index) => data.getUint8(base + 48 + index),
      growable: false,
    );

    final int extensionBase = _headerSize + (_carCount * blockSize);
    return CarTelemetryData(
      speed: data.getUint16(base, _endian),
      throttle: data.getFloat32(base + 2, _endian),
      steer: data.getFloat32(base + 6, _endian),
      brake: data.getFloat32(base + 10, _endian),
      clutch: data.getUint8(base + 14),
      gear: data.getInt8(base + 15),
      engineRpm: data.getUint16(base + 52, _endian),
      drs: data.getUint8(base + 54) == 1,
      revLightsPercent: data.getUint8(base + 55),
      brakesTemperature: brakesTemperature,
      tyresSurfaceTemperature: tyresSurfaceTemperature,
      tyresInnerTemperature: tyresInnerTemperature,
      tyresPressure: tyresPressure,
      surfaceType: surfaceType,
      mfdPanelIndex: data.getUint8(extensionBase),
      mfdPanelSecondaryIndex: data.getUint8(extensionBase + 1),
      suggestedGear: data.getInt8(extensionBase + 2),
    );
  }

  CarStatusData _parseCarStatus(ByteData data, int playerIndex) {
    const int blockSize = 44;
    final int base = _headerSize + (playerIndex.clamp(0, _carCount - 1) * blockSize);
    return CarStatusData(
      fuelInTank: data.getFloat32(base + 2, _endian),
      fuelRemainingLaps: data.getFloat32(base + 6, _endian),
      brakeBias: data.getUint8(base + 11),
      ersStoreEnergy: data.getFloat32(base + 24, _endian),
      ersDeployMode: data.getUint8(base + 28),
      ersHarvestedThisLapMGUK: data.getFloat32(base + 29, _endian),
      ersHarvestedThisLapMGUH: data.getFloat32(base + 33, _endian),
      ersDeployedThisLap: data.getFloat32(base + 37, _endian),
    );
  }

  LapData _parseLapData(ByteData data, int playerIndex) {
    const int blockSize = 57;
    final int base = _headerSize + (playerIndex.clamp(0, _carCount - 1) * blockSize);
    return LapData(
      lastLapTimeMs: data.getUint32(base, _endian),
      currentLapTimeMs: data.getUint32(base + 4, _endian),
      sector1TimeMs: data.getUint16(base + 8, _endian),
      sector2TimeMs: data.getUint16(base + 10, _endian),
      lapDistance: data.getFloat32(base + 12, _endian),
      totalDistance: data.getFloat32(base + 16, _endian),
      position: data.getUint8(base + 20),
      pitStatus: data.getUint8(base + 21),
      currentLapInvalid: data.getUint8(base + 22) == 1,
    );
  }

  CarDamageData _parseCarDamage(ByteData data, int playerIndex) {
    const int blockSize = 42;
    final int base = _headerSize + (playerIndex.clamp(0, _carCount - 1) * blockSize);
    return CarDamageData(
      tyresWear: List<double>.generate(
        4,
        (index) => data.getFloat32(base + (index * 4), _endian),
        growable: false,
      ),
      frontLeftWingDamage: data.getUint8(base + 16),
      frontRightWingDamage: data.getUint8(base + 17),
      rearWingDamage: data.getUint8(base + 18),
      engineDamage: data.getUint8(base + 19),
      gearBoxDamage: data.getUint8(base + 20),
      engineMGUHWear: data.getUint8(base + 21),
      engineESWear: data.getUint8(base + 22),
      engineCEWear: data.getUint8(base + 23),
      engineICEWear: data.getUint8(base + 24),
      engineMGUKWear: data.getUint8(base + 25),
      engineTCWear: data.getUint8(base + 26),
    );
  }
}

class ParsedPacket {
  const ParsedPacket({
    required this.header,
    this.telemetry,
    this.status,
    this.lapData,
    this.damage,
  });

  final PacketHeader header;
  final CarTelemetryData? telemetry;
  final CarStatusData? status;
  final LapData? lapData;
  final CarDamageData? damage;
}
