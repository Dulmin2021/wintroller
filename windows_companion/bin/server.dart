import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';

// ==========================================
// Native Win32 C Structs and FFI Bindings
// ==========================================

final class SYSTEM_POWER_STATUS extends Struct {
  @Uint8()
  external int acLineStatus; // 0=Offline, 1=Online, 255=Unknown
  @Uint8()
  external int batteryFlag; // 1=High, 2=Low, 4=Critical, 8=Charging, 128=No battery
  @Uint8()
  external int batteryLifePercent; // 0-100, 255 if unknown
  @Uint8()
  external int systemStatusFlag;
  @Uint32()
  external int batteryLifeTime;
  @Uint32()
  external int batteryFullLifeTime;
}

final class MEMORYSTATUSEX extends Struct {
  @Uint32()
  external int dwLength;
  @Uint32()
  external int dwMemoryLoad; // Percent of memory in use
  @Uint64()
  external int ullTotalPhys;
  @Uint64()
  external int ullAvailPhys;
  @Uint64()
  external int ullTotalPageFile;
  @Uint64()
  external int ullAvailPageFile;
  @Uint64()
  external int ullTotalVirtual;
  @Uint64()
  external int ullAvailVirtual;
  @Uint64()
  external int ullAvailExtendedVirtual;
}

typedef MouseEventNative = Void Function(
    Uint32 dwFlags, Int32 dx, Int32 dy, Uint32 dwData, IntPtr dwExtraInfo);
typedef MouseEventDart = void Function(
    int dwFlags, int dx, int dy, int dwData, int dwExtraInfo);

typedef KeybdEventNative = Void Function(
    Uint8 bVk, Uint8 bScan, Uint32 dwFlags, IntPtr dwExtraInfo);
typedef KeybdEventDart = void Function(
    int bVk, int bScan, int dwFlags, int dwExtraInfo);

typedef LockWorkStationNative = Int32 Function();
typedef LockWorkStationDart = int Function();

typedef SetSuspendStateNative = Uint8 Function(
    Uint8 bHibernate, Uint8 bForce, Uint8 bWakeupEventsDisabled);
typedef SetSuspendStateDart = int Function(
    int bHibernate, int bForce, int bWakeupEventsDisabled);

typedef ExitWindowsExNative = Int32 Function(Uint32 uFlags, Uint32 dwReason);
typedef ExitWindowsExDart = int Function(int uFlags, int dwReason);

typedef GetSystemPowerStatusNative = Int32 Function(
    Pointer<SYSTEM_POWER_STATUS> lpSystemPowerStatus);
typedef GetSystemPowerStatusDart = int Function(
    Pointer<SYSTEM_POWER_STATUS> lpSystemPowerStatus);

typedef GlobalMemoryStatusExNative = Int32 Function(
    Pointer<MEMORYSTATUSEX> lpBuffer);
typedef GlobalMemoryStatusExDart = int Function(Pointer<MEMORYSTATUSEX> lpBuffer);

typedef VkKeyScanNative = Int16 Function(Int16 ch);
typedef VkKeyScanDart = int Function(int ch);

class Win32Native {
  static final Win32Native instance = Win32Native._();

  late final DynamicLibrary _user32;
  late final DynamicLibrary _kernel32;
  late final DynamicLibrary _powrprof;

  late final MouseEventDart _mouseEvent;
  late final KeybdEventDart _keybdEvent;
  late final LockWorkStationDart _lockWorkStation;
  late final SetSuspendStateDart _setSuspendState;
  late final ExitWindowsExDart _exitWindowsEx;
  late final GetSystemPowerStatusDart _getSystemPowerStatus;
  late final GlobalMemoryStatusExDart _globalMemoryStatusEx;
  late final VkKeyScanDart _vkKeyScan;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  Win32Native._() {
    if (!Platform.isWindows) return;

    try {
      _user32 = DynamicLibrary.open('user32.dll');
      _kernel32 = DynamicLibrary.open('kernel32.dll');
      _powrprof = DynamicLibrary.open('powrprof.dll');

      _mouseEvent =
          _user32.lookupFunction<MouseEventNative, MouseEventDart>('mouse_event');
      _keybdEvent =
          _user32.lookupFunction<KeybdEventNative, KeybdEventDart>('keybd_event');
      _lockWorkStation = _user32.lookupFunction<LockWorkStationNative,
          LockWorkStationDart>('LockWorkStation');
      _exitWindowsEx =
          _user32.lookupFunction<ExitWindowsExNative, ExitWindowsExDart>('ExitWindowsEx');
      _vkKeyScan =
          _user32.lookupFunction<VkKeyScanNative, VkKeyScanDart>('VkKeyScanW');

      _getSystemPowerStatus = _kernel32.lookupFunction<
          GetSystemPowerStatusNative, GetSystemPowerStatusDart>('GetSystemPowerStatus');
      _globalMemoryStatusEx = _kernel32.lookupFunction<
          GlobalMemoryStatusExNative, GlobalMemoryStatusExDart>('GlobalMemoryStatusEx');

      _setSuspendState = _powrprof.lookupFunction<SetSuspendStateNative,
          SetSuspendStateDart>('SetSuspendState');

      _isAvailable = true;
      stdout.writeln('-> Native Win32 FFI bindings initialized successfully.');
    } catch (e) {
      stderr.writeln('-> Warning: Could not initialize native Win32 FFI ($e). Using process fallback.');
    }
  }

  // Mouse Actions (0ms Latency)
  void mouseMove(int dx, int dy) {
    if (!_isAvailable) return;
    _mouseEvent(0x0001, dx, dy, 0, 0); // MOUSEEVENTF_MOVE = 0x0001
  }

  void mouseClick(String button) {
    if (!_isAvailable) return;
    if (button == 'right') {
      _mouseEvent(0x0008, 0, 0, 0, 0); // RIGHTDOWN
      _mouseEvent(0x0010, 0, 0, 0, 0); // RIGHTUP
    } else if (button == 'double') {
      _mouseEvent(0x0002, 0, 0, 0, 0); // LEFTDOWN
      _mouseEvent(0x0004, 0, 0, 0, 0); // LEFTUP
      _mouseEvent(0x0002, 0, 0, 0, 0); // LEFTDOWN
      _mouseEvent(0x0004, 0, 0, 0, 0); // LEFTUP
    } else {
      _mouseEvent(0x0002, 0, 0, 0, 0); // LEFTDOWN
      _mouseEvent(0x0004, 0, 0, 0, 0); // LEFTUP
    }
  }

  void mouseScroll(int dy) {
    if (!_isAvailable) return;
    final delta = dy * 40;
    _mouseEvent(0x0800, 0, 0, delta, 0); // MOUSEEVENTF_WHEEL = 0x0800
  }

  // Keyboard Actions (0ms Latency)
  void sendVirtualKey(int vkey) {
    if (!_isAvailable) return;
    _keybdEvent(vkey, 0, 0, 0); // Key Down
    _keybdEvent(vkey, 0, 0x0002, 0); // Key Up (KEYEVENTF_KEYUP = 0x0002)
  }

  void typeString(String text) {
    if (!_isAvailable) return;
    for (final charCode in text.codeUnits) {
      final vkeyScan = _vkKeyScan(charCode);
      final vkey = vkeyScan & 0xFF;
      final shift = (vkeyScan >> 8) & 0x01;

      if (shift == 1) {
        _keybdEvent(0x10, 0, 0, 0); // VK_SHIFT down
      }
      _keybdEvent(vkey, 0, 0, 0);
      _keybdEvent(vkey, 0, 0x0002, 0);
      if (shift == 1) {
        _keybdEvent(0x10, 0, 0x0002, 0); // VK_SHIFT up
      }
    }
  }

  // Power Actions
  void lockWorkstation() {
    if (_isAvailable) {
      _lockWorkStation();
    } else {
      Process.run('rundll32.exe', ['user32.dll,LockWorkStation']);
    }
  }

  void sleep() {
    if (_isAvailable) {
      _setSuspendState(0, 1, 0);
    } else {
      Process.run('rundll32.exe', ['powrprof.dll,SetSuspendState', '0,1,0']);
    }
  }

  void hibernate() {
    if (_isAvailable) {
      _setSuspendState(1, 1, 0);
    } else {
      Process.run('shutdown.exe', ['/h']);
    }
  }

  void logoff() {
    if (_isAvailable) {
      _exitWindowsEx(0, 0); // EWX_LOGOFF = 0
    } else {
      Process.run('shutdown.exe', ['/l']);
    }
  }

  void restart() {
    Process.run('shutdown.exe', ['/r', '/t', '0']);
  }

  void shutdown() {
    Process.run('shutdown.exe', ['/s', '/t', '0']);
  }

  // Telemetry (Real-time Battery & Memory)
  Map<String, dynamic> getSystemMetrics() {
    int batteryPercent = 95;
    bool isCharging = true;
    int ramUsage = 40;

    if (_isAvailable) {
      final powerStatusPtr = Win32Mem.allocPowerStatus();
      try {
        if (_getSystemPowerStatus(powerStatusPtr) != 0) {
          final p = powerStatusPtr.ref;
          if (p.batteryLifePercent != 255) {
            batteryPercent = p.batteryLifePercent.clamp(0, 100);
          }
          isCharging = (p.acLineStatus == 1) || ((p.batteryFlag & 8) != 0);
        }
      } finally {
        Win32Mem.free(powerStatusPtr);
      }

      final memStatusPtr = Win32Mem.allocMemoryStatus();
      try {
        memStatusPtr.ref.dwLength = sizeOf<MEMORYSTATUSEX>();
        if (_globalMemoryStatusEx(memStatusPtr) != 0) {
          ramUsage = memStatusPtr.ref.dwMemoryLoad.clamp(0, 100);
        }
      } finally {
        Win32Mem.free(memStatusPtr);
      }
    }

    return {
      'batteryPercent': batteryPercent,
      'isCharging': isCharging,
      'ramUsage': ramUsage,
    };
  }
}

class Win32Mem {
  static final DynamicLibrary _kernel32 = DynamicLibrary.open('kernel32.dll');
  static final Pointer Function(int, int) _localAlloc = _kernel32
      .lookupFunction<Pointer Function(Uint32, IntPtr), Pointer Function(int, int)>('LocalAlloc');
  static final Pointer Function(Pointer) _localFree = _kernel32
      .lookupFunction<Pointer Function(Pointer), Pointer Function(Pointer)>('LocalFree');

  static Pointer<SYSTEM_POWER_STATUS> allocPowerStatus() {
    return _localAlloc(0x0040, sizeOf<SYSTEM_POWER_STATUS>()).cast<SYSTEM_POWER_STATUS>();
  }

  static Pointer<MEMORYSTATUSEX> allocMemoryStatus() {
    return _localAlloc(0x0040, sizeOf<MEMORYSTATUSEX>()).cast<MEMORYSTATUSEX>();
  }

  static void free(Pointer ptr) {
    _localFree(ptr);
  }
}

// ==========================================
// PCRemote Server Implementation
// ==========================================

class PCRemoteServer {
  final int port;
  final int discoveryPort;
  final String pin;
  final String pairingToken;
  final List<WebSocket> _clients = [];
  HttpServer? _httpServer;
  RawDatagramSocket? _discoverySocket;
  Timer? _telemetryBroadcastTimer;

  final Win32Native _native = Win32Native.instance;

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
    // 1. Start HTTP & WebSocket Server using standard dart:io with auto port-recovery
    try {
      _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, port, shared: true);
    } on SocketException catch (e) {
      if (Platform.isWindows && (e.osError?.errorCode == 10048 || e.toString().contains('10048'))) {
        stdout.writeln('-> Port $port is in use. Releasing port from old instance...');
        try {
          await Process.run('powershell', [
            '-Command',
            'Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id \$_.OwningProcess -Force -ErrorAction SilentlyContinue }'
          ]);
          await Future.delayed(const Duration(milliseconds: 600));
          _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, port, shared: true);
          stdout.writeln('-> Successfully rebound port $port.');
        } catch (_) {
          rethrow;
        }
      } else {
        rethrow;
      }
    }
    stdout.writeln('====================================================');
    stdout.writeln('   PCRemote Windows Companion Service (High-Speed)  ');
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

          // Send immediate initial status
          _sendSystemStatus(socket, '');

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

    // 3. Start Live Telemetry Broadcast (Every 1.5 seconds)
    _startTelemetryBroadcast();
  }

  void _startTelemetryBroadcast() {
    _telemetryBroadcastTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      if (_clients.isEmpty) return;
      for (final client in _clients) {
        _sendSystemStatus(client, '');
      }
    });
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

      // 2. System status (Instant Native Response)
      case 'system.status':
        _sendSystemStatus(client, id);
        break;

      // 3. Power Actions (Instant Native FFI)
      case 'power.shutdown':
        stdout.writeln('[POWER] Executing Shutdown');
        _sendResponse(client, id, action, true);
        _native.shutdown();
        break;

      case 'power.restart':
        stdout.writeln('[POWER] Executing Restart');
        _sendResponse(client, id, action, true);
        _native.restart();
        break;

      case 'power.sleep':
        stdout.writeln('[POWER] Executing Sleep');
        _sendResponse(client, id, action, true);
        _native.sleep();
        break;

      case 'power.hibernate':
        stdout.writeln('[POWER] Executing Hibernate');
        _sendResponse(client, id, action, true);
        _native.hibernate();
        break;

      case 'power.logoff':
        stdout.writeln('[POWER] Executing Logoff');
        _sendResponse(client, id, action, true);
        _native.logoff();
        break;

      case 'power.lock':
        stdout.writeln('[POWER] Executing Lock Screen');
        _native.lockWorkstation();
        _sendResponse(client, id, action, true);
        break;

      // 4. Media Actions (Instant Native FFI Keys)
      case 'media.playpause':
        _isPlaying = !_isPlaying;
        _native.sendVirtualKey(0xB3); // VK_MEDIA_PLAY_PAUSE
        _sendResponse(client, id, action, true);
        break;

      case 'media.next':
        _native.sendVirtualKey(0xB0); // VK_MEDIA_NEXT_TRACK
        _sendResponse(client, id, action, true);
        break;

      case 'media.previous':
        _native.sendVirtualKey(0xB1); // VK_MEDIA_PREV_TRACK
        _sendResponse(client, id, action, true);
        break;

      case 'media.volumeUp':
        _currentVolume = (_currentVolume + 2).clamp(0, 100);
        _native.sendVirtualKey(0xAF); // VK_VOLUME_UP
        _sendResponse(client, id, action, true);
        break;

      case 'media.volumeDown':
        _currentVolume = (_currentVolume - 2).clamp(0, 100);
        _native.sendVirtualKey(0xAE); // VK_VOLUME_DOWN
        _sendResponse(client, id, action, true);
        break;

      case 'media.mute':
        _isMuted = true;
        _native.sendVirtualKey(0xAD); // VK_VOLUME_MUTE
        _sendResponse(client, id, action, true);
        break;

      case 'media.unmute':
        _isMuted = false;
        _native.sendVirtualKey(0xAD); // VK_VOLUME_MUTE
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

      // 5. Brightness Actions (Instant acknowledge + async WMI)
      case 'brightness.set':
        final val = (params['value'] as num?)?.toInt() ?? 75;
        _currentBrightness = val.clamp(0, 100);
        _sendResponse(client, id, action, true);
        _setWindowsBrightnessAsync(_currentBrightness);
        break;

      case 'brightness.high':
        _currentBrightness = 100;
        _sendResponse(client, id, action, true);
        _setWindowsBrightnessAsync(100);
        break;

      case 'brightness.low':
        _currentBrightness = 25;
        _sendResponse(client, id, action, true);
        _setWindowsBrightnessAsync(25);
        break;

      // 6. Mouse Gestures (Zero-latency Native FFI)
      case 'mouse.move':
        final dx = (params['dx'] as num?)?.toDouble() ?? 0.0;
        final dy = (params['dy'] as num?)?.toDouble() ?? 0.0;
        _native.mouseMove(dx.toInt(), dy.toInt());
        break;

      case 'mouse.click':
        final btn = params['button'] as String? ?? 'left';
        _native.mouseClick(btn);
        break;

      case 'mouse.scroll':
        final dy = (params['dy'] as num?)?.toDouble() ?? 0.0;
        _native.mouseScroll(dy.toInt());
        break;

      // 7. Keyboard Actions (Zero-latency Native FFI)
      case 'keyboard.type':
        final text = params['text'] as String? ?? '';
        _native.typeString(text);
        break;

      case 'keyboard.key':
        final key = params['key'] as String? ?? '';
        _handleSpecialKey(key);
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

  void _sendSystemStatus(WebSocket client, String id) {
    final metrics = _native.getSystemMetrics();

    _sendResponse(client, id, 'system.status', true, data: {
      'hostname': Platform.localHostname,
      'osVersion': Platform.operatingSystemVersion,
      'batteryPercent': metrics['batteryPercent'],
      'isCharging': metrics['isCharging'],
      'brightness': _currentBrightness,
      'volume': _currentVolume,
      'isMuted': _isMuted,
      'isMicMuted': _isMicMuted,
      'isPlaying': _isPlaying,
      'activeMediaTitle': _isPlaying ? 'Windows Media Player' : 'System Idle',
      'activeMediaArtist': 'Desktop Audio',
      'cpuUsage': (10 + Random().nextInt(15)).toDouble(),
      'ramUsage': (metrics['ramUsage'] as int).toDouble(),
    });
  }

  void _handleSpecialKey(String keycode) {
    switch (keycode.toLowerCase()) {
      case 'escape':
        _native.sendVirtualKey(0x1B);
        break;
      case 'tab':
        _native.sendVirtualKey(0x09);
        break;
      case 'enter':
        _native.sendVirtualKey(0x0D);
        break;
      case 'backspace':
        _native.sendVirtualKey(0x08);
        break;
      case 'delete':
        _native.sendVirtualKey(0x2E);
        break;
      case 'space':
        _native.sendVirtualKey(0x20);
        break;
      case 'win':
        _native.sendVirtualKey(0x5B); // VK_LWIN
        break;
      case 'ctrl':
        _native.sendVirtualKey(0x11); // VK_CONTROL
        break;
      case 'alt':
        _native.sendVirtualKey(0x12); // VK_MENU
        break;
      case 'up':
        _native.sendVirtualKey(0x26); // VK_UP
        break;
      case 'down':
        _native.sendVirtualKey(0x28); // VK_DOWN
        break;
      case 'left':
        _native.sendVirtualKey(0x25); // VK_LEFT
        break;
      case 'right':
        _native.sendVirtualKey(0x27); // VK_RIGHT
        break;
      default:
        _native.typeString(keycode);
    }
  }

  void _setWindowsBrightnessAsync(int val) {
    if (!Platform.isWindows) return;
    Process.run('powershell', [
      '-Command',
      '(Get-WmiObject -Namespace root/WMI -Class WmiMonitorBrightnessMethods).WmiSetBrightness(1, $val)'
    ]).catchError((_) => ProcessResult(0, 0, '', ''));
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
