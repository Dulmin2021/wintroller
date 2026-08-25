import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/file_models.dart';
import '../../../theme/app_colors.dart';

class FileDetailSheet extends StatelessWidget {
  final RemoteFileItem file;
  final VoidCallback onDownload;

  const FileDetailSheet({
    super.key,
    required this.file,
    required this.onDownload,
  });

  IconData _getFileIcon() {
    final ext = (file.extension ?? '').toLowerCase();
    if (file.isDirectory) return Icons.folder_rounded;
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
      return Icons.image_rounded;
    }
    if (['mp4', 'mkv', 'avi', 'mov'].contains(ext)) {
      return Icons.video_file_rounded;
    }
    if (['mp3', 'wav', 'flac', 'aac'].contains(ext)) {
      return Icons.audio_file_rounded;
    }
    if (['pdf', 'doc', 'docx', 'txt'].contains(ext)) {
      return Icons.description_rounded;
    }
    if (['zip', 'rar', '7z', 'tar'].contains(ext)) {
      return Icons.folder_zip_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM d, yyyy • h:mm a').format(file.modifiedAt);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // File Icon & Name Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.filesAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getFileIcon(),
                  color: AppColors.filesAccent,
                  size: 36,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      file.formattedSize,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(color: AppColors.outlineVariant, height: 1),
          const SizedBox(height: 16),

          // File Info Rows
          _DetailRow(label: 'Path', value: file.path),
          const SizedBox(height: 10),
          _DetailRow(label: 'Last Modified', value: dateStr),
          const SizedBox(height: 10),
          _DetailRow(label: 'Type', value: file.isDirectory ? 'Directory' : (file.extension?.toUpperCase() ?? 'File')),

          const SizedBox(height: 28),

          // Actions Row
          if (!file.isDirectory) ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.filesAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.download_rounded),
                label: const Text(
                  'Download to Phone',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  onDownload();
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
