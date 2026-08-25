import 'dart:convert';

enum DeviceType { laptop, desktop, unknown }

class PairedDevice {
  final String id;
  final String name;
  final String ip;
  final int port;
  final String? token;
  final DeviceType type;
  final DateTime lastConnected;
  final bool isDefault;

  const PairedDevice({
    required this.id,
    required this.name,
    required this.ip,
    this.port = 8765,
    this.token,
    this.type = DeviceType.desktop,
    required this.lastConnected,
    this.isDefault = false,
  });

  PairedDevice copyWith({
    String? id,
    String? name,
    String? ip,
    int? port,
    String? token,
    DeviceType? type,
    DateTime? lastConnected,
    bool? isDefault,
  }) {
    return PairedDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      token: token ?? this.token,
      type: type ?? this.type,
      lastConnected: lastConnected ?? this.lastConnected,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'ip': ip,
      'port': port,
      'token': token,
      'type': type.name,
      'lastConnected': lastConnected.toIso8601String(),
      'isDefault': isDefault,
    };
  }

  factory PairedDevice.fromMap(Map<String, dynamic> map) {
    return PairedDevice(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Windows PC',
      ip: map['ip'] as String? ?? '127.0.0.1',
      port: (map['port'] as num?)?.toInt() ?? 8765,
      token: map['token'] as String?,
      type: DeviceType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => DeviceType.desktop,
      ),
      lastConnected: map['lastConnected'] != null
          ? DateTime.tryParse(map['lastConnected'] as String) ?? DateTime.now()
          : DateTime.now(),
      isDefault: map['isDefault'] as bool? ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory PairedDevice.fromJson(String source) =>
      PairedDevice.fromMap(json.decode(source) as Map<String, dynamic>);
}
