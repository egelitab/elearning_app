import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'recycle_bin_screen.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'instructor_storage_explorer_screen.dart';

class InstructorFilesScreen extends StatefulWidget {
  final bool showToggle;
  final bool startInDownloads;

  const InstructorFilesScreen({
    super.key, 
    this.showToggle = true,
    this.startInDownloads = false,
  });

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
  
  // Download State
  List<FileSystemEntity> _downloadedFiles = [];

  @override
  void initState() {
    super.initState();
    isLocalSelected = widget.startInDownloads == false; // Reversed logic: if startInDownloads is true, isLocalSelected should be false
    _fetchStorage();
    _loadDownloadedFiles();
  }

  Future<void> _fetchStorage() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getInstructorStorage(folderId: null);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _error != null
          ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text("Error: $_error", style: const TextStyle(color: Colors.red)),
                TextButton(onPressed: _fetchStorage, child: const Text("Retry"))
              ],
            ))
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: const Color(0xFFF4F7FC),
                  elevation: 0,
                  pinned: true,
                  title: Text(
                    (widget.showToggle == false && widget.startInDownloads == true) ? "Downloads" : "My Files", 
                    style: const TextStyle(
                      color: Color(0xFF05398F), 
                      fontSize: 22, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                  actions: [
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF05398F)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      onSelected: (val) async {
                        if (val == 'recycle') {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RecycleBinScreen()),
                          );
                          if (result == true) _fetchStorage();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'recycle',
                          child: Row(children: [Icon(Icons.delete_outline_rounded, size: 20), SizedBox(width: 10), Text("Recycle Bin")])
                        ),
                      ],
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildSearchBar(),
                      if (widget.showToggle == true)
                        _buildStorageToggle(),
                      
                      if (isLocalSelected) ...[
                        const SizedBox(height: 10),
                        _buildRecentFilesSection(context),
                        const SizedBox(height: 15),
                        _buildStorageStatus(),
                        const SizedBox(height: 40),
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
    double itemWidth = MediaQuery.of(context).size.width * 0.28;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Recent Files", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => InstructorStorageExplorerScreen(initialFolders: _folders, initialFiles: _files)));
                },
                child: const Icon(Icons.keyboard_arrow_right_rounded, color: Colors.black45), 
              ),
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
              _getRelativeTime(file['created_at']), 
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
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getColorForFile(name).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_getIconForFile(name), color: _getColorForFile(name), size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            maxLines: 1,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black38, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _getRelativeTime(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return "${diff.inMinutes} mins ago";
    if (diff.inHours < 24) return "${diff.inHours} hrs ago";
    if (diff.inDays == 1) return "Yesterday";
    return DateFormat('MMM dd, yyyy').format(date);
  }

  Widget _buildStorageStatus() {
    final int usedBytes = int.tryParse(_stats['total_size']?.toString() ?? '0') ?? 0;
    const int totalLimit = 1024 * 1024 * 1024; 
    final double progress = (usedBytes / totalLimit).clamp(0.0, 1.0);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => InstructorStorageExplorerScreen(initialFolders: _folders, initialFiles: _files))).then((_) => _fetchStorage());
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF09AEF5), Color(0xFF05398F)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: const Color(0xFF05398F).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 const Text("Virtual Storage Used", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                 const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16)
              ],
            ),
            const SizedBox(height: 8),
            Text(_formatBytes(usedBytes), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress, 
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              borderRadius: BorderRadius.circular(10),
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            const Text("Tap to explore and manage your files", style: TextStyle(color: Colors.white70, fontSize: 12, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (log(bytes) / log(1024)).floor();
    return ((bytes / pow(1024, i)).toStringAsFixed(1)) + ' ' + suffixes[i];
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
            onTap: () => setState(() => _selectedFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF09AEF5) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Text(filter, style: TextStyle(color: isSelected ? Colors.white : Colors.black54, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, fontSize: 14)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDownloadsList() {
    if (_downloadedFiles.isEmpty) {
      return const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text("No downloaded files found", style: TextStyle(color: Colors.black38))));
    }
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
        children: filtered.map((entity) {
          final file = entity as File;
          final name = file.path.split(Platform.pathSeparator).last;
          return _buildDownloadFileTile(name, _formatBytes(file.lengthSync()), "Local Device");
        }).toList(),
      ),
    );
  }

  Widget _buildDownloadFileTile(String name, String size, String author) {
    IconData icon = _getIconForFile(name);
    Color iconColor = _getColorForFile(name);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))]),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: iconColor.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 24)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis), Text("$size • $author", style: const TextStyle(color: Colors.black38, fontSize: 12))])),
          const Icon(Icons.more_vert_rounded, color: Colors.black26),
        ],
      ),
    );
  }

  IconData _getIconForFile(String name) {
    String ext = name.split('.').last.toLowerCase();
    if (ext == 'pdf') return Icons.picture_as_pdf_rounded;
    if (ext == 'mp4') return Icons.video_library_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color _getColorForFile(String name) {
    String ext = name.split('.').last.toLowerCase();
    if (ext == 'pdf') return Colors.red;
    if (ext == 'mp4') return Colors.orange;
    return const Color(0xFF05398F);
  }
}