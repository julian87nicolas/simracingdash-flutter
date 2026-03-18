import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

class UdpPacket {
  const UdpPacket({
    required this.bytes,
    required this.receivedAt,
    required this.source,
  });

  final Uint8List bytes;
  final DateTime receivedAt;
  final InternetAddress source;
}

class UdpListener {
  UdpListener({int defaultPort = 20777}) : _port = defaultPort;

  final StreamController<UdpPacket> _controller =
      StreamController<UdpPacket>.broadcast();
  RawDatagramSocket? _socket;
  int _port;
  Timer? _simulationTimer;
  int _frameCounter = 0;
  bool _simulationEnabled = false;

  Stream<UdpPacket> get packets => _controller.stream;
  int get port => _port;
  bool get simulationEnabled => _simulationEnabled;

  Future<void> start({int? port}) async {
    _port = port ?? _port;
    await stop();
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, _port);
      _socket!
        ..readEventsEnabled = true
        ..listen(_onSocketEvent, onError: _controller.addError, onDone: stop);
      _simulationEnabled = false;
    } on SocketException {
      _startSimulation();
    }
  }

  Future<void> restart(int port) => start(port: port);

  void _onSocketEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read || _socket == null) {
      return;
    }

    Datagram? datagram;
    while ((datagram = _socket!.receive()) != null) {
      _controller.add(
        UdpPacket(
          bytes: datagram!.data,
          receivedAt: DateTime.now(),
          source: datagram.address,
        ),
      );
    }
  }

  void _startSimulation() {
    _simulationEnabled = true;
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      _frameCounter++;
      final double t = _frameCounter / 30.0;
      for (final Uint8List packet in _buildSimulationPackets(t)) {
        _controller.add(
          UdpPacket(
            bytes: packet,
            receivedAt: DateTime.now(),
            source: InternetAddress.loopbackIPv4,
          ),
        );
      }
    });
  }

  List<Uint8List> _buildSimulationPackets(double t) {
    return <Uint8List>[
      _carTelemetryPacket(t),
      _carStatusPacket(t),
      _lapPacket(t),
      _damagePacket(t),
    ];
  }

  Uint8List _header(int packetId) {
    final ByteData data = ByteData(29);
    data.setUint16(0, 2025, Endian.little);
    data.setUint8(5, 1);
    data.setUint8(6, packetId);
    data.setFloat32(7, _frameCounter / 30.0, Endian.little);
    data.setUint32(11, _frameCounter, Endian.little);
    data.setUint8(21, 0);
    return data.buffer.asUint8List();
  }

  Uint8List _carTelemetryPacket(double t) {
    const int headerSize = 29;
    const int carCount = 22;
    const int blockSize = 60;
    final ByteData data = ByteData(headerSize + (carCount * blockSize) + 3);
    data.buffer.asUint8List().setAll(0, _header(6));
    final int speed = 250 + (math.sin(t) * 70).round();
    final double throttle = (0.6 + (math.sin(t * 1.8) * 0.35)).clamp(0.0, 1.0);
    final double brake = (0.3 + (math.cos(t * 1.1) * 0.3)).clamp(0.0, 1.0);
    final int gear = ((t ~/ 1) % 8) - 1;
    final int rpm = 9000 + ((math.sin(t * 2.2) + 1) * 3000).round();
    final int base = headerSize;
    data.setUint16(base, speed, Endian.little);
    data.setFloat32(base + 2, throttle, Endian.little);
    data.setFloat32(base + 6, math.sin(t) * 0.15, Endian.little);
    data.setFloat32(base + 10, brake, Endian.little);
    data.setUint8(base + 14, 0);
    data.setInt8(base + 15, gear);
    for (int i = 0; i < 4; i++) {
      data.setUint16(base + 16 + (i * 2), 620 + (i * 6) + (math.sin(t + i) * 12).round(), Endian.little);
      data.setUint8(base + 24 + i, 90 + (math.sin(t + i) * 8).round());
      data.setUint8(base + 28 + i, 82 + (math.cos(t + i) * 6).round());
      data.setFloat32(base + 32 + (i * 4), 22.0 + (i * 0.1), Endian.little);
      data.setUint8(base + 48 + i, 0);
    }
    data.setUint16(base + 52, rpm, Endian.little);
    data.setUint8(base + 54, (t % 6) > 3.5 ? 1 : 0);
    data.setUint8(base + 55, ((rpm / 15000) * 100).round().clamp(0, 100));
    final int extensionBase = headerSize + (carCount * blockSize);
    data.setUint8(extensionBase, ((t ~/ 6) % 5).toInt());
    data.setUint8(extensionBase + 1, 0);
    data.setInt8(extensionBase + 2, (gear + 1).clamp(1, 8));
    return data.buffer.asUint8List();
  }

  Uint8List _carStatusPacket(double t) {
    const int headerSize = 29;
    const int carCount = 22;
    const int blockSize = 44;
    final ByteData data = ByteData(headerSize + (carCount * blockSize));
    data.buffer.asUint8List().setAll(0, _header(7));
    final int base = headerSize;
    data.setFloat32(base + 2, 31.5 - ((_frameCounter % 500) / 100), Endian.little);
    data.setFloat32(base + 6, 14.2, Endian.little);
    data.setUint8(base + 11, 56);
    data.setFloat32(base + 24, 1_200_000 + (math.sin(t * 0.4) * 750_000), Endian.little);
    data.setUint8(base + 28, ((t ~/ 5) % 4).toInt());
    data.setFloat32(base + 29, 21000 + (math.sin(t) * 1000), Endian.little);
    data.setFloat32(base + 33, 12000 + (math.cos(t) * 800), Endian.little);
    data.setFloat32(base + 37, 25000 + (math.sin(t * 0.5) * 3000), Endian.little);
    return data.buffer.asUint8List();
  }

  Uint8List _lapPacket(double t) {
    const int headerSize = 29;
    const int carCount = 22;
    const int blockSize = 57;
    final ByteData data = ByteData(headerSize + (carCount * blockSize));
    data.buffer.asUint8List().setAll(0, _header(2));
    final int base = headerSize;
    data.setUint32(base, 92 * 1000 + (_frameCounter % 1000), Endian.little);
    data.setUint32(base + 4, ((_frameCounter * 33) % 93_000), Endian.little);
    data.setUint16(base + 8, 31 * 1000, Endian.little);
    data.setUint16(base + 10, 29 * 1000, Endian.little);
    data.setFloat32(base + 12, ((t * 120) % 5300), Endian.little);
    data.setFloat32(base + 16, t * 120, Endian.little);
    data.setUint8(base + 20, 4);
    data.setUint8(base + 21, ((t ~/ 18) % 2).toInt());
    data.setUint8(base + 22, 0);
    return data.buffer.asUint8List();
  }

  Uint8List _damagePacket(double t) {
    const int headerSize = 29;
    const int carCount = 22;
    const int blockSize = 42;
    final ByteData data = ByteData(headerSize + (carCount * blockSize));
    data.buffer.asUint8List().setAll(0, _header(10));
    final int base = headerSize;
    for (int i = 0; i < 4; i++) {
      data.setFloat32(base + (i * 4), 8 + i * 3 + (math.sin(t + i) * 2), Endian.little);
    }
    data.setUint8(base + 16, 4);
    data.setUint8(base + 17, 6);
    data.setUint8(base + 18, 2);
    data.setUint8(base + 19, 7);
    data.setUint8(base + 20, 3);
    data.setUint8(base + 21, 9);
    data.setUint8(base + 22, 4);
    data.setUint8(base + 23, 5);
    data.setUint8(base + 24, 8);
    data.setUint8(base + 25, 6);
    data.setUint8(base + 26, 7);
    return data.buffer.asUint8List();
  }

  Future<void> stop() async {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    _socket?.close();
    _socket = null;
  }

  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}
