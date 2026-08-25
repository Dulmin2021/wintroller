import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import '../models/file_models.dart';
import '../models/system_models.dart';
import '../protocol/command_protocol.dart';
import 'websocket_service.dart';

class PCRemoteRepository {
  final WebSocketService _wsService;
  final _transferProgressController = StreamController<TransferProgress>.broadcast();

  PCRemoteRepository(this._wsService) {
    _wsService.incomingMessagesStream.listen((map) {
      if (map['action'] == 'files.progress' && map['data'] != null) {
        final d = map['data'] as Map<String, dynamic>;
        final progress = TransferProgress(
          id: d['id'] as String? ?? '',
          fileName: d['fileName'] as String? ?? '',
          direction: (d['direction'] == 'upload')
              ? TransferDirection.upload
              : TransferDirection.download,
          progress: (d['progress'] as num?)?.toDouble() ?? 0.0,
          transferredBytes: (d['transferredBytes'] as num?)?.toInt() ?? 0,
          totalBytes: (d['totalBytes'] as num?)?.toInt() ?? 0,
          isCompleted: d['isCompleted'] as bool? ?? false,
          error: d['error'] as String?,
        );
        _transferProgressController.add(progress);
      }
    });
  }

  Stream<ConnectionStatus> get connectionStatusStream => _wsService.statusStream;
  Stream<HostSystemInfo> get systemInfoStream => _wsService.systemInfoStream;
  Stream<TransferProgress> get transferProgressStream => _transferProgressController.stream;
  ConnectionStatus get currentStatus => _wsService.status;

  // Pairing
  Future<ResponseMessage> requestPin() async {
    return await _wsService.sendCommand(ProtocolActions.pairingRequestPin);
  }

  Future<ResponseMessage> verifyPin(String pin) async {
    return await _wsService.sendCommand(
      ProtocolActions.pairingVerify,
      params: {'pin': pin},
    );
  }

  Future<ResponseMessage> verifyQrToken(String token) async {
    return await _wsService.sendCommand(
      ProtocolActions.pairingVerify,
      params: {'token': token},
    );
  }

  // System Status
  Future<ResponseMessage> getSystemStatus() async {
    return await _wsService.sendCommand(ProtocolActions.systemStatus);
  }

  // Power Actions
  Future<ResponseMessage> shutdown() async =>
      await _wsService.sendCommand(ProtocolActions.powerShutdown);

  Future<ResponseMessage> restart() async =>
      await _wsService.sendCommand(ProtocolActions.powerRestart);

  Future<ResponseMessage> sleep() async =>
      await _wsService.sendCommand(ProtocolActions.powerSleep);

  Future<ResponseMessage> hibernate() async =>
      await _wsService.sendCommand(ProtocolActions.powerHibernate);

  Future<ResponseMessage> logoff() async =>
      await _wsService.sendCommand(ProtocolActions.powerLogoff);

  Future<ResponseMessage> lock() async =>
      await _wsService.sendCommand(ProtocolActions.powerLock);

  // Media Actions
  Future<ResponseMessage> mediaPlayPause() async =>
      await _wsService.sendCommand(ProtocolActions.mediaPlayPause);

  Future<ResponseMessage> mediaNext() async =>
      await _wsService.sendCommand(ProtocolActions.mediaNext);

  Future<ResponseMessage> mediaPrevious() async =>
      await _wsService.sendCommand(ProtocolActions.mediaPrevious);

  Future<ResponseMessage> mediaVolumeUp() async =>
      await _wsService.sendCommand(ProtocolActions.mediaVolumeUp);

  Future<ResponseMessage> mediaVolumeDown() async =>
      await _wsService.sendCommand(ProtocolActions.mediaVolumeDown);

  Future<ResponseMessage> mediaMute() async =>
      await _wsService.sendCommand(ProtocolActions.mediaMute);

  Future<ResponseMessage> mediaUnmute() async =>
      await _wsService.sendCommand(ProtocolActions.mediaUnmute);

  Future<ResponseMessage> mediaMicOn() async =>
      await _wsService.sendCommand(ProtocolActions.mediaMicOn);

  Future<ResponseMessage> mediaMicOff() async =>
      await _wsService.sendCommand(ProtocolActions.mediaMicOff);

  // Brightness Actions
  Future<ResponseMessage> setBrightness(int value) async =>
      await _wsService.sendCommand(ProtocolActions.brightnessSet, params: {'value': value});

  Future<ResponseMessage> brightnessHigh() async =>
      await _wsService.sendCommand(ProtocolActions.brightnessHigh);

  Future<ResponseMessage> brightnessLow() async =>
      await _wsService.sendCommand(ProtocolActions.brightnessLow);

  // Mouse Gestures (Low-latency streaming)
  void sendMouseMove(double dx, double dy) {
    _wsService.sendStreamMessage(ProtocolActions.mouseMove, {'dx': dx, 'dy': dy});
  }

  void sendMouseClick(String button) {
    _wsService.sendStreamMessage(ProtocolActions.mouseClick, {'button': button});
  }

  void sendMouseScroll(double dy) {
    _wsService.sendStreamMessage(ProtocolActions.mouseScroll, {'dy': dy});
  }

  // Keyboard
  void sendKeyboardType(String text) {
    _wsService.sendStreamMessage(ProtocolActions.keyboardType, {'text': text});
  }

  void sendKeyboardKey(String keycode) {
    _wsService.sendStreamMessage(ProtocolActions.keyboardKey, {'key': keycode});
  }

  // Files
  Future<List<RemoteFileItem>> listFiles(String path) async {
    final resp = await _wsService.sendCommand(
      ProtocolActions.filesList,
      params: {'path': path},
    );
    if (resp.success && resp.data != null) {
      final list = resp.data as List;
      return list.map((e) => RemoteFileItem.fromMap(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  Future<ResponseMessage> downloadFile(String remotePath) async {
    return await _wsService.sendCommand(
      ProtocolActions.filesDownload,
      params: {'path': remotePath},
      timeout: const Duration(seconds: 30),
    );
  }

  Future<ResponseMessage> uploadFile(String remotePath, Uint8List fileBytes, String fileName) async {
    final base64Data = base64Encode(fileBytes);
    return await _wsService.sendCommand(
      ProtocolActions.filesUpload,
      params: {
        'path': remotePath,
        'fileName': fileName,
        'data': base64Data,
      },
      timeout: const Duration(seconds: 60),
    );
  }

  void dispose() {
    _transferProgressController.close();
  }
}
