import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/file_models.dart';
import '../../providers/app_providers.dart';
import '../../services/websocket_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/alien_icons.dart';
import '../../widgets/hud_frame.dart';
import '../settings/settings_screen.dart';
import 'widgets/file_detail_sheet.dart';

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
    final colors = AppColors.of(context);
    final repo = ref.read(pcRemoteRepositoryProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading ${file.name}...'),
        backgroundColor: colors.surfaceContainerHigh,
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
              backgroundColor: colors.tertiaryContainer,
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save file: $e'),
            backgroundColor: colors.errorContainer,
          ),
        );
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: ${response.error ?? "Unknown error"}'),
          backgroundColor: colors.errorContainer,
        ),
      );
    }
  }

  Future<void> _uploadFile() async {
    final colors = AppColors.of(context);
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
        backgroundColor: colors.surfaceContainerHigh,
      ),
    );

    final response = await repo.uploadFile(_currentPath, bytes, file.name);

    if (response.success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Uploaded ${file.name} successfully'),
          backgroundColor: colors.tertiaryContainer,
        ),
      );
      _loadDirectory(_currentPath);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: ${response.error ?? "Unknown error"}'),
          backgroundColor: colors.errorContainer,
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
    final colors = AppColors.of(context);
    final themeStyle = ref.watch(themeStyleProvider);
    final isAlienHud = themeStyle == AppThemeStyle.alienHud;
    final connectionStatus = ref.watch(connectionStatusProvider).value ?? ConnectionStatus.offline;

    final filtered = _items.where((i) {
      if (_searchQuery.isEmpty) return true;
      return i.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.onSurface, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 6),
                      if (isAlienHud) const AlienEmblem(size: 30),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'WINTROLLER',
                              style: isAlienHud
                                  ? GoogleFonts.orbitron(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: colors.primary,
                                      letterSpacing: 2.0,
                                    )
                                  : TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                      color: colors.onSurface,
                                    ),
                            ),
                            Text(
                              isAlienHud ? 'ALIEN REMOTE INTERFACE' : 'File Explorer',
                              style: isAlienHud
                                  ? GoogleFonts.orbitron(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w700,
                                      color: colors.primary.withOpacity(0.7),
                                      letterSpacing: 1.5,
                                    )
                                  : TextStyle(
                                      fontSize: 12,
                                      color: colors.onSurfaceVariant,
                                    ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainer,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colors.primary, width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: connectionStatus == ConnectionStatus.connected
                                    ? colors.primary
                                    : colors.error,
                                boxShadow: [
                                  BoxShadow(color: colors.primary.withOpacity(0.8), blurRadius: 4),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              connectionStatus == ConnectionStatus.connected ? 'CONNECTED' : 'OFFLINE',
                              style: GoogleFonts.orbitron(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: connectionStatus == ConnectionStatus.connected
                                    ? colors.primary
                                    : colors.error,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Breadcrumb Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.primary.withOpacity(0.4), width: 0.8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.storage_rounded, color: colors.primary, size: 18),
                      const SizedBox(width: 8),
                      if (_currentPath != 'C:\\')
                        GestureDetector(
                          onTap: _navigateUp,
                          child: Icon(Icons.arrow_upward_rounded, color: colors.primary, size: 18),
                        ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text(
                            _currentPath.replaceAll('\\', ' / '),
                            style: GoogleFonts.shareTechMono(
                              fontSize: 13,
                              color: colors.primary,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colors.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.primary.withOpacity(0.4), width: 0.8),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: GoogleFonts.shareTechMono(color: colors.primary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'SEARCH_FILES_OR_FOLDERS...',
                        hintStyle: GoogleFonts.shareTechMono(
                          color: colors.primary.withOpacity(0.4),
                          fontSize: 12,
                          letterSpacing: 0.8,
                        ),
                        prefixIcon: Icon(Icons.search_rounded, color: colors.primary, size: 18),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear_rounded, color: colors.primary, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                ),

                // File Table List with NAME / SIZE / ACT Header
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: HudFrame(
                      chamferSize: 14,
                      borderColor: colors.primary,
                      backgroundColor: colors.surfaceContainer,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          // Table Header
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: Text(
                                    'NAME',
                                    style: GoogleFonts.shareTechMono(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: colors.onSurfaceVariant,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'SIZE',
                                    style: GoogleFonts.shareTechMono(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: colors.onSurfaceVariant,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                Text(
                                  'ACT',
                                  style: GoogleFonts.shareTechMono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: colors.onSurfaceVariant,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(color: colors.outlineVariant, height: 1),

                          // File List
                          Expanded(
                            child: _isLoading
                                ? Center(child: CircularProgressIndicator(color: colors.primary))
                                : filtered.isEmpty
                                    ? Center(
                                        child: Text(
                                          'NO_FILES_DETECTED',
                                          style: GoogleFonts.shareTechMono(
                                            color: colors.onSurfaceVariant,
                                            fontSize: 12,
                                          ),
                                        ),
                                      )
                                    : ListView.separated(
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        itemCount: filtered.length,
                                        separatorBuilder: (_, __) => Divider(
                                          color: colors.outlineVariant.withOpacity(0.4),
                                          height: 1,
                                        ),
                                        itemBuilder: (context, index) {
                                          final item = filtered[index];
                                          final icon = _getFileIcon(item);

                                          return InkWell(
                                            onTap: () {
                                              if (item.isDirectory) {
                                                _loadDirectory(item.path);
                                              } else {
                                                _openFileDetail(item);
                                              }
                                            },
                                            child: Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    icon,
                                                    color: colors.primary,
                                                    size: 18,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    flex: 6,
                                                    child: Text(
                                                      item.name,
                                                      style: GoogleFonts.shareTechMono(
                                                        fontSize: 12.5,
                                                        fontWeight: FontWeight.w600,
                                                        color: item.isDirectory
                                                            ? colors.primary
                                                            : colors.onSurface,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    flex: 3,
                                                    child: Text(
                                                      item.isDirectory ? '--' : item.formattedSize,
                                                      style: GoogleFonts.shareTechMono(
                                                        fontSize: 11,
                                                        color: colors.onSurfaceVariant,
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(Icons.more_vert_rounded, color: colors.primary, size: 18),
                                                    padding: EdgeInsets.zero,
                                                    constraints: const BoxConstraints(),
                                                    onPressed: () => _openFileDetail(item),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom Sci-Fi Cybernetic Dock
                if (isAlienHud)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: HudFrame(
                      chamferSize: 14,
                      borderColor: colors.primary,
                      backgroundColor: colors.surfaceContainer,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          IconButton(
                            icon: HudRadarCircle(
                              size: 24,
                              color: colors.primary,
                              child: Icon(Icons.gps_fixed_rounded, color: colors.primary, size: 12),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          IconButton(
                            icon: Icon(Icons.folder_open_rounded, color: colors.primary, size: 24),
                            onPressed: () {},
                          ),
                          GestureDetector(
                            onTap: _uploadFile,
                            child: HudRadarCircle(
                              size: 44,
                              color: colors.primary,
                              child: const AlienEmblem(size: 26, hasGlow: true),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.bar_chart_rounded, color: colors.primary, size: 24),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: Icon(Icons.settings_outlined, color: colors.primary, size: 24),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const SettingsScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Floating Glowing + Upload Button (matching bottom-right of screenshot)
            Positioned(
              right: 28,
              bottom: 80,
              child: GestureDetector(
                onTap: _uploadFile,
                child: Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.primary,
                    boxShadow: [
                      BoxShadow(
                        color: colors.primary.withOpacity(0.7),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.black,
                    size: 34,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
