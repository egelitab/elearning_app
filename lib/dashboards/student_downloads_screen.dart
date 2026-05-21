import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:math';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../main.dart';

class StudentDownloadsScreen extends StatefulWidget {
  const StudentDownloadsScreen({super.key});

  @override
  State<StudentDownloadsScreen> createState() => _StudentDownloadsScreenState();
}

class _StudentDownloadsScreenState extends State<StudentDownloadsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Documents', 'Videos', 'Images'];
  late ScrollController _scrollController;
  List<FileSystemEntity> _downloadedFiles = [];
  bool _isLoading = true;
  final Set<String> _selectedFilePaths = {};
  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _loadDownloadedFiles();
  }

  Future<void> _loadDownloadedFiles() async {
    setState(() => _isLoading = true);
    try {
      Directory directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download/ELMS');
      } else {
        directory = Directory('${(await getApplicationDocumentsDirectory()).path}/ELMS');
      }

      if (await directory.exists()) {
        final List<FileSystemEntity> files = directory.listSync();
        if (mounted) {
          setState(() {
            _downloadedFiles = files.where((f) => f is File).toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _downloadedFiles = [];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading downloads: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();
    return ((bytes / pow(1024, i)).toStringAsFixed(1)) + ' ' + suffixes[i];
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isSelectionMode = _selectedFilePaths.isNotEmpty;

    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDark, _) => Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: isSelectionMode ? const Color(0xFF05398F) : AppColors.appBar,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: isSelectionMode 
          ? IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => setState(() => _selectedFilePaths.clear()),
            )
          : _isSearching
            ? IconButton(
                icon: Icon(Icons.arrow_back_rounded, color: AppColors.appBarForeground),
                onPressed: () => setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                }),
              )
            : null,
        title: isSelectionMode 
          ? Text("${_selectedFilePaths.length} Selected", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))
          : _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: "Search files...",
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppColors.secondaryText),
                ),
                style: TextStyle(color: AppColors.primaryText, fontSize: 18, fontWeight: FontWeight.w600),
              )
            : Text(
                "Downloads",
                style: TextStyle(color: AppColors.appBarForeground, fontSize: 24, fontWeight: FontWeight.bold)
              ),
        actions: [
          if (isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
              onPressed: _deleteSelectedFiles,
            )
          else if (_isSearching)
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Color(0xFF05398F)),
              onPressed: () => setState(() {
                _searchQuery = '';
                _searchController.clear();
              }),
            )
          else
            IconButton(
              icon: Icon(Icons.search_rounded, color: AppColors.appBarForeground),
              onPressed: () => setState(() => _isSearching = true),
            ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: _filters.map((filter) {
                  bool isSelected = _selectedFilter == filter;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF09AEF5) : AppColors.card,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.white : AppColors.secondaryText,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Download List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _isLoading 
                ? const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                : _buildFileList(),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    ),
  );
}

  Future<void> _deleteSelectedFiles() async {
    final count = _selectedFilePaths.length;
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Files"),
        content: Text("Are you sure you want to delete $count selected files?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("DELETE", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      for (String path in _selectedFilePaths) {
        try {
          final file = File(path);
          if (await file.exists()) await file.delete();
        } catch (e) {
          debugPrint("Error deleting file $path: $e");
        }
      }
      setState(() {
        _selectedFilePaths.clear();
      });
      _loadDownloadedFiles();
    }
  }

  Widget _buildFileList() {
    final filteredFiles = _downloadedFiles.where((f) {
      final name = f.path.split(Platform.pathSeparator).last.toLowerCase();
      final queryMatch = name.contains(_searchQuery.toLowerCase());
      if (!queryMatch) return false;

      if (_selectedFilter == 'All') return true;
      String ext = f.path.split('.').last.toLowerCase();
      if (_selectedFilter == 'Documents') return ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx', 'ppt', 'pptx'].contains(ext);
      if (_selectedFilter == 'Videos') return ['mp4', 'avi', 'mov'].contains(ext);
      if (_selectedFilter == 'Images') return ['jpg', 'jpeg', 'png', 'gif'].contains(ext);
      return false;
    }).toList();

    if (filteredFiles.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(40), child: Text("No downloaded files found", style: TextStyle(color: AppColors.secondaryText))));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredFiles.length,
      itemBuilder: (context, index) {
        final file = filteredFiles[index] as File;
        final name = file.path.split(Platform.pathSeparator).last;
        return _buildDownloadFileTile(
          name, 
          _formatBytes(file.lengthSync()), 
          "Local Device",
          file.path,
        );
      },
    );
  }


  Widget _buildDateSection(String date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 10.0),
      child: Text(
        date, 
        style: TextStyle(
          fontSize: 15, 
          fontWeight: FontWeight.bold, 
          color: AppColors.primaryText
        )
      ),
    );
  }

  Widget _buildDownloadFileTile(String name, String size, String author, String path) {
    IconData icon = _getIconForFile(name);
    Color iconColor = _getColorForFile(name);
    bool isSelected = _selectedFilePaths.contains(path);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF09AEF5).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: isSelected ? Border.all(color: const Color(0xFF09AEF5), width: 1.5) : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onLongPress: () {
          setState(() {
            if (isSelected) {
              _selectedFilePaths.remove(path);
            } else {
              _selectedFilePaths.add(path);
            }
          });
        },
        onTap: () async {
          if (_selectedFilePaths.isNotEmpty) {
            setState(() {
              if (isSelected) {
                _selectedFilePaths.remove(path);
              } else {
                _selectedFilePaths.add(path);
              }
            });
            return;
          }
          try {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Opening file...")));
            final api = ApiService();
            await api.downloadAndOpenFile(path, context: context, fileName: name);
          } catch (e) {
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF09AEF5) : iconColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isSelected ? Icons.check_rounded : icon, 
                      color: isSelected ? Colors.white : iconColor, 
                      size: 24
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryText), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(size, style: TextStyle(color: AppColors.secondaryText, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Text("•", style: TextStyle(color: AppColors.secondaryText, fontSize: 12)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(author, style: TextStyle(color: AppColors.secondaryText, fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle_rounded, color: Color(0xFF09AEF5), size: 24),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForFile(String name) {
    String ext = name.toLowerCase().split('.').last;
    if (ext.contains('pdf')) return Icons.picture_as_pdf_rounded;
    if (ext.contains('doc') || ext.contains('txt')) return Icons.description_rounded;
    if (ext.contains('mp4') || ext.contains('avi') || ext.contains('mov')) return Icons.video_collection_rounded;
    if (ext.contains('zip') || ext.contains('rar') || ext.contains('7z')) return Icons.folder_zip_rounded;
    if (ext.contains('jpg') || ext.contains('jpeg') || ext.contains('png') || ext.contains('gif')) return Icons.image_rounded;
    if (ext.contains('ppt') || ext.contains('pptx')) return Icons.slideshow_rounded;
    if (ext.contains('xls') || ext.contains('xlsx') || ext.contains('csv')) return Icons.table_chart_rounded;
    if (ext.contains('mp3') || ext.contains('wav') || ext.contains('aac')) return Icons.audiotrack_rounded;
    
    return Icons.insert_drive_file_rounded;
  }

  Color _getColorForFile(String name) {
    String ext = name.toLowerCase().split('.').last;
    if (ext.contains('pdf')) return Colors.red.shade600;
    if (ext.contains('doc') || ext.contains('txt')) return Colors.blue.shade700;
    if (ext.contains('mp4') || ext.contains('avi') || ext.contains('mov')) return Colors.deepPurple;
    if (ext.contains('zip') || ext.contains('rar') || ext.contains('7z')) return Colors.orange.shade800;
    if (ext.contains('jpg') || ext.contains('jpeg') || ext.contains('png') || ext.contains('gif')) return Colors.teal;
    if (ext.contains('ppt') || ext.contains('pptx')) return Colors.orange.shade900;
    if (ext.contains('xls') || ext.contains('xlsx') || ext.contains('csv')) return Colors.green.shade700;
    if (ext.contains('mp3') || ext.contains('wav') || ext.contains('aac')) return Colors.pink.shade400;

    return Colors.blueGrey;
  }
}

