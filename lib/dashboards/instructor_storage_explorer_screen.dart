import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';

class InstructorStorageExplorerScreen extends StatefulWidget {
  final List<dynamic>? initialFolders;
  final List<dynamic>? initialFiles;
  final String? initialFolderId;
  final String initialFolderName;

  const InstructorStorageExplorerScreen({
    super.key, 
    this.initialFolders, 
    this.initialFiles,
    this.initialFolderId,
    this.initialFolderName = 'Main Storage'
  });

  @override
  State<InstructorStorageExplorerScreen> createState() => _InstructorStorageExplorerScreenState();
}

class _InstructorStorageExplorerScreenState extends State<InstructorStorageExplorerScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  
  List<dynamic> _folders = [];
  List<dynamic> _files = [];
  
  // Navigation State
  late List<Map<String, String?>> _navigationStack;
  String? get _currentFolderId => _navigationStack.last['id'];
  String get _currentFolderName => _navigationStack.last['name']!;

  // Clipboard State
  List<Map<String, dynamic>>? _clipboard;
  
  // Selection State
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _navigationStack = [{'id': widget.initialFolderId, 'name': widget.initialFolderName}];
    if (widget.initialFolders != null && widget.initialFiles != null) {
      _folders = widget.initialFolders!;
      _files = widget.initialFiles!;
    } else {
      _fetchContent();
    }
  }

  Future<void> _fetchContent() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.getInstructorStorage(folderId: _currentFolderId);
      if (mounted) {
        setState(() {
          _folders = data['folders'] ?? [];
          _files = data['files'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void _navigateToFolder(String id, String name) {
    setState(() {
      _navigationStack.add({'id': id, 'name': name});
    });
    _fetchContent();
  }

  void _navigateBack() {
    if (_navigationStack.length > 1) {
      setState(() {
        _navigationStack.removeLast();
      });
      _fetchContent();
    } else {
      Navigator.pop(context);
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
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
      items.add({'id': parts[1], 'type': parts[0], 'mode': 'cut'});
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
      items.add({'id': parts[1], 'type': parts[0], 'mode': 'copy'});
    }
    setState(() {
      _clipboard = items;
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
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      )
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      for (final selectionId in _selectedIds) {
        final parts = selectionId.split(':');
        await _apiService.softDeleteEntry(parts[1], parts[0]);
      }
      _exitSelectionMode();
      _fetchContent();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$count items moved to recycle bin")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Delete failed: $e")));
      _fetchContent();
    }
  }

  Future<void> _pickAndUploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles();
      if (result != null) {
        setState(() => _isLoading = true);
        await _apiService.uploadInstructorFile(result.files.single.path!, folderId: _currentFolderId);
        _fetchContent();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
      setState(() => _isLoading = false);
    }
  }

  void _showNewFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Folder"),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: "Folder Name"), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                Navigator.pop(context);
                setState(() => _isLoading = true);
                try {
                  await _apiService.createFolder(controller.text, parentId: _currentFolderId);
                  _fetchContent();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: _isSelectionMode ? const Color(0xFF05398F) : const Color(0xFFF4F7FC),
        elevation: 0,
        leading: IconButton(
          icon: Icon(_isSelectionMode ? Icons.close_rounded : Icons.arrow_back_rounded, color: _isSelectionMode ? Colors.white : const Color(0xFF05398F)),
          onPressed: _isSelectionMode ? _exitSelectionMode : () => Navigator.pop(context),
        ),
        title: Text(
          _isSelectionMode ? "${_selectedIds.length} Selected" : "Storage Explorer",
          style: TextStyle(color: _isSelectionMode ? Colors.white : const Color(0xFF05398F), fontWeight: FontWeight.bold),
        ),
        actions: _isSelectionMode ? [
          IconButton(icon: const Icon(Icons.content_cut_rounded, color: Colors.white), onPressed: _handleMultiCut),
          IconButton(icon: const Icon(Icons.content_copy_rounded, color: Colors.white), onPressed: _handleMultiCopy),
          IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.white), onPressed: _deleteSelected),
          IconButton(
            icon: const Icon(Icons.select_all_rounded, color: Colors.white),
            onPressed: () {
              final total = _folders.length + _files.length;
              setState(() {
                if (_selectedIds.length == total) {
                  _selectedIds.clear();
                } else {
                  for (var f in _folders) _selectedIds.add("folder:${f['id']}");
                  for (var f in _files) _selectedIds.add("file:${f['id']}");
                }
              });
            },
          ),
        ] : [],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildBreadcrumbs(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (_folders.isEmpty && _files.isEmpty)
                      const Center(child: Padding(padding: EdgeInsets.only(top: 50), child: Text("This folder is empty", style: TextStyle(color: Colors.black38)))),
                    
                    ..._folders.map((folder) {
                      final id = "folder:${folder['id']}";
                      final isSelected = _selectedIds.contains(id);
                      return _buildTile(folder, 'folder', isSelected);
                    }),
                    ..._files.map((file) {
                      final id = "file:${file['id']}";
                      final isSelected = _selectedIds.contains(id);
                      return _buildTile(file, 'file', isSelected);
                    }),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "exp_upload",
            onPressed: _pickAndUploadFile,
            backgroundColor: const Color(0xFF09AEF5),
            child: const Icon(Icons.cloud_upload_rounded, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "exp_add",
            onPressed: _showNewFolderDialog,
            backgroundColor: const Color(0xFF09AEF5),
            child: const Icon(Icons.add_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          if (_navigationStack.length > 1) 
            IconButton(icon: const Icon(Icons.arrow_back_rounded, size: 20, color: Color(0xFF05398F)), onPressed: _navigateBack)
          else
            const Icon(Icons.storage_rounded, size: 20, color: Color(0xFF05398F)),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: Colors.black26, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(_currentFolderName, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF05398F)), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildTile(dynamic item, String type, bool isSelected) {
    String name = item['name'];
    String date = _formatDate(item['created_at']);
    String info = type == 'folder' ? "Items" : _formatBytes(item['file_size_bytes'] ?? 0);
    
    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection("${type}:${item['id']}");
        } else if (type == 'folder') {
          _navigateToFolder(item['id'].toString(), name);
        }
      },
      onLongPress: () => _toggleSelection("${type}:${item['id']}"),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? const Color(0xFF09AEF5) : Colors.transparent, width: 2),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))]
        ),
        child: Row(
          children: [
            if (isSelected) const Padding(padding: EdgeInsets.only(right: 12), child: Icon(Icons.check_circle_rounded, color: Color(0xFF09AEF5), size: 24)),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _getIconColor(name, type).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(_getIcon(name, type), color: _getIconColor(name, type), size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(date, style: const TextStyle(color: Colors.black38, fontSize: 11)),
                ],
              ),
            ),
            Text(info, style: const TextStyle(color: Colors.black38, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  IconData _getIcon(String name, String type) {
    if (type == 'folder') return Icons.folder_rounded;
    String ext = name.split('.').last.toLowerCase();
    if (ext == 'pdf') return Icons.picture_as_pdf_rounded;
    if (ext == 'mp4') return Icons.video_library_rounded;
    if (ext == 'jpg' || ext == 'png') return Icons.image_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Color _getIconColor(String name, String type) {
    if (type == 'folder') return const Color(0xFF09AEF5);
    String ext = name.split('.').last.toLowerCase();
    if (ext == 'pdf') return Colors.red;
    if (ext == 'mp4') return Colors.orange;
    if (ext == 'jpg' || ext == 'png') return Colors.green;
    return const Color(0xFF05398F);
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr).toLocal();
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _formatBytes(dynamic bytes) {
    int b = int.tryParse(bytes.toString()) ?? 0;
    if (b <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = (log(b) / log(1024)).floor();
    return ((b / pow(1024, i)).toStringAsFixed(1)) + ' ' + suffixes[i];
  }
}
