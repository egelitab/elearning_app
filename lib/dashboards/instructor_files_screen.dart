import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'account_settings_screen.dart';
import 'recycle_bin_screen.dart';
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

  // Clipboard/Move State
  List<Map<String, dynamic>>? _clipboard; // List of {id, type, mode: 'cut'|'copy'}
  
  // Selection State
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {}; // Format: "type:id"

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

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIds.add(id);
        _isSelectionMode = true;
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _handleMultiCut() {
    final List<Map<String, dynamic>> items = [];
    for (var selectionId in _selectedIds) {
      final parts = selectionId.split(':');
      final type = parts[0];
      final id = parts[1];
      items.add({'id': id, 'type': type, 'mode': 'cut'});
    }
    setState(() {
      _clipboard = items;
      _exitSelectionMode();
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${items.length} items cut to clipboard")));
  }

  void _handleMultiCopy() {
    final List<Map<String, dynamic>> items = [];
    for (var selectionId in _selectedIds) {
      final parts = selectionId.split(':');
      final type = parts[0];
      final id = parts[1];
      items.add({'id': id, 'type': type, 'mode': 'copy'});
    }
    setState(() {
      _clipboard = items; // Copy logic (soon)
      _exitSelectionMode();
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${items.length} items copied to clipboard")));
  }

  Future<void> _deleteSelected() async {
    final int count = _selectedIds.length;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Selected"),
        content: Text("Are you sure you want to move $count items to the recycle bin?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Delete", style: TextStyle(color: Colors.red))
          ),
        ],
      )
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      for (final selectionId in _selectedIds) {
        final parts = selectionId.split(':');
        final type = parts[0];
        final id = parts[1];
        
        await _apiService.softDeleteEntry(id, type);
      }
      _exitSelectionMode();
      _fetchStorage();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$count items moved to recycle bin")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
      _fetchStorage();
    }
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
    try {
      FilePickerResult? result = await FilePicker.pickFiles();
      if (result != null) {
        setState(() => _isLoading = true);
        await _apiService.uploadInstructorFile(result.files.single.path!, folderId: _currentFolderId);
        _fetchStorage();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("File uploaded successfully!")));
        }
      }
    } catch (e) {
      if (mounted) {
        String message = e.toString().contains("already exists") 
            ? "A file with this name already exists here."
            : "Upload failed: $e";
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
          TextButton(
            onPressed: () => Navigator.pop(context), 
            child: const Text("Cancel")
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                try {
                  await _apiService.createFolder(controller.text, parentId: _currentFolderId);
                  _fetchStorage();
                } catch (e) {
                  String message = e.toString().contains("already exists") 
                      ? "A folder with this name already exists here."
                      : "Error creating folder: $e";
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
                  setState(() => _isLoading = false);
                }
              }
            }, 
            child: const Text("Create")
          ),
        ],
      ),
    );
  }

  void _showEntryOptions(dynamic item, String type) {
    final bool isUploads = type == 'folder' && item['name'] == 'Uploads' && _currentFolderId == null;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isUploads) ...[
              _buildOptionTile(Icons.edit_rounded, "Rename", Colors.orange, () {
                Navigator.pop(context);
                _showRenameDialog(item, type);
              }),
              _buildOptionTile(Icons.content_cut_rounded, "Cut", Colors.blue, () {
                Navigator.pop(context);
                setState(() => _clipboard = [{'id': item['id'], 'type': type, 'mode': 'cut'}]);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Item cut to clipboard")));
              }),
              _buildOptionTile(Icons.content_copy_rounded, "Copy", Colors.blue, () {
                Navigator.pop(context);
                setState(() => _clipboard = [{'id': item['id'], 'type': type, 'mode': 'copy'}]);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Item copied to clipboard")));
              }),
            ],
            if (type == 'file') 
              _buildOptionTile(Icons.share_rounded, "Share", Colors.green, () {
                Navigator.pop(context);
                // Share logic
              }),
            if (!isUploads)
              _buildOptionTile(Icons.delete_outline_rounded, "Delete", Colors.red, () {
                Navigator.pop(context);
                _showDeleteWarning(item, type);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String title, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: onTap,
    );
  }

  void _showRenameDialog(dynamic item, String type) {
    final controller = TextEditingController(text: item['name']);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Rename ${type == 'folder' ? 'Folder' : 'File'}"),
        content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: "New Name")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty && controller.text != item['name']) {
                 Navigator.pop(context);
                 setState(() => _isLoading = true);
                 try {
                   await _apiService.renameEntry(item['id'].toString(), type, controller.text);
                   _fetchStorage();
                 } catch (e) {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Rename failed: $e")));
                   setState(() => _isLoading = false);
                 }
              }
            },
            child: const Text("Rename"),
          ),
        ],
      )
    );
  }

  void _showDeleteWarning(dynamic item, String type) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Move to Recycle Bin?"),
        content: Text("Are you sure you want to delete '${item['name']}'? It can be recovered from the Recycle Bin."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await _apiService.softDeleteEntry(item['id'].toString(), type);
                _fetchStorage();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
                setState(() => _isLoading = false);
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
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
                  backgroundColor: _isSelectionMode ? const Color(0xFF05398F) : const Color(0xFFF4F7FC),
                  elevation: 0,
                  pinned: true,
                  leading: _isSelectionMode 
                    ? IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white), onPressed: _exitSelectionMode)
                    : null,
                  title: Text(
                    _isSelectionMode ? "${_selectedIds.length} Selected" : "My Files", 
                    style: TextStyle(
                      color: _isSelectionMode ? Colors.white : const Color(0xFF05398F), 
                      fontSize: 20, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                  actions: _isSelectionMode ? [
                    IconButton(
                      icon: const Icon(Icons.content_cut_rounded, color: Colors.white),
                      onPressed: _handleMultiCut,
                      tooltip: "Cut",
                    ),
                    IconButton(
                        icon: const Icon(Icons.content_copy_rounded, color: Colors.white),
                        onPressed: _handleMultiCopy,
                        tooltip: "Copy",
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                      onPressed: _deleteSelected,
                      tooltip: "Delete",
                    ),
                    IconButton(
                      icon: const Icon(Icons.select_all_rounded, color: Colors.white),
                      onPressed: () {
                        final totalItems = _folders.length + _files.length;
                        setState(() {
                          if (_selectedIds.length == totalItems) {
                            _selectedIds.clear();
                            _isSelectionMode = false;
                          } else {
                            for (var f in _folders) { _selectedIds.add("folder:${f['id']}"); }
                            for (var f in _files) { _selectedIds.add("file:${f['id']}"); }
                          }
                        });
                      },
                    ),
                  ] : [
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
                onTap: _showAllRecentFiles,
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

  void _showAllRecentFiles() {
    // Group files by category
    Map<String, List<dynamic>> categories = {
      'Today': [],
      'This week': [],
      'This month': [],
      'Earlier': [],
    };

    final now = DateTime.now();
    for (var file in _recentFiles) {
      final date = DateTime.parse(file['created_at']);
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        categories['Today']!.add(file);
      } else if (diff.inDays < 7) {
        categories['This week']!.add(file);
      } else if (diff.inDays < 30) {
        categories['This month']!.add(file);
      } else {
        categories['Earlier']!.add(file);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Color(0xFFF4F7FC),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        ),
        child: Column(
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: Text("Recent Activity", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF05398F))),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: categories.entries.where((e) => e.value.isNotEmpty).expand((entry) => [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 0.5)),
                  ),
                  ...entry.value.map((file) => _buildImageFileTile(
                    file['name'], 
                    _getRelativeTime(file['created_at']), 
                    _formatBytes(int.tryParse(file['file_size_bytes'].toString()) ?? 0)
                  )),
                ]).toList(),
              ),
            ),
          ],
        ),
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
    if (diff.inDays < 7) return "${diff.inDays} days ago";
    if (diff.inDays < 30) return "${(diff.inDays / 7).floor()} weeks ago";
    return DateFormat('MMM dd, yyyy').format(date);
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
              if (_clipboard != null)
                IconButton(
                  icon: const Icon(Icons.paste_rounded, color: Colors.green),
                  tooltip: "Move here",
                  onPressed: _pasteItem,
                ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.sort_rounded, color: Color(0xFF05398F)),
                onSelected: (val) {
                  if (val == 'name_asc') {
                    setState(() {
                      _folders.sort((a, b) => a['name'].toString().toLowerCase().compareTo(b['name'].toString().toLowerCase()));
                      _files.sort((a, b) => a['name'].toString().toLowerCase().compareTo(b['name'].toString().toLowerCase()));
                    });
                  } else if (val == 'date_desc') {
                    setState(() {
                      _folders.sort((a, b) => b['created_at'].toString().compareTo(a['created_at'].toString()));
                      _files.sort((a, b) => b['created_at'].toString().compareTo(a['created_at'].toString()));
                    });
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'name_asc', 
                    child: Row(children: [Icon(Icons.sort_by_alpha_rounded, size: 20), SizedBox(width: 10), Text("Name (A-Z)")])
                  ),
                  const PopupMenuItem(
                    value: 'date_desc', 
                    child: Row(children: [Icon(Icons.calendar_today_rounded, size: 20), SizedBox(width: 10), Text("Date (Newest)")])
                  ),
                ],
              ),
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
              ..._folders.map((folder) {
                final bool isUploads = folder['name'] == 'Uploads' && _currentFolderId == null;
                final String selectionId = "folder:${folder['id']}";
                final bool isSelected = _selectedIds.contains(selectionId);

                return GestureDetector(
                  onLongPress: () {
                    _toggleSelection(selectionId);
                  },
                  child: _buildImageFolderTile(
                    folder['name'], 
                    _formatDate(folder['created_at']), 
                    "0 items",
                    isSystemFolder: isUploads,
                    isSelected: isSelected,
                    onOptions: () => _showEntryOptions(folder, 'folder'),
                  ),
                );
              }),
              ..._files.map((file) {
                final String selectionId = "file:${file['id']}";
                final bool isSelected = _selectedIds.contains(selectionId);

                return GestureDetector(
                  onTap: () {
                    if (_isSelectionMode) {
                      _toggleSelection(selectionId);
                    }
                  },
                  onLongPress: () {
                    _toggleSelection(selectionId);
                  },
                  child: _buildImageFileTile(
                    file['name'], 
                    _formatDate(file['created_at']), 
                    _formatBytes(int.tryParse(file['file_size_bytes'].toString()) ?? 0),
                    isSelected: isSelected,
                    onOptions: () => _showEntryOptions(file, 'file'),
                  ),
                );
              }),
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

  Future<void> _pasteItem() async {
    if (_clipboard == null || _clipboard!.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      for (var item in _clipboard!) {
        await _apiService.moveEntry(
          item['id'].toString(), 
          item['type'], 
          _currentFolderId
        );
      }
      setState(() => _clipboard = null);
      _fetchStorage();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Items moved successfully")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Move failed: $e")));
      setState(() => _isLoading = false);
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.sort_by_alpha_rounded),
            title: const Text("Name (A-Z)"),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _folders.sort((a, b) => a['name'].toString().toLowerCase().compareTo(b['name'].toString().toLowerCase()));
                _files.sort((a, b) => a['name'].toString().toLowerCase().compareTo(b['name'].toString().toLowerCase()));
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today_rounded),
            title: const Text("Date (Newest)"),
            onTap: () {
              Navigator.pop(context);
              setState(() {
                _folders.sort((a, b) => b['created_at'].toString().compareTo(a['created_at'].toString()));
                _files.sort((a, b) => b['created_at'].toString().compareTo(a['created_at'].toString()));
              });
            },
          ),
        ],
      ),
    );
  }


  Widget _buildImageFolderTile(String name, String date, String itemCount, {bool isSystemFolder = false, bool isSelected = false, VoidCallback? onOptions}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isSelected ? Border.all(color: const Color(0xFF09AEF5), width: 2) : Border.all(color: Colors.transparent, width: 2),
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
          if (isSelected) 
            const Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.check_circle_rounded, color: Color(0xFF09AEF5), size: 24)),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSystemFolder ? const Color(0xFFE8F5E9) : const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isSystemFolder ? Icons.folder_shared_rounded : Icons.folder_rounded, 
              color: isSystemFolder ? Colors.green : const Color(0xFF09AEF5), 
              size: 28
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                    if (isSystemFolder) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.lock_rounded, size: 14, color: Colors.black26),
                    ]
                  ],
                ),
                const SizedBox(height: 4),
                Text(date, style: const TextStyle(color: Colors.black45, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (onOptions != null && !isSelected)
            IconButton(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.black38),
              onPressed: onOptions,
            )
          else
            Text(itemCount, style: const TextStyle(color: Colors.black38, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildImageFileTile(String name, String date, String size, {bool isSelected = false, VoidCallback? onOptions}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isSelected ? Border.all(color: const Color(0xFF09AEF5), width: 2) : Border.all(color: Colors.transparent, width: 2),
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
          if (isSelected) 
            const Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.check_circle_rounded, color: Color(0xFF09AEF5), size: 24)),
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
          if (onOptions != null && !isSelected)
            IconButton(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.black38),
              onPressed: onOptions,
            )
          else
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