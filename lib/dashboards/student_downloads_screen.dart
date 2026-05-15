import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:math';
import '../services/api_service.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const _LessStretchyScrollPhysics(parent: AlwaysScrollableScrollPhysics()), 
        slivers: [
          // The SliverAppBar that contains the Storage widget and expands when dragged down
          SliverAppBar(
            backgroundColor: const Color(0xFFF4F7FC),
            elevation: 0,
            pinned: true,
            floating: false,
            stretch: false, 
            expandedHeight: 250.0,
            collapsedHeight: 60.0,
            title: const Text(
              "Downloads",
              style: TextStyle(color: Color(0xFF05398F), fontSize: 24, fontWeight: FontWeight.bold)
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded, color: Color(0xFF05398F)),
                onPressed: () {},
              ),
            ],
            // Regular flexible space for storage widget, appears on scroll to top
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildStorageStatus(),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
          
          // Sticky Filter Chips Below App Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _FilterHeaderDelegate(
              child: Container(
                color: const Color(0xFFF4F7FC),
                width: double.infinity,
                child: SingleChildScrollView(
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
                ),
              ),
            ),
          ),

          // Search Results / Download List grouped by Date
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                 _buildDateSection("December 21 2025"),
                 _buildDownloadFileTile("Compiler Design Lecture Note - 2.pdf", "8.14 MB", "Miraf M."),
                 _buildDownloadFileTile("Research Methods in Computer Scie...txt", "5.9 MB", "Muluken B."),
                 
                 const SizedBox(height: 15),
                 
                 _buildDateSection("January 23 2026"),
                 _buildDownloadFileTile("Complexity Classes Part 2 | NPC (N....mp4", "38.3 MB", "Dr. Debas"),
                 _buildDownloadFileTile("Image 02.png", "122 KB", "Abebe M."),
                 _buildDownloadFileTile("Complexity Theory.pptx", "4.4 MB", "Dr. Debas"),
                 
                 const SizedBox(height: 80), // Padding at bottom for navigation bar
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageStatus() {
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
            children: const [
               Text("Local Storage Used", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
               Icon(Icons.sd_storage_rounded, color: Colors.white70, size: 20)
            ],
          ),
          const SizedBox(height: 5),
          const Text("182 MB", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: 0.25, 
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            borderRadius: BorderRadius.circular(5),
            minHeight: 6,
          ),
          const SizedBox(height: 8),
          const Text("Saved for Offline Viewing", style: TextStyle(color: Colors.white60, fontSize: 11)),
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
      return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("No downloaded files found", style: TextStyle(color: Colors.black38))));
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
        style: const TextStyle(
          fontSize: 15, 
          fontWeight: FontWeight.bold, 
          color: Colors.black87
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

