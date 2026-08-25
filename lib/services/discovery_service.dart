import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../models/device_models.dart';

class DiscoveredPC {
  final String id;
  final String name;
  final String ip;
  final int port;
  final DeviceType type;
  final DateTime discoveredAt;

  DiscoveredPC({
    required this.id,
    required this.name,
    required this.ip,
    required this.port,
    required this.type,
    DateTime? discoveredAt,
  }) : discoveredAt = discoveredAt ?? DateTime.now();

  PairedDevice toPairedDevice() {
    return PairedDevice(
      id: id,
      name: name,
      ip: ip,
      port: port,
      type: type,
      lastConnected: DateTime.now(),
    );
  }
}

class DiscoveryService {
  static const int discoveryPort = 8766;
  static const int defaultServerPort = 8765;

  RawDatagramSocket? _socket;
  final _discoveredController = StreamController<List<DiscoveredPC>>.broadcast();
  final Map<String, DiscoveredPC> _found = {};
  bool _isScanning = false;
  Timer? _broadcastTimer;

  Stream<List<DiscoveredPC>> get discoveredPCsStream => _discoveredController.stream;
  bool get isScanning => _isScanning;

  Future<void> startDiscovery() async {
    if (_isScanning) return;
    _isScanning = true;
    _found.clear();
    _discoveredController.add([]);

    try {
      _socket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
        reuseAddress: true,
      );
      _socket?.broadcastEnabled = true;

      _socket?.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _socket?.receive();
          if (datagram != null) {
            _handleDatagram(datagram);
          }
        }
      });

      // Send initial discovery packet
      _sendDiscoveryPing();

      // Repeat broadcast every 2 seconds for 10 seconds
      _broadcastTimer = Timer.periodic(const Duration(seconds: 2), (t) {
        _sendDiscoveryPing();
        if (t.tick >= 5) {
          stopDiscovery();
        }
      });
    } catch (_) {
      // Fallback: If UDP bind fails, we still allow manual or direct scanning
    }
  }

  void _sendDiscoveryPing() {
    try {
      final msg = utf8.encode(json.encode({
        'type': 'pcremote_discover',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }));
      _socket?.send(
        msg,
        InternetAddress('255.255.255.255'),
        discoveryPort,
      );
    } catch (_) {}
  }

  void _handleDatagram(Datagram datagram) {
    try {
      final text = utf8.decode(datagram.data);
      final jsonMap = json.decode(text) as Map<String, dynamic>;
      if (jsonMap['type'] == 'pcremote_beacon' || jsonMap['service'] == 'pcremote') {
        final id = jsonMap['id'] as String? ?? datagram.address.address;
        final name = jsonMap['name'] as String? ?? 'Windows PC';
        final port = (jsonMap['port'] as num?)?.toInt() ?? defaultServerPort;
        final deviceTypeStr = jsonMap['deviceType'] as String? ?? 'desktop';
        final devType = deviceTypeStr == 'laptop' ? DeviceType.laptop : DeviceType.desktop;

        final pc = DiscoveredPC(
          id: id,
          name: name,
          ip: datagram.address.address,
          port: port,
          type: devType,
        );

        _found[id] = pc;
        _discoveredController.add(_found.values.toList());
      }
    } catch (_) {}
  }

  void stopDiscovery() {
    _isScanning = false;
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    _socket?.close();
    _socket = null;
  }

  void dispose() {
    stopDiscovery();
    _discoveredController.close();
  }
}
