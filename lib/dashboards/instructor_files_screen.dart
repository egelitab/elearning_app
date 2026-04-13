import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class InstructorFilesScreen extends StatefulWidget {
  const InstructorFilesScreen({super.key});

  @override
  State<InstructorFilesScreen> createState() => _InstructorFilesScreenState();
}

class _InstructorFilesScreenState extends State<InstructorFilesScreen> {
  final ApiService _apiService = ApiService();
  bool isLocalSelected = true; 
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Documents', 'Videos', 'Images']; 
  
  // Storage State
  List<dynamic> _folders = [];
  List<dynamic> _files = [];
  List<dynamic> _recentFiles = [];
  Map<String, dynamic> _stats = {'total_size': 0};
  bool _isLoading = true;
  String? _error;
  
  // Navigation State
  List<Map<String, String?>> _navigationStack = [{'id': null, 'name': 'Main Storage'}];
  String? get _currentFolderId => _navigationStack.last['id'];
  String get _currentFolderName => _navigationStack.last['name']!;

  // Download State
  List<FileSystemEntity> _downloadedFiles = [];

  @override
  void initState() {
    super.initState();
    _fetchStorage();
    _loadDownloadedFiles();
  }

  Future<void> _fetchStorage() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getInstructorStorage(folderId: _currentFolderId);
      if (mounted) {
        setState(() {
          _folders = data['folders'] ?? [];
          _files = data['files'] ?? [];
          _recentFiles = data['recent'] ?? [];
          _stats = data['stats'] ?? {'total_size': 0};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadDownloadedFiles() async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final List<FileSystemEntity> files = directory.listSync();
        if (mounted) {
          setState(() {
            _downloadedFiles = files.where((f) => f is File).toList();
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading downloads: $e");
    }
  }

  void _navigateToFolder(String id, String name) {
    setState(() {
      _navigationStack.add({'id': id, 'name': name});
    });
    _fetchStorage();
  }

  void _navigateBack() {
    if (_navigationStack.length > 1) {
      setState(() {
        _navigationStack.removeLast();
      });
      _fetchStorage();
    }
  }

  Future<void> _pickAndUploadFile() async {
    FilePickerResult? result = await FilePicker.pickFiles();
    if (result != null) {
      setState(() => _isLoading = true);
      try {
        await _apiService.uploadInstructorFile(result.files.single.path!, folderId: _currentFolderId);
        _fetchStorage();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("File uploaded successfully!")));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
        setState(() => _isLoading = false);
      }
    }
  }

  void _showNewFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Folder"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Folder Name"),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                try {
                  await _apiService.createFolder(controller.text, parentId: _currentFolderId);
                  _fetchStorage();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                  setState(() => _isLoading = false);
                }
              }
            }, 
            child: const Text("Create")
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: const Color(0xFFF4F7FC),
                elevation: 0,
                pinned: true,
                title: const Text(
                  "My Files", 
                  style: const TextStyle(color: Color(0xFF05398F), fontSize: 24, fontWeight: FontWeight.bold)
                ),
                actions: [
                   IconButton(icon: const Icon(Icons.refresh_rounded, color: Color(0xFF05398F)), onPressed: _fetchStorage)
                ],
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildSearchBar(),
                    _buildStorageToggle(),
                    
                    if (isLocalSelected) ...[
                      const SizedBox(height: 10),
                      _buildRecentFilesSection(context),
                      const SizedBox(height: 15),
                      _buildStorageStatus(),
                      const SizedBox(height: 25),
                      _buildFolderHierarchyView(),
                    ] else ...[
                      _buildDownloadsFilters(),
                      _buildDownloadsList(),
                    ],
                    const SizedBox(height: 100), 
                  ],
                ),
              )
            ],
          ),
      floatingActionButton: Visibility(
        visible: isLocalSelected,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
              FloatingActionButton(
                heroTag: "upload_btn",
                onPressed: _pickAndUploadFile,
                backgroundColor: const Color(0xFF09AEF5),
                elevation: 4,
                child: const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 15),
              FloatingActionButton(
                heroTag: "add_btn",
                onPressed: _showNewFolderDialog,
                backgroundColor: const Color(0xFF09AEF5),
                elevation: 4,
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
              ),
            ],
          ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4)
            )
          ]
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: "Search your files...",
            hintStyle: const TextStyle(color: Colors.black38),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF05398F)),
            filled: true,
            fillColor: Colors.transparent,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStorageToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _toggleItem("Storage", isLocalSelected, () => setState(() => isLocalSelected = true)),
          _toggleItem("Downloads", !isLocalSelected, () => setState(() => isLocalSelected = false)),
        ],
      ),
    );
  }

  Widget _toggleItem(String title, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))] : [],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? const Color(0xFF05398F) : Colors.black54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentFilesSection(BuildContext context) {
    if (_recentFiles.isEmpty) return const SizedBox.shrink();
    double itemWidth = MediaQuery.of(context).size.width * 0.35;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Recent Files", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              Icon(Icons.keyboard_arrow_up_rounded, color: Colors.black45), 
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(left: 20, bottom: 20),
          child: Row(
            children: _recentFiles.map((file) => _buildRecentFileItem(
              file['name'], 
              _formatDate(file['created_at']), 
              itemWidth
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentFileItem(String name, String date, double width) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getColorForFile(name).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getIconForFile(name), color: _getColorForFile(name), size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: const TextStyle(color: Colors.black38, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildFolderHierarchyView() {
    return Column(
      children: [
        Container(
          height: 60,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (_navigationStack.length > 1) 
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF05398F)),
                  onPressed: _navigateBack,
                )
              else
                const Icon(Icons.home_rounded, color: Color(0xFF05398F), size: 22),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: Colors.black38, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _currentFolderName, 
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF05398F)),
                  overflow: TextOverflow.ellipsis
                )
              ),
              const Icon(Icons.more_horiz_rounded, color: Colors.black54),
            ],
          ),
        ),
        
        const SizedBox(height: 15),
        
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              if (_folders.isEmpty && _files.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text("This folder is empty", style: TextStyle(color: Colors.black38)),
                ),
              ..._folders.map((folder) => GestureDetector(
                onTap: () => _navigateToFolder(folder['id'].toString(), folder['name']),
                child: _buildImageFolderTile(
                  folder['name'], 
                  _formatDate(folder['created_at']), 
                  "0 items" 
                ),
              )),
              ..._files.map((file) => _buildImageFileTile(
                file['name'], 
                _formatDate(file['created_at']), 
                _formatBytes(int.tryParse(file['file_size_bytes'].toString()) ?? 0)
              )),
            ],
          ),
        ),
      ],
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();
    return ((bytes / pow(1024, i)).toStringAsFixed(1)) + ' ' + suffixes[i];
  }

  Widget _buildImageFolderTile(String name, String date, String itemCount) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.folder_rounded, color: Color(0xFF09AEF5), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(date, style: const TextStyle(color: Colors.black45, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Text(itemCount, style: const TextStyle(color: Colors.black38, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildImageFileTile(String name, String date, String size) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getColorForFile(name).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_getIconForFile(name), color: _getColorForFile(name), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(date, style: const TextStyle(color: Colors.black45, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Text(size, style: const TextStyle(color: Colors.black38, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
  Widget _buildDownloadsFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                color: isSelected ? const Color(0xFF09AEF5) : Colors.white,
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
                    color: isSelected ? Colors.white : Colors.black54,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14,
                  ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDownloadsList() {
    if (_downloadedFiles.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: Text("No downloaded files found on device", style: TextStyle(color: Colors.black38))),
      );
    }

    // Filter based on selected category simulation
    final filtered = _downloadedFiles.where((f) {
      if (_selectedFilter == 'All') return true;
      final name = f.path.toLowerCase();
      if (_selectedFilter == 'Documents') return name.contains('.pdf') || name.contains('.docx') || name.contains('.txt');
      if (_selectedFilter == 'Videos') return name.contains('.mp4') || name.contains('.avi');
      if (_selectedFilter == 'Images') return name.contains('.jpg') || name.contains('.png');
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: filtered.map((entity) {
          final file = entity as File;
          final stat = file.statSync();
          final name = file.path.split(Platform.pathSeparator).last;
          
          return _buildDownloadFileTile(
            name, 
            _formatBytes(stat.size), 
            "Local Device"
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateSection(String date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 10.0),
      child: Text(
        date, 
        style: const TextStyle(
          fontSize: 15, 
          fontWeight: FontWeight.bold, 
          color: Colors.black87
        )
      ),
    );
  }

  Widget _buildStorageStatus() {
    final int usedBytes = int.tryParse(_stats['total_size']?.toString() ?? '0') ?? 0;
    const int totalLimit = 1024 * 1024 * 1024; // 1 GB limit simulation
    final double progress = (usedBytes / totalLimit).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF09AEF5), Color(0xFF05398F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF05398F).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Text("Virtual Storage Used", style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
               const Icon(Icons.cloud_done_rounded, color: Colors.white70, size: 20)
            ],
          ),
          const SizedBox(height: 5),
          Text(_formatBytes(usedBytes), style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress, 
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            borderRadius: BorderRadius.circular(5),
            minHeight: 6,
          ),
          const SizedBox(height: 8),
          Text("of 1.0 GB used", style: const TextStyle(color: Colors.white60, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildDownloadFileTile(String name, String size, String author) {
    IconData icon = _getIconForFile(name);
    Color iconColor = _getColorForFile(name);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(size, style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    const Text("•", style: TextStyle(color: Colors.black38, fontSize: 12)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(author, style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.black38),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          )
        ],
      ),
    );
  }

  IconData _getIconForFile(String filename) {
    String ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf': return Icons.picture_as_pdf_rounded;
      case 'docx':
      case 'doc':
      case 'txt': return Icons.description_rounded;
      case 'mp4':
      case 'avi':
      case 'mov': return Icons.video_library_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png': return Icons.image_rounded;
      case 'zip':
      case 'rar': return Icons.archive_rounded;
      default: return Icons.insert_drive_file_rounded;
    }
  }

  Color _getColorForFile(String filename) {
    String ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf': return const Color(0xFFE91E63);
      case 'docx':
      case 'doc': return const Color(0xFF2196F3);
      case 'txt': return const Color(0xFF607D8B);
      case 'mp4':
      case 'avi': return const Color(0xFFFF9800);
      case 'jpg':
      case 'jpeg':
      case 'png': return const Color(0xFF4CAF50);
      case 'zip':
      case 'rar': return const Color(0xFF9C27B0);
      default: return const Color(0xFF05398F);
    }
  }
}