import 'package:flutter_test/flutter_test.dart';
import 'package:pcremote/protocol/command_protocol.dart';
import 'package:pcremote/models/device_models.dart';
import 'package:pcremote/models/system_models.dart';
import 'package:pcremote/models/file_models.dart';

void main() {
  group('PCRemote Protocol and Models Tests', () {
    test('CommandMessage serialize and deserialize correctly', () {
      final msg = CommandMessage(
        id: '12345',
        action: ProtocolActions.powerShutdown,
        params: {'force': true},
        token: 'auth_token_abc',
      );

      final jsonStr = msg.toJson();
      final decoded = CommandMessage.fromJson(jsonStr);

      expect(decoded.id, '12345');
      expect(decoded.action, ProtocolActions.powerShutdown);
      expect(decoded.params['force'], true);
      expect(decoded.token, 'auth_token_abc');
    });

    test('ResponseMessage serialize and deserialize correctly', () {
      final resp = ResponseMessage(
        id: 'req_1',
        action: ProtocolActions.filesList,
        success: true,
        data: [{'name': 'test.txt', 'sizeBytes': 1024}],
      );

      final jsonStr = resp.toJson();
      final decoded = ResponseMessage.fromJson(jsonStr);

      expect(decoded.id, 'req_1');
      expect(decoded.action, ProtocolActions.filesList);
      expect(decoded.success, true);
      expect((decoded.data as List).length, 1);
    });

    test('PairedDevice serialization and copyWith', () {
      final now = DateTime.now();
      final device = PairedDevice(
        id: 'pc_1',
        name: 'Work PC',
        ip: '192.168.1.50',
        port: 8765,
        token: 'token_123',
        type: DeviceType.desktop,
        lastConnected: now,
        isDefault: true,
      );

      final map = device.toMap();
      final fromMap = PairedDevice.fromMap(map);

      expect(fromMap.id, 'pc_1');
      expect(fromMap.name, 'Work PC');
      expect(fromMap.ip, '192.168.1.50');
      expect(fromMap.isDefault, true);

      final updated = device.copyWith(name: 'Workstation 2026');
      expect(updated.name, 'Workstation 2026');
      expect(updated.ip, '192.168.1.50');
    });

    test('HostSystemInfo model default and parsing', () {
      final info = HostSystemInfo.fromMap({
        'hostname': 'Gaming-Rig',
        'osVersion': 'Windows 11 Enterprise',
        'batteryPercent': 98,
        'isCharging': true,
        'volume': 65,
        'brightness': 80,
      });

      expect(info.hostname, 'Gaming-Rig');
      expect(info.batteryPercent, 98);
      expect(info.isCharging, true);
      expect(info.volume, 65);
      expect(info.brightness, 80);
    });

    test('RemoteFileItem formattedSize calculations', () {
      final folder = RemoteFileItem(
        name: 'Projects',
        path: 'C:\\Projects',
        isDirectory: true,
        sizeBytes: 0,
        modifiedAt: DateTime.now(),
      );
      expect(folder.formattedSize, 'Folder');

      final smallFile = RemoteFileItem(
        name: 'readme.txt',
        path: 'C:\\readme.txt',
        isDirectory: false,
        sizeBytes: 500,
        modifiedAt: DateTime.now(),
      );
      expect(smallFile.formattedSize, '500 B');

      final mbFile = RemoteFileItem(
        name: 'video.mp4',
        path: 'C:\\video.mp4',
        isDirectory: false,
        sizeBytes: 15 * 1024 * 1024,
        modifiedAt: DateTime.now(),
      );
      expect(mbFile.formattedSize, '15.0 MB');
    });
  });
}
