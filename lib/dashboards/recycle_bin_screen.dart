import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _items = [];
  bool _isLoading = true;
  bool _isSelectionMode = false;
  Set<String> _selectedItemKeys = {};

  @override
  void initState() {
    super.initState();
    _fetchRecycleBin();
  }

  Future<void> _fetchRecycleBin() async {
    setState(() => _isLoading = true);
    try {
      final items = await _apiService.getRecycleBin();
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), behavior: SnackBarBehavior.floating));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreItem(String id, String type) async {
    try {
      await _apiService.restoreEntry(id, type);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Item restored successfully"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
      );
      _fetchRecycleBin();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to restore: $e"), behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _deleteSingleItem(String id, String type) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Permanently"),
        content: const Text("Are you sure you want to permanently delete this item? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Delete", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    try {
      await _apiService.permanentlyDeleteEntry(id, type);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Item permanently deleted"), backgroundColor: Colors.black87, behavior: SnackBarBehavior.floating),
      );
      _fetchRecycleBin();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to delete: $e"), behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _restoreSelected() async {
    setState(() => _isLoading = true);
    int count = 0;
    for (final item in _items) {
      final key = "${item['type']}_${item['id']}";
      if (_selectedItemKeys.contains(key)) {
        try {
          await _apiService.restoreEntry(item['id'].toString(), item['type']);
          count++;
        } catch(e) {}
      }
    }
    _selectedItemKeys.clear();
    _isSelectionMode = false;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$count items restored"), behavior: SnackBarBehavior.floating));
    _fetchRecycleBin();
  }

  Future<void> _deleteSelected() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Permanently"),
        content: Text("Are you sure you want to permanently delete these ${_selectedItemKeys.length} items? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Delete", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() => _isLoading = true);
    int count = 0;
    for (final item in _items) {
      final key = "${item['type']}_${item['id']}";
      if (_selectedItemKeys.contains(key)) {
        try {
          await _apiService.permanentlyDeleteEntry(item['id'].toString(), item['type']);
          count++;
        } catch(e) {}
      }
    }
    _selectedItemKeys.clear();
    _isSelectionMode = false;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$count items permanently deleted"), behavior: SnackBarBehavior.floating));
    _fetchRecycleBin();
  }

  Map<String, List<dynamic>> _categorizeItems() {
    Map<String, List<dynamic>> categories = {
      'Today': [],
      'Yesterday': [],
      'This Week': [],
      'Earlier': [],
    };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final sixDaysAgo = today.subtract(const Duration(days: 6));

    for (var item in _items) {
      final deletedAt = DateTime.parse(item['deleted_at']).toLocal();
      final deletedDate = DateTime(deletedAt.year, deletedAt.month, deletedAt.day);

      if (deletedDate == today) {
        categories['Today']!.add(item);
      } else if (deletedDate == yesterday) {
        categories['Yesterday']!.add(item);
      } else if (deletedDate.isAfter(sixDaysAgo)) {
        categories['This Week']!.add(item);
      } else {
        categories['Earlier']!.add(item);
      }
    }
    return categories;
  }

  @override
  Widget build(BuildContext context) {
    final categorized = _categorizeItems();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: _isSelectionMode
        ? AppBar(
            backgroundColor: const Color(0xFF05398F),
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => setState(() {
                _isSelectionMode = false;
                _selectedItemKeys.clear();
              }),
            ),
            title: Text("${_selectedItemKeys.length} Selected", style: const TextStyle(color: Colors.white, fontSize: 18)),
            actions: [
              IconButton(
                icon: Icon(
                  _selectedItemKeys.length == _items.length ? Icons.deselect_rounded : Icons.select_all_rounded,
                  color: Colors.white,
                ),
                tooltip: _selectedItemKeys.length == _items.length ? "Deselect All" : "Select All",
                onPressed: () {
                  setState(() {
                    if (_selectedItemKeys.length == _items.length) {
                      _selectedItemKeys.clear();
                    } else {
                      _selectedItemKeys.clear();
                      for (var item in _items) {
                        _selectedItemKeys.add("${item['type']}_${item['id']}");
                      }
                    }
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.restore_rounded, color: Colors.white),
                onPressed: _selectedItemKeys.isEmpty ? null : _restoreSelected,
              ),
              IconButton(
                icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                onPressed: _selectedItemKeys.isEmpty ? null : _deleteSelected,
              ),
            ],
          )
        : AppBar(
            title: const Text("Recycle Bin", style: TextStyle(color: Color(0xFF05398F), fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF05398F)),
              onPressed: () => Navigator.pop(context, true),
            ),
            actions: [
              if (_items.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.checklist_rounded, color: Color(0xFF05398F)),
                  onPressed: () => setState(() => _isSelectionMode = true),
                ),
            ],
          ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _items.isEmpty 
          ? _buildEmptyState()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: categorized.entries
                .where((e) => e.value.isNotEmpty)
                .map((entry) => _buildCategorySection(entry.key, entry.value))
                .toList(),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_outline_rounded, size: 80, color: Colors.blue.withOpacity(0.2)),
          const SizedBox(height: 16),
          const Text("Recycle Bin is Empty", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black45)),
        ],
      ),
    );
  }

  Widget _buildCategorySection(String title, List<dynamic> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 0.5)),
        ),
        ...items.map((item) => _buildRecycleItemTile(item)),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildRecycleItemTile(dynamic item) {
    final bool isFolder = item['type'] == 'folder';
    final String name = item['name'] ?? 'Unnamed';
    final String date = DateFormat('MMM d, h:mm a').format(DateTime.parse(item['deleted_at']).toLocal());
    final Color itemColor = isFolder ? const Color(0xFF09AEF5) : _getColorForFile(name);
    final String key = "${item['type']}_${item['id']}";
    final bool isSelected = _selectedItemKeys.contains(key);

    return GestureDetector(
      onLongPress: () {
        if (!_isSelectionMode) {
          setState(() {
            _isSelectionMode = true;
            _selectedItemKeys.add(key);
          });
        }
      },
      onTap: () {
        if (_isSelectionMode) {
          setState(() {
            if (isSelected) {
              _selectedItemKeys.remove(key);
              if (_selectedItemKeys.isEmpty) _isSelectionMode = false;
            } else {
              _selectedItemKeys.add(key);
            }
          });
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: Colors.blue, width: 1.5) : Border.all(color: Colors.transparent, width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))
          ]
        ),
        child: Row(
          children: [
            if (_isSelectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  color: isSelected ? Colors.blue : Colors.grey.shade400,
                ),
              ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: itemColor.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(
                isFolder ? Icons.folder_rounded : _getIconForFile(name), 
                color: itemColor, 
                size: 24
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text("Deleted: $date", style: const TextStyle(color: Colors.black38, fontSize: 11, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            if (!_isSelectionMode) ...[
              IconButton(
                onPressed: () => _restoreItem(item['id'].toString(), item['type']),
                icon: const Icon(Icons.restore_rounded, color: Color(0xFF05398F)),
                tooltip: "Restore",
              ),
              IconButton(
                onPressed: () => _deleteSingleItem(item['id'].toString(), item['type']),
                icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                tooltip: "Permanently Delete",
              ),
            ]
          ],
        ),
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
      case 'mp4': return Icons.video_library_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png': return Icons.image_rounded;
      default: return Icons.insert_drive_file_rounded;
    }
  }

  Color _getColorForFile(String filename) {
    String ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf': return const Color(0xFFE91E63);
      case 'docx': return const Color(0xFF2196F3);
      case 'txt': return const Color(0xFF607D8B);
      case 'mp4': return const Color(0xFFFF9800);
      case 'jpg':
      case 'png': return const Color(0xFF4CAF50);
      default: return const Color(0xFF05398F);
    }
  }
}
