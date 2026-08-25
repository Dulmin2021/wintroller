class HostSystemInfo {
  final String hostname;
  final String osVersion;
  final int batteryPercent;
  final bool isCharging;
  final int brightness;
  final int volume;
  final bool isMuted;
  final bool isMicMuted;
  final String? activeMediaTitle;
  final String? activeMediaArtist;
  final bool isPlaying;
  final double cpuUsage;
  final double ramUsage;
  final bool isWifiOn;
  final bool isBluetoothOn;
  final bool isDisplayOn;

  const HostSystemInfo({
    this.hostname = 'Windows PC',
    this.osVersion = 'Windows 11 Pro',
    this.batteryPercent = 85,
    this.isCharging = false,
    this.brightness = 75,
    this.volume = 40,
    this.isMuted = false,
    this.isMicMuted = false,
    this.activeMediaTitle,
    this.activeMediaArtist,
    this.isPlaying = false,
    this.cpuUsage = 18.5,
    this.ramUsage = 42.0,
    this.isWifiOn = true,
    this.isBluetoothOn = false,
    this.isDisplayOn = true,
  });

  HostSystemInfo copyWith({
    String? hostname,
    String? osVersion,
    int? batteryPercent,
    bool? isCharging,
    int? brightness,
    int? volume,
    bool? isMuted,
    bool? isMicMuted,
    String? activeMediaTitle,
    String? activeMediaArtist,
    bool? isPlaying,
    double? cpuUsage,
    double? ramUsage,
    bool? isWifiOn,
    bool? isBluetoothOn,
    bool? isDisplayOn,
  }) {
    return HostSystemInfo(
      hostname: hostname ?? this.hostname,
      osVersion: osVersion ?? this.osVersion,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      isCharging: isCharging ?? this.isCharging,
      brightness: brightness ?? this.brightness,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      isMicMuted: isMicMuted ?? this.isMicMuted,
      activeMediaTitle: activeMediaTitle ?? this.activeMediaTitle,
      activeMediaArtist: activeMediaArtist ?? this.activeMediaArtist,
      isPlaying: isPlaying ?? this.isPlaying,
      cpuUsage: cpuUsage ?? this.cpuUsage,
      ramUsage: ramUsage ?? this.ramUsage,
      isWifiOn: isWifiOn ?? this.isWifiOn,
      isBluetoothOn: isBluetoothOn ?? this.isBluetoothOn,
      isDisplayOn: isDisplayOn ?? this.isDisplayOn,
    );
  }

  factory HostSystemInfo.fromMap(Map<String, dynamic> map) {
    return HostSystemInfo(
      hostname: map['hostname'] as String? ?? 'Windows PC',
      osVersion: map['osVersion'] as String? ?? 'Windows 11',
      batteryPercent: (map['batteryPercent'] as num?)?.toInt() ?? 85,
      isCharging: map['isCharging'] as bool? ?? false,
      brightness: (map['brightness'] as num?)?.toInt() ?? 75,
      volume: (map['volume'] as num?)?.toInt() ?? 40,
      isMuted: map['isMuted'] as bool? ?? false,
      isMicMuted: map['isMicMuted'] as bool? ?? false,
      activeMediaTitle: map['activeMediaTitle'] as String?,
      activeMediaArtist: map['activeMediaArtist'] as String?,
      isPlaying: map['isPlaying'] as bool? ?? false,
      cpuUsage: (map['cpuUsage'] as num?)?.toDouble() ?? 15.0,
      ramUsage: (map['ramUsage'] as num?)?.toDouble() ?? 40.0,
      isWifiOn: map['isWifiOn'] as bool? ?? true,
      isBluetoothOn: map['isBluetoothOn'] as bool? ?? false,
      isDisplayOn: map['isDisplayOn'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hostname': hostname,
      'osVersion': osVersion,
      'batteryPercent': batteryPercent,
      'isCharging': isCharging,
      'brightness': brightness,
      'volume': volume,
      'isMuted': isMuted,
      'isMicMuted': isMicMuted,
      'activeMediaTitle': activeMediaTitle,
      'activeMediaArtist': activeMediaArtist,
      'isPlaying': isPlaying,
      'cpuUsage': cpuUsage,
      'ramUsage': ramUsage,
      'isWifiOn': isWifiOn,
      'isBluetoothOn': isBluetoothOn,
      'isDisplayOn': isDisplayOn,
    };
  }
}
