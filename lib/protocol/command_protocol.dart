import 'dart:convert';

class CommandMessage {
  final String id;
  final String action;
  final Map<String, dynamic> params;
  final String? token;

  CommandMessage({
    required this.id,
    required this.action,
    this.params = const {},
    this.token,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'params': params,
      if (token != null) 'token': token,
    };
  }

  String toJson() => json.encode(toMap());

  factory CommandMessage.fromMap(Map<String, dynamic> map) {
    return CommandMessage(
      id: map['id'] as String? ?? '',
      action: map['action'] as String? ?? '',
      params: (map['params'] as Map<String, dynamic>?) ?? {},
      token: map['token'] as String?,
    );
  }

  factory CommandMessage.fromJson(String source) =>
      CommandMessage.fromMap(json.decode(source) as Map<String, dynamic>);
}

class ResponseMessage {
  final String id;
  final String action;
  final bool success;
  final dynamic data;
  final String? error;

  ResponseMessage({
    required this.id,
    required this.action,
    required this.success,
    this.data,
    this.error,
  });

  factory ResponseMessage.fromMap(Map<String, dynamic> map) {
    return ResponseMessage(
      id: map['id'] as String? ?? '',
      action: map['action'] as String? ?? '',
      success: map['success'] as bool? ?? false,
      data: map['data'],
      error: map['error'] as String?,
    );
  }

  factory ResponseMessage.fromJson(String source) =>
      ResponseMessage.fromMap(json.decode(source) as Map<String, dynamic>);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'success': success,
      'data': data,
      'error': error,
    };
  }

  String toJson() => json.encode(toMap());
}

/// Constant action names matching the PCRemote protocol.
class ProtocolActions {
  ProtocolActions._();

  // Pairing
  static const String pairingRequestPin = 'pairing.requestPin';
  static const String pairingVerify = 'pairing.verify';

  // System status
  static const String systemStatus = 'system.status';

  // Power
  static const String powerShutdown = 'power.shutdown';
  static const String powerRestart = 'power.restart';
  static const String powerSleep = 'power.sleep';
  static const String powerHibernate = 'power.hibernate';
  static const String powerLogoff = 'power.logoff';
  static const String powerLock = 'power.lock';

  // Media
  static const String mediaPlayPause = 'media.playpause';
  static const String mediaNext = 'media.next';
  static const String mediaPrevious = 'media.previous';
  static const String mediaVolumeUp = 'media.volumeUp';
  static const String mediaVolumeDown = 'media.volumeDown';
  static const String mediaSetVolume = 'media.setVolume';
  static const String mediaMute = 'media.mute';
  static const String mediaUnmute = 'media.unmute';
  static const String mediaMicOn = 'media.micOn';
  static const String mediaMicOff = 'media.micOff';

  // Brightness
  static const String brightnessSet = 'brightness.set';
  static const String brightnessHigh = 'brightness.high';
  static const String brightnessLow = 'brightness.low';

  // Mouse
  static const String mouseMove = 'mouse.move';
  static const String mouseClick = 'mouse.click';
  static const String mouseScroll = 'mouse.scroll';

  // Keyboard
  static const String keyboardType = 'keyboard.type';
  static const String keyboardKey = 'keyboard.key';

  // Files
  static const String filesList = 'files.list';
  static const String filesDownload = 'files.download';
  static const String filesUpload = 'files.upload';
}
