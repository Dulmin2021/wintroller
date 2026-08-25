import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/file_models.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_colors.dart';
import 'widgets/file_detail_sheet.dart';
import 'widgets/file_transfer_sheet.dart';

class FileManagerScreen extends ConsumerStatefulWidget {
  const FileManagerScreen({super.key});

  @override
  ConsumerState<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends ConsumerState<FileManagerScreen> {
  String _currentPath = 'C:\\';
  List<RemoteFileItem> _items = [];
  bool _isLoading = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDirectory(_currentPath);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDirectory(String path) async {
    setState(() {
      _isLoading = true;
      _currentPath = path;
    });

    final repo = ref.read(pcRemoteRepositoryProvider);
    final items = await repo.listFiles(path);

    if (mounted) {
      setState(() {
        _items = items;
        _isLoading = false;
      });
    }
  }

  void _navigateUp() {
    if (_currentPath == 'C:\\' || _currentPath.isEmpty) return;
    final separator = _currentPath.contains('/') ? '/' : '\\';
    final parts = _currentPath.split(separator).where((p) => p.isNotEmpty).toList();
    if (parts.length <= 1) {
      _loadDirectory('C:\\');
    } else {
      parts.removeLast();
      _loadDirectory('${parts.join(separator)}$separator');
    }
  }

  void _openFileDetail(RemoteFileItem file) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => FileDetailSheet(
        file: file,
        onDownload: () => _downloadFile(file),
      ),
    );
  }

  Future<void> _downloadFile(RemoteFileItem file) async {
    final repo = ref.read(pcRemoteRepositoryProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${file.name}...'),
        backgroundColor: AppColors.surfaceContainerHigh,
      ),
    );

    final response = await repo.downloadFile(file.path);

    if (response.success && response.data != null) {
      try {
        final base64Content = response.data['data'] as String?;
        if (base64Content != null) {
          final bytes = base64Decode(base64Content);
          final dir = await getApplicationDocumentsDirectory();
          final localFile = File('${dir.path}/${file.name}');
          await localFile.writeAsBytes(bytes);

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Saved to ${localFile.path}'),
              backgroundColor: AppColors.tertiaryContainer,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save file: $e'),
            backgroundColor: AppColors.errorContainer,
          ),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: ${response.error ?? "Unknown error"}'),
          backgroundColor: AppColors.errorContainer,
        ),
      );
    }
  }

  Future<void> _uploadFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    Uint8List? bytes = file.bytes;
    if (bytes == null && file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    }

    if (bytes == null) return;

    final repo = ref.read(pcRemoteRepositoryProvider);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Uploading ${file.name}...'),
        backgroundColor: AppColors.surfaceContainerHigh,
      ),
    );

    final response = await repo.uploadFile(_currentPath, bytes, file.name);

    if (response.success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Uploaded ${file.name} successfully'),
          backgroundColor: AppColors.tertiaryContainer,
        ),
      );
      _loadDirectory(_currentPath);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: ${response.error ?? "Unknown error"}'),
          backgroundColor: AppColors.errorContainer,
        ),
      );
    }
  }

  IconData _getFileIcon(RemoteFileItem item) {
    if (item.isDirectory) return Icons.folder_rounded;
    final ext = (item.extension ?? '').toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext)) {
      return Icons.image_rounded;
    }
    if (['mp4', 'mkv', 'avi'].contains(ext)) return Icons.movie_rounded;
    if (['mp3', 'wav', 'flac'].contains(ext)) return Icons.music_note_rounded;
    if (['pdf', 'doc', 'docx', 'txt'].contains(ext)) return Icons.article_rounded;
    if (['zip', 'rar', '7z'].contains(ext)) return Icons.folder_zip_rounded;
    return Icons.insert_drive_file_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _items.where((i) {
      if (_searchQuery.isEmpty) return true;
      return i.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('File Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Directory',
            onPressed: () => _loadDirectory(_currentPath),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.filesAccent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.upload_file_rounded),
        label: const Text(
          'Upload File',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: _uploadFile,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: AppColors.onSurface),
                decoration: InputDecoration(
                  hintText: 'Search files and folders...',
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.filesAccent),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceContainer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.outlineVariant),
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),

            // Breadcrumb navigation header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.surfaceContainerLow,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_upward_rounded, size: 20),
                    tooltip: 'Parent Folder',
                    onPressed: _currentPath == 'C:\\' ? null : _navigateUp,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        _currentPath,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Quick Folder Access Shortcuts
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  _QuickPathChip(
                    label: 'C: Drive',
                    icon: Icons.storage_rounded,
                    onTap: () => _loadDirectory('C:\\'),
                  ),
                  const SizedBox(width: 8),
                  _QuickPathChip(
                    label: 'Downloads',
                    icon: Icons.download_rounded,
                    onTap: () => _loadDirectory('C:\\Users\\Default\\Downloads\\'),
                  ),
                  const SizedBox(width: 8),
                  _QuickPathChip(
                    label: 'Documents',
                    icon: Icons.folder_shared_rounded,
                    onTap: () => _loadDirectory('C:\\Users\\Default\\Documents\\'),
                  ),
                  const SizedBox(width: 8),
                  _QuickPathChip(
                    label: 'Desktop',
                    icon: Icons.desktop_windows_rounded,
                    onTap: () => _loadDirectory('C:\\Users\\Default\\Desktop\\'),
                  ),
                ],
              ),
            ),

            // Files & Folders List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.filesAccent),
                    )
                  : filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.folder_open_rounded,
                                size: 54,
                                color: AppColors.onSurfaceVariant.withOpacity(0.4),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No matches found'
                                    : 'Directory is empty',
                                style: const TextStyle(
                                  color: AppColors.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            final icon = _getFileIcon(item);

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  if (item.isDirectory) {
                                    _loadDirectory(item.path);
                                  } else {
                                    _openFileDetail(item);
                                  }
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Ink(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceContainer,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.outlineVariant.withOpacity(0.6),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: item.isDirectory
                                              ? AppColors.primaryContainer.withOpacity(0.15)
                                              : AppColors.filesAccent.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          icon,
                                          color: item.isDirectory
                                              ? AppColors.primaryContainer
                                              : AppColors.filesAccent,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.onSurface,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              item.formattedSize,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (item.isDirectory)
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: AppColors.onSurfaceVariant,
                                        )
                                      else
                                        IconButton(
                                          icon: const Icon(
                                            Icons.download_rounded,
                                            color: AppColors.filesAccent,
                                          ),
                                          onPressed: () => _downloadFile(item),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickPathChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickPathChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      backgroundColor: AppColors.surfaceContainerHigh,
      side: const BorderSide(color: AppColors.outlineVariant, width: 0.8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      avatar: Icon(icon, size: 16, color: AppColors.primary),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onSurface),
      ),
      onPressed: onTap,
    );
  }
}
