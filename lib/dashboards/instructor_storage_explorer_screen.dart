import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class InstructorStorageExplorerScreen extends StatefulWidget {
  final List<dynamic>? initialFolders;
  final List<dynamic>? initialFiles;
  final String? initialFolderId;
  final String initialFolderName;
  final bool isPicker;

  const InstructorStorageExplorerScreen({
    super.key, 
    this.initialFolders, 
    this.initialFiles,
    this.initialFolderId,
    this.initialFolderName = 'Main Storage',
    this.isPicker = false,
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

  // For Sharing
  List<dynamic> _courses = [];
  List<dynamic> _targets = [];
  @override
  void initState() {
    super.initState();
    _navigationStack = [{'id': widget.initialFolderId, 'name': widget.initialFolderName}];
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    try {
      final List<Future> futures = [];
      int? storageIndex;
      int? coursesIndex;
      int? targetsIndex;

      if (widget.initialFolders == null) {
        storageIndex = futures.length;
        futures.add(_apiService.getInstructorStorage(folderId: _currentFolderId));
      }
      
      coursesIndex = futures.length;
      futures.add(_apiService.getInstructorCourses());
      
      targetsIndex = futures.length;
      futures.add(_apiService.getInstructorTargets());

      final results = await Future.wait(futures);

      if (storageIndex != null) {
        final storageData = results[storageIndex] as Map<String, dynamic>;
        _folders = storageData['folders'] ?? [];
        _files = storageData['files'] ?? [];
      } else {
        _folders = widget.initialFolders ?? [];
        _files = widget.initialFiles ?? [];
      }
      
      _courses = results[coursesIndex] as List<dynamic>;
      _targets = results[targetsIndex] as List<dynamic>;
      
      _applySort('name_asc'); // Pin and sort
    } catch (e) {
      debugPrint("Init error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          
          _applySort('name_asc'); // Default sort
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

  void _navigateToBreadcrumb(int index) {
    if (index < 0 || index >= _navigationStack.length - 1) return;
    setState(() {
      _navigationStack = _navigationStack.sublist(0, index + 1);
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

  void _toggleSelection(String id, {bool isSystem = false}) {
    if (isSystem) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("The Uploads folder cannot be modified or moved.")));
      return;
    }
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

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Sort By", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF05398F))),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.text_format_rounded, color: Color(0xFF09AEF5)),
              title: const Text("Name"),
              onTap: () {
                _applySort('name_asc');
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today_rounded, color: Color(0xFF09AEF5)),
              title: const Text("Date Modified"),
              onTap: () {
                _applySort('date_desc');
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
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
      String name = '';
      try {
        if (type == 'folder') {
          name = _folders.firstWhere((f) => f['id'].toString() == id)['name'];
        } else {
          name = _files.firstWhere((f) => f['id'].toString() == id)['name'];
        }
      } catch (e) { name = 'Unknown'; }
      items.add({
        'id': id, 
        'type': type, 
        'name': name, 
        'mode': 'cut',
        'source_folder_id': _currentFolderId
      });
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
      String name = '';
      try {
        if (type == 'folder') {
          name = _folders.firstWhere((f) => f['id'].toString() == id)['name'];
        } else {
          name = _files.firstWhere((f) => f['id'].toString() == id)['name'];
        }
      } catch (e) { name = 'Unknown'; }
      items.add({
        'id': id, 
        'type': type, 
        'name': name, 
        'mode': 'copy',
        'source_folder_id': _currentFolderId
      });
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

  void _showRenameDialog() {
    if (_selectedIds.length != 1) return;
    
    final idStr = _selectedIds.first;
    final parts = idStr.split(':');
    final type = parts[0];
    final id = parts[1];
    
    // Find item name
    String currentName = '';
    if (type == 'folder') {
      currentName = _folders.firstWhere((f) => f['id'].toString() == id)['name'];
    } else {
      currentName = _files.firstWhere((f) => f['id'].toString() == id)['name'];
    }

    // Split name and extension for files
    String base = currentName;
    String ext = '';
    if (type == 'file') {
      int dotIndex = currentName.lastIndexOf('.');
      if (dotIndex > 0 && dotIndex < currentName.length - 1) {
        base = currentName.substring(0, dotIndex);
        ext = currentName.substring(dotIndex);
      }
    }

    final controller = TextEditingController(text: base);
    // Auto-select the name part so the user can immediately overwrite it
    controller.selection = TextSelection(baseOffset: 0, extentOffset: base.length);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Rename ${type == 'folder' ? 'Folder' : 'File'}"),
        content: TextField(
          controller: controller, 
          autofocus: true, 
          decoration: InputDecoration(
            hintText: "New Name",
            suffixText: ext.isNotEmpty ? ext : null,
            suffixStyle: const TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final newBase = controller.text.trim();
              if (newBase.isNotEmpty && (newBase != base || ext.isNotEmpty)) {
                final fullName = newBase + ext;
                Navigator.pop(context);
                setState(() => _isLoading = true);
                try {
                  await _apiService.renameEntry(id, type, fullName);
                  _exitSelectionMode();
                  _fetchContent();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Rename failed: $e")));
                  setState(() => _isLoading = false);
                }
              }
            }, 
            child: const Text("Rename"),
          ),
        ],
      ),
    );
  }

  String _incrementName(String name, String type) {
    if (type == 'folder') {
      // Folders treat dots as part of the name, not extensions
      final regex = RegExp(r'_(\d+)$');
      final match = regex.firstMatch(name);
      if (match != null) {
        int num = int.parse(match.group(1)!) + 1;
        String base = name.substring(0, match.start);
        return "${base}_$num";
      } else {
        return "${name}_1";
      }
    }

    // For files, separate the extension accurately
    int dotIndex = name.lastIndexOf('.');
    // If no dot, or dot is first char (hidden file), or dot is last char
    if (dotIndex <= 0 || dotIndex == name.length - 1) {
      final regex = RegExp(r'_(\d+)$');
      final match = regex.firstMatch(name);
      if (match != null) {
        int num = int.parse(match.group(1)!) + 1;
        String base = name.substring(0, match.start);
        return "${base}_$num";
      } else {
        return "${name}_1";
      }
    }

    String base = name.substring(0, dotIndex);
    String ext = name.substring(dotIndex);
    
    final regex = RegExp(r'_(\d+)$');
    final match = regex.firstMatch(base);
    if (match != null) {
      int num = int.parse(match.group(1)!) + 1;
      base = base.substring(0, match.start);
      return "${base}_$num$ext";
    } else {
      return "${base}_1$ext";
    }
  }

  void _applySort(String criteria) {
    setState(() {
      _folders.sort((a, b) {
        // Always Pin Uploads to the very top
        String nameA = a['name'].toString().trim().toLowerCase();
        String nameB = b['name'].toString().trim().toLowerCase();

        if (nameA == 'uploads' && nameB != 'uploads') return -1;
        if (nameB == 'uploads' && nameA != 'uploads') return 1;
        
        if (criteria == 'name_asc') {
          return a['name'].toString().toLowerCase().compareTo(b['name'].toString().toLowerCase());
        } else if (criteria == 'date_desc') {
          return b['created_at'].toString().compareTo(a['created_at'].toString());
        }
        return 0;
      });

      _files.sort((a, b) {
        if (criteria == 'name_asc') {
          return a['name'].toString().toLowerCase().compareTo(b['name'].toString().toLowerCase());
        } else if (criteria == 'date_desc') {
          return b['created_at'].toString().compareTo(a['created_at'].toString());
        }
        return 0;
      });
    });
  }

  Future<void> _pasteItems() async {
    if (_clipboard == null || _clipboard!.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final List<Map<String, dynamic>> clipboardCopy = List.from(_clipboard!);
      
      for (var item in clipboardCopy) {
        // Optimization: If pasting in same folder during CUT, it's a no-op
        if (item['mode'] == 'cut' && item['source_folder_id'] == _currentFolderId) {
          continue;
        }

        String baseName = item['name'];
        String newName = baseName;

        // Auto-resolve conflicts by incrementing name until unique
        while (_folders.any((f) => f['name'] == newName) || _files.any((f) => f['name'] == newName)) {
          newName = _incrementName(newName, item['type']);
        }

        if (item['mode'] == 'copy') {
          await _apiService.duplicateEntry(item['id'], item['type'], _currentFolderId, newName: newName);
        } else {
          // Cut mode: Rename if name was changed, then move
          if (newName != baseName) {
            await _apiService.renameEntry(item['id'], item['type'], newName);
          }
          await _apiService.moveEntry(item['id'], item['type'], _currentFolderId);
        }
      }

      setState(() => _clipboard = null);
      _fetchContent();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Items placed successfully")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Paste failed: $e")));
      _fetchContent();
    }
  }

  void _showNewFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        String? errorText;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("New Folder"),
              content: TextField(
                controller: controller, 
                autofocus: true,
                onChanged: (val) {
                  if (errorText != null) setDialogState(() => errorText = null);
                },
                decoration: InputDecoration(
                  hintText: "Folder Name",
                  errorText: errorText,
                  errorMaxLines: 2,
                ), 
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () async {
                    if (controller.text.isNotEmpty) {
                      final String folderName = controller.text;
                      // Check for duplicate name
                      if (_folders.any((f) => f['name'].toString().toLowerCase() == folderName.toLowerCase()) || 
                          _files.any((f) => f['name'].toString().toLowerCase() == folderName.toLowerCase())) {
                        setDialogState(() => errorText = "A folder or file with this name already exists.");
                        return;
                      }

                      Navigator.pop(context);
                      setState(() => _isLoading = true);
                      try {
                        await _apiService.createFolder(folderName, parentId: _currentFolderId);
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
            );
          }
        );
      },
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
          if (_selectedIds.length == 1)
            IconButton(icon: const Icon(Icons.edit_rounded, color: Colors.white), onPressed: _showRenameDialog, tooltip: "Rename"),
          IconButton(icon: const Icon(Icons.content_cut_rounded, color: Colors.white), onPressed: _handleMultiCut, tooltip: "Cut"),
          IconButton(icon: const Icon(Icons.content_copy_rounded, color: Colors.white), onPressed: _handleMultiCopy, tooltip: "Copy"),
          IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.white), onPressed: _deleteSelected, tooltip: "Delete"),
          IconButton(
            icon: const Icon(Icons.select_all_rounded, color: Colors.white),
            onPressed: () {
              final selectableFolders = _folders.where((f) => f['name'].toString().toLowerCase() != 'uploads' || _currentFolderId != null).toList();
              final total = selectableFolders.length + _files.length;
              
              setState(() {
                if (_selectedIds.length == total) {
                  _selectedIds.clear();
                  _isSelectionMode = false;
                } else {
                  for (var f in selectableFolders) _selectedIds.add("folder:${f['id']}");
                  for (var f in _files) _selectedIds.add("file:${f['id']}");
                  _isSelectionMode = true;
                }
              });
            },
            tooltip: "Select All",
          ),
        ] : [
          MenuAnchor(
            builder: (context, controller, child) {
              return IconButton(
                icon: const Icon(Icons.more_vert_rounded, color: Color(0xFF05398F)),
                onPressed: () => controller.isOpen ? controller.close() : controller.open(),
                tooltip: "More actions",
              );
            },
            menuChildren: [
              MenuItemButton(
                leadingIcon: const Icon(Icons.cloud_upload_rounded, size: 20, color: Color(0xFF09AEF5)),
                onPressed: _pickAndUploadFile,
                child: const Text("Upload File"),
              ),
              MenuItemButton(
                leadingIcon: const Icon(Icons.create_new_folder_rounded, size: 20, color: Color(0xFF09AEF5)),
                onPressed: _showNewFolderDialog,
                child: const Text("New Folder"),
              ),
              MenuItemButton(
                leadingIcon: const Icon(Icons.share_rounded, size: 20, color: Color(0xFF09AEF5)),
                onPressed: () {
                  setState(() => _isSelectionMode = true);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tap on the items you wish to share.")));
                },
                child: const Text("Share Items"),
              ),
              const Divider(height: 1),
              SubmenuButton(
                leadingIcon: const Icon(Icons.sort_rounded, size: 20, color: Color(0xFF05398F)),
                menuChildren: [
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.text_format_rounded, size: 20),
                    onPressed: () => _applySort('name_asc'),
                    child: const Text("Name"),
                  ),
                  MenuItemButton(
                    leadingIcon: const Icon(Icons.calendar_today_rounded, size: 20),
                    onPressed: () => _applySort('date_desc'),
                    child: const Text("Date"),
                  ),
                ],
                child: const Text("Sort By"),
              ),
            ],
          ),
        ],
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
                      const Center(child: Padding(padding: EdgeInsets.only(top: 50), child: Text("This folder is empty", style: TextStyle(color: Colors.black38))))
                    else ...[
                      // Special Section for System/Pinned Folders (only in root)
                      if (_currentFolderId == null) ...[
                        ..._folders.where((f) => f['name'].toString().toLowerCase() == 'uploads').map((folder) {
                          final id = "folder:${folder['id']}";
                          final isSelected = _selectedIds.contains(id);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTile(folder, 'folder', isSelected),
                              const Divider(height: 32, thickness: 1, color: Colors.black12),
                            ],
                          );
                        }),
                      ],

                      // Remaining Folders
                      ..._folders.where((f) {
                        if (_currentFolderId == null) {
                          return f['name'].toString().toLowerCase() != 'uploads';
                        }
                        return true;
                      }).map((folder) {
                        final id = "folder:${folder['id']}";
                        final isSelected = _selectedIds.contains(id);
                        return _buildTile(folder, 'folder', isSelected);
                      }),

                      // Files
                      ..._files.map((file) {
                        final id = "file:${file['id']}";
                        final isSelected = _selectedIds.contains(id);
                        return _buildTile(file, 'file', isSelected);
                      }),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
      bottomNavigationBar: _isSelectionMode ? SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]
          ),
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: widget.isPicker ? ElevatedButton.icon(
              onPressed: () {
                if (_selectedIds.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(behavior: SnackBarBehavior.floating, content: Text("Please select at least one item.")));
                } else {
                  // Return a list of selected items (only files usually for attachments)
                  final List<Map<String, dynamic>> selectedItems = [];
                  for (final selectionId in _selectedIds) {
                    final parts = selectionId.split(':');
                    final type = parts[0];
                    final id = parts[1];
                    try {
                      final item = type == 'folder' 
                        ? _folders.firstWhere((f) => f['id'].toString() == id)
                        : _files.firstWhere((f) => f['id'].toString() == id);
                      selectedItems.add({...item, 'type': type});
                    } catch (_) {}
                  }
                  Navigator.pop(context, selectedItems);
                }
              },
              icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
              label: const Text("Select Item(s)", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF05398F),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ) : ElevatedButton.icon(
              onPressed: () {
                if (_selectedIds.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(behavior: SnackBarBehavior.floating, content: Text("Please select at least one item.")));
                } else {
                  _showShareBottomSheet();
                }
              },
              icon: const Icon(Icons.share_rounded, color: Colors.white),
              label: const Text("Share Now", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF09AEF5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),
      ) : null,
    );
  }

  Widget _buildBreadcrumbs() {
    // Truncation logic: Show at most 3 items
    const int maxVisible = 3;
    final int total = _navigationStack.length;
    final bool isTruncated = total > maxVisible;
    
    final List<Widget> items = [];

    if (isTruncated) {
      items.add(const Text("...", style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)));
      items.add(const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Text(">", style: TextStyle(color: Colors.black26, fontSize: 14)),
      ));
    }

    final int start = isTruncated ? total - maxVisible : 0;
    for (int i = start; i < total; i++) {
      final bool isLast = i == total - 1;
      final String name = _navigationStack[i]['name']!;
      
      items.add(Flexible(
        child: GestureDetector(
          onTap: () => _navigateToBreadcrumb(i),
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: isLast ? FontWeight.bold : FontWeight.w500,
              color: isLast ? const Color(0xFF05398F) : Colors.black54,
              fontSize: 13,
            ),
          ),
        ),
      ));

      if (!isLast) {
        items.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(">", style: TextStyle(color: Colors.black26, fontSize: 14)),
        ));
      }
    }

    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          if (total > 1) 
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, size: 20, color: Color(0xFF05398F)), 
              onPressed: _navigateBack,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            )
          else
            const Icon(Icons.storage_rounded, size: 20, color: Color(0xFF05398F)),
          const SizedBox(width: 8),
          
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: items,
            ),
          ),

          if (_clipboard != null && _clipboard!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.paste_rounded, color: Colors.green, size: 20),
              tooltip: "Place here",
              onPressed: _pasteItems,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      ),
    );
  }

  Widget _buildTile(dynamic item, String type, bool isSelected) {
    String name = item['name'];
    String date = _formatDate(item['created_at']);
    String info = type == 'folder' ? "${item['item_count'] ?? 0} Items" : _formatBytes(item['file_size_bytes'] ?? 0);
    
    final bool isUploads = type == 'folder' && name.toLowerCase() == 'uploads' && _currentFolderId == null;
    
    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection("${type}:${item['id']}", isSystem: isUploads);
        } else if (type == 'folder') {
          _navigateToFolder(item['id'].toString(), name);
        } else if (type == 'file') {
          _openFile(item);
        }
      },
      onLongPress: () => _toggleSelection("${type}:${item['id']}", isSystem: isUploads),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUploads ? const Color(0xFFE8F5E9) : _getIconColor(name, type).withOpacity(0.1), 
                shape: BoxShape.circle,
              ),
              child: Icon(
                isUploads ? Icons.folder_shared_rounded : _getIcon(name, type), 
                color: isUploads ? Colors.green : _getIconColor(name, type), 
                size: 24
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      if (isUploads) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.lock_rounded, size: 14, color: Colors.black26),
                      ]
                    ],
                  ),
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

  Future<void> _openFile(dynamic fileItem) async {
    final urlStr = fileItem['file_path'] ?? fileItem['url'];
    if (urlStr == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("File not found")));
      return;
    }
    
    String baseUrl = ApiService.baseUrl.replaceAll('/api', '');
    final uri = Uri.parse('$baseUrl$urlStr');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open file.")));
      }
    }
  }

  IconData _getIcon(String name, String type) {
    if (type == 'folder') return Icons.folder_rounded;
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

  Color _getIconColor(String name, String type) {
    if (type == 'folder') return const Color(0xFF09AEF5);
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

  void _showShareBottomSheet() {
    if (_selectedIds.isEmpty) return;
    
    String? selectedCourseId = _courses.isNotEmpty ? _courses.first['id'].toString() : null;
    String? selectedDeptId = _targets.isNotEmpty ? _targets.first['id']?.toString() : null;
    
    // Helper to get sections for a dept
    List<String> getCleanedSections(String? deptId) {
      if (deptId == null) return [];
      var dept = _targets.firstWhere((t) => t['id'].toString() == deptId, orElse: () => null);
      if (dept == null) return [];
      
      List<String> raw = List<String>.from(dept['sections'] ?? []);
      Set<String> cleaned = {};
      for (String s in raw) {
        String c = s.trim();
        if (c.length == 1) c = "Section $c";
        else if (!c.toLowerCase().startsWith('section ')) c = "Section $c";
        cleaned.add(c);
      }
      List<String> sorted = cleaned.toList()..sort();
      sorted.insert(0, "All Sections");
      return sorted;
    }

    List<String> currentSections = getCleanedSections(selectedDeptId);
    String? selectedSection = currentSections.isNotEmpty ? currentSections.first : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20, left: 20, right: 20, 
                bottom: MediaQuery.of(context).viewInsets.bottom + 30
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Share Selected Items", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF05398F))),
                  const SizedBox(height: 8),
                  Text("Sharing ${_selectedIds.length} items from storage.", style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 20),
                  
                  const Text("Select Course", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(10)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedCourseId,
                        items: _courses.map((c) => DropdownMenuItem<String>(
                          value: c['id'].toString(),
                          child: Text((c['title'] ?? c['course_code']).toString()),
                        )).toList(),
                        onChanged: (val) => setSheetState(() => selectedCourseId = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text("Select Department", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(10)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedDeptId,
                        items: _targets.map((d) => DropdownMenuItem<String>(value: d['id'].toString(), child: Text(d['name']))).toList(),
                        onChanged: (val) {
                          setSheetState(() {
                            selectedDeptId = val;
                            currentSections = getCleanedSections(val);
                            selectedSection = currentSections.isNotEmpty ? currentSections.first : null;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text("Select Section", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(10)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedSection,
                        items: currentSections.map((s) => DropdownMenuItem<String>(value: s, child: Text(s))).toList(),
                        onChanged: (val) => setSheetState(() => selectedSection = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                       onPressed: () async {
                          final materialIds = _selectedIds.map((id) => id.split(':')[1]).toList();
                          if (selectedCourseId == null || selectedDeptId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a course and department"), backgroundColor: Colors.orange));
                            return;
                          }

                          Navigator.pop(context);
                          setState(() => _isLoading = true);
                          try {
                            await _apiService.shareMaterials(
                              materialIds, 
                              selectedCourseId,
                              selectedDeptId, 
                              selectedSection == "All Sections" ? null : selectedSection
                            );
                            _exitSelectionMode();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Shared successfully"), backgroundColor: Colors.green));
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Share failed: $e"), backgroundColor: Colors.red));
                          } finally {
                            setState(() => _isLoading = false);
                            _fetchContent();
                          }
                       },
                       style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF09AEF5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                       child: const Text("Share Now", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }
}
