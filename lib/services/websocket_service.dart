import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/device_models.dart';
import '../models/system_models.dart';
import '../protocol/command_protocol.dart';

enum ConnectionStatus { offline, connecting, connected, error }

class WebSocketService {
  WebSocketChannel? _channel;
  PairedDevice? _activeDevice;
  ConnectionStatus _status = ConnectionStatus.offline;
  bool _autoReconnect = true;
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;

  final _statusController = StreamController<ConnectionStatus>.broadcast();
  final _systemInfoController = StreamController<HostSystemInfo>.broadcast();
  final _incomingMessagesController = StreamController<Map<String, dynamic>>.broadcast();
  final Map<String, Completer<ResponseMessage>> _pendingRequests = {};

  Stream<ConnectionStatus> get statusStream => _statusController.stream;
  Stream<HostSystemInfo> get systemInfoStream => _systemInfoController.stream;
  Stream<Map<String, dynamic>> get incomingMessagesStream => _incomingMessagesController.stream;

  ConnectionStatus get status => _status;
  PairedDevice? get activeDevice => _activeDevice;

  void setAutoReconnect(bool enable) {
    _autoReconnect = enable;
  }

  void _setStatus(ConnectionStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusController.add(_status);
    }
  }

  Future<bool> connect(PairedDevice device) async {
    _activeDevice = device;
    _reconnectAttempts = 0;
    return _doConnect();
  }

  Future<bool> _doConnect() async {
    if (_activeDevice == null) return false;

    _setStatus(ConnectionStatus.connecting);
    _cleanupChannel();

    final url = Uri.parse('ws://${_activeDevice!.ip}:${_activeDevice!.port}/ws');
    try {
      _channel = WebSocketChannel.connect(url);

      // Listen on channel stream
      _channel!.stream.listen(
        (message) {
          _handleIncomingMessage(message);
        },
        onDone: () {
          _handleDisconnect();
        },
        onError: (err) {
          _handleDisconnect();
        },
        cancelOnError: true,
      );

      // Request system status or authenticate if token is present
      _setStatus(ConnectionStatus.connected);
      _reconnectAttempts = 0;
      _startHeartbeat();

      // Send initial status request
      sendCommand(ProtocolActions.systemStatus);

      return true;
    } catch (e) {
      _handleDisconnect();
      return false;
    }
  }

  void _handleIncomingMessage(dynamic raw) {
    try {
      final text = raw is String ? raw : utf8.decode(raw as List<int>);
      final map = json.decode(text) as Map<String, dynamic>;

      _incomingMessagesController.add(map);

      // Check if it's a response to a pending request
      final id = map['id'] as String?;
      if (id != null && _pendingRequests.containsKey(id)) {
        final resp = ResponseMessage.fromMap(map);
        _pendingRequests.remove(id)!.complete(resp);
      }

      // Check if it's system telemetry
      if (map['action'] == ProtocolActions.systemStatus && map['data'] != null) {
        final info = HostSystemInfo.fromMap(map['data'] as Map<String, dynamic>);
        _systemInfoController.add(info);
      }
    } catch (_) {}
  }

  void _handleDisconnect() {
    _cleanupChannel();
    _setStatus(ConnectionStatus.offline);

    // Fail any pending requests
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.complete(ResponseMessage(
          id: '',
          action: 'error',
          success: false,
          error: 'Connection closed',
        ));
      }
    }
    _pendingRequests.clear();

    if (_autoReconnect && _activeDevice != null) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectAttempts++;
    final backoffSeconds = (_reconnectAttempts * 2).clamp(1, 10);
    _reconnectTimer = Timer(Duration(seconds: backoffSeconds), () {
      if (_status != ConnectionStatus.connected && _activeDevice != null) {
        _doConnect();
      }
    });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 4), (t) {
      if (_status == ConnectionStatus.connected) {
        sendCommand(ProtocolActions.systemStatus);
      }
    });
  }

  Future<ResponseMessage> sendCommand(
    String action, {
    Map<String, dynamic> params = const {},
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final cmdId = DateTime.now().microsecondsSinceEpoch.toString();
    final cmd = CommandMessage(
      id: cmdId,
      action: action,
      params: params,
      token: _activeDevice?.token,
    );

    if (_status != ConnectionStatus.connected || _channel == null) {
      return ResponseMessage(
        id: cmdId,
        action: action,
        success: false,
        error: 'PC is offline',
      );
    }

    final completer = Completer<ResponseMessage>();
    _pendingRequests[cmdId] = completer;

    try {
      _channel!.sink.add(cmd.toJson());
      return await completer.future.timeout(
        timeout,
        onTimeout: () {
          _pendingRequests.remove(cmdId);
          return ResponseMessage(
            id: cmdId,
            action: action,
            success: false,
            error: 'Request timeout',
          );
        },
      );
    } catch (e) {
      _pendingRequests.remove(cmdId);
      return ResponseMessage(
        id: cmdId,
        action: action,
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Fire and forget for low-latency streaming inputs (mouse, keyboard)
  void sendStreamMessage(String action, Map<String, dynamic> params) {
    if (_status != ConnectionStatus.connected || _channel == null) return;
    try {
      final cmd = CommandMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        action: action,
        params: params,
        token: _activeDevice?.token,
      );
      _channel!.sink.add(cmd.toJson());
    } catch (_) {}
  }

  void disconnect() {
    _autoReconnect = false;
    _reconnectTimer?.cancel();
    _cleanupChannel();
    _setStatus(ConnectionStatus.offline);
  }

  void _cleanupChannel() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }

  void dispose() {
    disconnect();
    _statusController.close();
    _systemInfoController.close();
    _incomingMessagesController.close();
  }
}
