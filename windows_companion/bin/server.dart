import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

class PCRemoteServer {
  final int port;
  final int discoveryPort;
  final String pin;
  final String pairingToken;
  final List<WebSocket> _clients = [];
  HttpServer? _httpServer;
  RawDatagramSocket? _discoverySocket;

  int _currentBrightness = 75;
  int _currentVolume = 40;
  bool _isMuted = false;
  bool _isMicMuted = false;
  bool _isPlaying = false;

  PCRemoteServer({
    this.port = 8765,
    this.discoveryPort = 8766,
  })  : pin = (100000 + Random().nextInt(900000)).toString(),
        pairingToken = _generateToken();

  static String _generateToken() {
    final rand = Random.secure();
    final values = List<int>.generate(24, (i) => rand.nextInt(256));
    return base64Url.encode(values);
  }

  Future<void> start() async {
    // 1. Start HTTP & WebSocket Server using standard dart:io
    _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, port, shared: true);
    stdout.writeln('====================================================');
    stdout.writeln('   PCRemote Windows Companion Service Running       ');
    stdout.writeln('====================================================');
    stdout.writeln('WebSocket URL : ws://0.0.0.0:$port/ws');
    stdout.writeln('Pairing PIN   : $pin');
    stdout.writeln('Pairing Token : $pairingToken');
    stdout.writeln('Host Name     : ${Platform.localHostname}');
    stdout.writeln('Operating Sys : ${Platform.operatingSystemVersion}');
    stdout.writeln('====================================================\n');

    _httpServer?.listen((HttpRequest request) async {
      if (request.uri.path == '/ws' || WebSocketTransformer.isUpgradeRequest(request)) {
        try {
          final socket = await WebSocketTransformer.upgrade(request);
          _clients.add(socket);
          stdout.writeln('-> Android client connected.');

          socket.listen(
            (message) => _handleClientMessage(socket, message),
            onDone: () {
              _clients.remove(socket);
              stdout.writeln('-> Android client disconnected.');
            },
            onError: (e) {
              _clients.remove(socket);
              stderr.writeln('-> Client error: $e');
            },
          );
        } catch (e) {
          stderr.writeln('WebSocket upgrade failed: $e');
        }
      } else {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.json
          ..write(json.encode({
            'service': 'pcremote',
            'version': '1.0.0',
            'host': Platform.localHostname,
          }))
          ..close();
      }
    });

    // 2. Start UDP Discovery Beacon
    _startDiscoveryBeacon();
  }

  Future<void> _startDiscoveryBeacon() async {
    try {
      _discoverySocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        discoveryPort,
        reuseAddress: true,
      );
      _discoverySocket?.broadcastEnabled = true;

      _discoverySocket?.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = _discoverySocket?.receive();
          if (datagram != null) {
            final text = utf8.decode(datagram.data);
            if (text.contains('pcremote_discover')) {
              final beacon = json.encode({
                'service': 'pcremote',
                'type': 'pcremote_beacon',
                'id': 'pc_${Platform.localHostname.toLowerCase()}',
                'name': Platform.localHostname,
                'port': port,
                'deviceType': 'desktop',
              });
              _discoverySocket?.send(
                utf8.encode(beacon),
                datagram.address,
                datagram.port,
              );
            }
          }
        }
      });
      stdout.writeln('UDP Discovery Beacon active on port $discoveryPort.');
    } catch (e) {
      stderr.writeln('Warning: UDP Discovery socket could not bind ($e).');
    }
  }

  void _handleClientMessage(WebSocket client, dynamic message) {
    try {
      final text = message is String ? message : utf8.decode(message as List<int>);
      final map = json.decode(text) as Map<String, dynamic>;

      final id = map['id'] as String? ?? '';
      final action = map['action'] as String? ?? '';
      final params = (map['params'] as Map<String, dynamic>?) ?? {};

      _dispatchCommand(client, id, action, params);
    } catch (e) {
      stderr.writeln('Failed to parse client message: $e');
    }
  }

  void _dispatchCommand(
    WebSocket client,
    String id,
    String action,
    Map<String, dynamic> params,
  ) {
    switch (action) {
      // 1. Pairing
      case 'pairing.requestPin':
        _sendResponse(client, id, action, true, data: {'pinRequired': true});
        break;

      case 'pairing.verify':
        final inputPin = params['pin'] as String?;
        final inputToken = params['token'] as String?;
        if (inputPin == pin || inputToken == pairingToken) {
          _sendResponse(client, id, action, true, data: {
            'token': pairingToken,
            'name': Platform.localHostname,
          });
          stdout.writeln('-> Pairing verified successfully for client.');
        } else {
          _sendResponse(client, id, action, false, error: 'Invalid PIN or token.');
        }
        break;

      // 2. System status
      case 'system.status':
        _sendResponse(client, id, action, true, data: {
          'hostname': Platform.localHostname,
          'osVersion': Platform.operatingSystemVersion,
          'batteryPercent': 92,
          'isCharging': true,
          'brightness': _currentBrightness,
          'volume': _currentVolume,
          'isMuted': _isMuted,
          'isMicMuted': _isMicMuted,
          'isPlaying': _isPlaying,
          'activeMediaTitle': _isPlaying ? 'Windows Media Player' : 'System Idle',
          'activeMediaArtist': 'Desktop Audio',
          'cpuUsage': 14.2,
          'ramUsage': 38.6,
        });
        break;

      // 3. Power Actions
      case 'power.shutdown':
        stdout.writeln('[POWER] Executing Shutdown');
        _runProcess('shutdown', ['/s', '/t', '0']);
        _sendResponse(client, id, action, true);
        break;

      case 'power.restart':
        stdout.writeln('[POWER] Executing Restart');
        _runProcess('shutdown', ['/r', '/t', '0']);
        _sendResponse(client, id, action, true);
        break;

      case 'power.sleep':
        stdout.writeln('[POWER] Executing Sleep');
        _runProcess('rundll32.exe', ['powrprof.dll,SetSuspendState', '0,1,0']);
        _sendResponse(client, id, action, true);
        break;

      case 'power.hibernate':
        stdout.writeln('[POWER] Executing Hibernate');
        _runProcess('shutdown', ['/h']);
        _sendResponse(client, id, action, true);
        break;

      case 'power.logoff':
        stdout.writeln('[POWER] Executing Logoff');
        _runProcess('shutdown', ['/l']);
        _sendResponse(client, id, action, true);
        break;

      case 'power.lock':
        stdout.writeln('[POWER] Executing Lock Screen');
        _runProcess('rundll32.exe', ['user32.dll,LockWorkStation']);
        _sendResponse(client, id, action, true);
        break;

      // 4. Media Actions
      case 'media.playpause':
        _isPlaying = !_isPlaying;
        _sendVirtualKey(0xB3); // VK_MEDIA_PLAY_PAUSE
        _sendResponse(client, id, action, true);
        break;

      case 'media.next':
        _sendVirtualKey(0xB0); // VK_MEDIA_NEXT_TRACK
        _sendResponse(client, id, action, true);
        break;

      case 'media.previous':
        _sendVirtualKey(0xB1); // VK_MEDIA_PREV_TRACK
        _sendResponse(client, id, action, true);
        break;

      case 'media.volumeUp':
        _currentVolume = (_currentVolume + 2).clamp(0, 100);
        _sendVirtualKey(0xAF); // VK_VOLUME_UP
        _sendResponse(client, id, action, true);
        break;

      case 'media.volumeDown':
        _currentVolume = (_currentVolume - 2).clamp(0, 100);
        _sendVirtualKey(0xAE); // VK_VOLUME_DOWN
        _sendResponse(client, id, action, true);
        break;

      case 'media.mute':
        _isMuted = true;
        _sendVirtualKey(0xAD); // VK_VOLUME_MUTE
        _sendResponse(client, id, action, true);
        break;

      case 'media.unmute':
        _isMuted = false;
        _sendVirtualKey(0xAD); // VK_VOLUME_MUTE
        _sendResponse(client, id, action, true);
        break;

      case 'media.micOn':
        _isMicMuted = false;
        _sendResponse(client, id, action, true);
        break;

      case 'media.micOff':
        _isMicMuted = true;
        _sendResponse(client, id, action, true);
        break;

      // 5. Brightness Actions
      case 'brightness.set':
        final val = (params['value'] as num?)?.toInt() ?? 75;
        _currentBrightness = val.clamp(0, 100);
        _setWindowsBrightness(_currentBrightness);
        _sendResponse(client, id, action, true);
        break;

      case 'brightness.high':
        _currentBrightness = 100;
        _setWindowsBrightness(100);
        _sendResponse(client, id, action, true);
        break;

      case 'brightness.low':
        _currentBrightness = 25;
        _setWindowsBrightness(25);
        _sendResponse(client, id, action, true);
        break;

      // 6. Mouse Gestures
      case 'mouse.move':
        final dx = (params['dx'] as num?)?.toDouble() ?? 0.0;
        final dy = (params['dy'] as num?)?.toDouble() ?? 0.0;
        _injectMouseMove(dx.toInt(), dy.toInt());
        break;

      case 'mouse.click':
        final btn = params['button'] as String? ?? 'left';
        _injectMouseClick(btn);
        break;

      case 'mouse.scroll':
        final dy = (params['dy'] as num?)?.toDouble() ?? 0.0;
        _injectMouseScroll(dy.toInt());
        break;

      // 7. Keyboard Actions
      case 'keyboard.type':
        final text = params['text'] as String? ?? '';
        _injectKeyboardType(text);
        break;

      case 'keyboard.key':
        final key = params['key'] as String? ?? '';
        _injectKeyboardKey(key);
        break;

      // 8. File Manager Actions
      case 'files.list':
        final path = params['path'] as String? ?? 'C:\\';
        final items = _listDirectory(path);
        _sendResponse(client, id, action, true, data: items);
        break;

      case 'files.download':
        final filePath = params['path'] as String?;
        if (filePath != null && File(filePath).existsSync()) {
          final bytes = File(filePath).readAsBytesSync();
          final b64 = base64Encode(bytes);
          _sendResponse(client, id, action, true, data: {
            'path': filePath,
            'data': b64,
          });
        } else {
          _sendResponse(client, id, action, false, error: 'File not found');
        }
        break;

      case 'files.upload':
        final targetPath = params['path'] as String? ?? 'C:\\';
        final fileName = params['fileName'] as String? ?? 'uploaded_file';
        final data = params['data'] as String?;
        if (data != null) {
          final bytes = base64Decode(data);
          final fullPath = targetPath.endsWith('\\') || targetPath.endsWith('/')
              ? '$targetPath$fileName'
              : '$targetPath\\$fileName';
          File(fullPath).writeAsBytesSync(bytes);
          _sendResponse(client, id, action, true, data: {'path': fullPath});
        } else {
          _sendResponse(client, id, action, false, error: 'Missing file data');
        }
        break;

      default:
        _sendResponse(client, id, action, false, error: 'Unknown action: $action');
    }
  }

  void _sendResponse(
    WebSocket client,
    String id,
    String action,
    bool success, {
    dynamic data,
    String? error,
  }) {
    try {
      final map = <String, dynamic>{
        'id': id,
        'action': action,
        'success': success,
      };
      if (data != null) map['data'] = data;
      if (error != null) map['error'] = error;
      final resp = json.encode(map);
      client.add(resp);
    } catch (_) {}
  }

  void _runProcess(String executable, List<String> arguments) {
    if (Platform.isWindows) {
      Process.run(executable, arguments).catchError((Object err) {
        return ProcessResult(0, -1, '', err.toString());
      });
    }
  }

  void _sendVirtualKey(int vkey) {
    if (!Platform.isWindows) return;
    Process.run('powershell', [
      '-Command',
      r'''
      $wshell = New-Object -ComObject wscript.shell;
      Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, uint dwExtraInfo);' -Name "Win32Key" -Namespace Win32Functions;
      '''
      r'[Win32Functions.Win32Key]::keybd_event(' '$vkey' r', 0, 0, 0); [Win32Functions.Win32Key]::keybd_event(' '$vkey' r', 0, 2, 0);'
    ]).catchError((Object err) {
      return ProcessResult(0, -1, '', err.toString());
    });
  }

  void _setWindowsBrightness(int val) {
    if (!Platform.isWindows) return;
    Process.run('powershell', [
      '-Command',
      '(Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightnessMethods).WmiSetBrightness(1, $val)'
    ]).catchError((Object err) {
      return ProcessResult(0, -1, '', err.toString());
    });
  }

  void _injectMouseMove(int dx, int dy) {
    if (!Platform.isWindows) return;
    Process.run('powershell', [
      '-Command',
      r'''Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern void mouse_event(uint dwFlags, int dx, int dy, uint dwData, int dwExtraInfo);' -Name "Win32Mouse" -Namespace Win32;'''
      r'[Win32.Win32Mouse]::mouse_event(1, ' '$dx' r', ' '$dy' r', 0, 0);'
    ]).catchError((Object err) {
      return ProcessResult(0, -1, '', err.toString());
    });
  }

  void _injectMouseClick(String btn) {
    if (!Platform.isWindows) return;
    int down = 2; // LEFTDOWN
    int up = 4; // LEFTUP
    if (btn == 'right') {
      down = 8;
      up = 16;
    }
    Process.run('powershell', [
      '-Command',
      r'''Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern void mouse_event(uint dwFlags, int dx, int dy, uint dwData, int dwExtraInfo);' -Name "Win32Mouse" -Namespace Win32;'''
      r'[Win32.Win32Mouse]::mouse_event(' '$down' r', 0, 0, 0, 0); [Win32.Win32Mouse]::mouse_event(' '$up' r', 0, 0, 0, 0);'
    ]).catchError((Object err) {
      return ProcessResult(0, -1, '', err.toString());
    });
  }

  void _injectMouseScroll(int dy) {
    if (!Platform.isWindows) return;
    final wheelDelta = dy * 40;
    Process.run('powershell', [
      '-Command',
      r'''Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern void mouse_event(uint dwFlags, int dx, int dy, uint dwData, int dwExtraInfo);' -Name "Win32Mouse" -Namespace Win32;'''
      r'[Win32.Win32Mouse]::mouse_event(2048, 0, 0, ' '$wheelDelta' r', 0);'
    ]).catchError((Object err) {
      return ProcessResult(0, -1, '', err.toString());
    });
  }

  void _injectKeyboardType(String text) {
    if (!Platform.isWindows) return;
    final escaped = text.replaceAll('"', '`"').replaceAll("'", "''");
    Process.run('powershell', [
      '-Command',
      r'$w = New-Object -ComObject WScript.Shell; $w.SendKeys("' '$escaped' r'")'
    ]).catchError((Object err) {
      return ProcessResult(0, -1, '', err.toString());
    });
  }

  void _injectKeyboardKey(String keycode) {
    if (!Platform.isWindows) return;
    String winKey = '';
    switch (keycode.toLowerCase()) {
      case 'escape':
        winKey = '{ESC}';
        break;
      case 'tab':
        winKey = '{TAB}';
        break;
      case 'enter':
        winKey = '{ENTER}';
        break;
      case 'backspace':
        winKey = '{BACKSPACE}';
        break;
      case 'delete':
        winKey = '{DELETE}';
        break;
      case 'up':
        winKey = '{UP}';
        break;
      case 'down':
        winKey = '{DOWN}';
        break;
      case 'left':
        winKey = '{LEFT}';
        break;
      case 'right':
        winKey = '{RIGHT}';
        break;
      case 'space':
        winKey = ' ';
        break;
      case 'win':
        winKey = '^{ESC}';
        break;
      default:
        winKey = keycode;
    }

    Process.run('powershell', [
      '-Command',
      r'$w = New-Object -ComObject WScript.Shell; $w.SendKeys("' '$winKey' r'")'
    ]).catchError((Object err) {
      return ProcessResult(0, -1, '', err.toString());
    });
  }

  List<Map<String, dynamic>> _listDirectory(String path) {
    try {
      final dir = Directory(path);
      if (!dir.existsSync()) return [];

      final entries = dir.listSync(followLinks: false);
      final List<Map<String, dynamic>> items = [];

      for (final entity in entries) {
        try {
          final stat = entity.statSync();
          final isDir = entity is Directory;
          final name = entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
          final ext = isDir ? null : name.contains('.') ? name.split('.').last : null;

          items.add({
            'name': name,
            'path': entity.path,
            'isDirectory': isDir,
            'sizeBytes': isDir ? 0 : stat.size,
            'modifiedAt': stat.modified.toIso8601String(),
            'extension': ext,
          });
        } catch (_) {}
      }

      items.sort((a, b) {
        if (a['isDirectory'] == true && b['isDirectory'] != true) return -1;
        if (a['isDirectory'] != true && b['isDirectory'] == true) return 1;
        return (a['name'] as String).toLowerCase().compareTo((b['name'] as String).toLowerCase());
      });

      return items;
    } catch (_) {
      return [];
    }
  }
}

void main(List<String> args) async {
  final server = PCRemoteServer();
  await server.start();
}
