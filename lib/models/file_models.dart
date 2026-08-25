class RemoteFileItem {
  final String name;
  final String path;
  final bool isDirectory;
  final int sizeBytes;
  final DateTime modifiedAt;
  final String? extension;

  const RemoteFileItem({
    required this.name,
    required this.path,
    required this.isDirectory,
    required this.sizeBytes,
    required this.modifiedAt,
    this.extension,
  });

  factory RemoteFileItem.fromMap(Map<String, dynamic> map) {
    return RemoteFileItem(
      name: map['name'] as String? ?? '',
      path: map['path'] as String? ?? '',
      isDirectory: map['isDirectory'] as bool? ?? false,
      sizeBytes: (map['sizeBytes'] as num?)?.toInt() ?? 0,
      modifiedAt: map['modifiedAt'] != null
          ? DateTime.tryParse(map['modifiedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      extension: map['extension'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'path': path,
      'isDirectory': isDirectory,
      'sizeBytes': sizeBytes,
      'modifiedAt': modifiedAt.toIso8601String(),
      'extension': extension,
    };
  }

  String get formattedSize {
    if (isDirectory) return 'Folder';
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

enum TransferDirection { upload, download }

class TransferProgress {
  final String id;
  final String fileName;
  final TransferDirection direction;
  final double progress; // 0.0 to 1.0
  final int transferredBytes;
  final int totalBytes;
  final bool isCompleted;
  final bool isCancelled;
  final String? error;

  const TransferProgress({
    required this.id,
    required this.fileName,
    required this.direction,
    required this.progress,
    required this.transferredBytes,
    required this.totalBytes,
    this.isCompleted = false,
    this.isCancelled = false,
    this.error,
  });

  TransferProgress copyWith({
    String? id,
    String? fileName,
    TransferDirection? direction,
    double? progress,
    int? transferredBytes,
    int? totalBytes,
    bool? isCompleted,
    bool? isCancelled,
    String? error,
  }) {
    return TransferProgress(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      direction: direction ?? this.direction,
      progress: progress ?? this.progress,
      transferredBytes: transferredBytes ?? this.transferredBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      isCompleted: isCompleted ?? this.isCompleted,
      isCancelled: isCancelled ?? this.isCancelled,
      error: error ?? this.error,
    );
  }
}
