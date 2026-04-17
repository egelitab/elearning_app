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
      appBar: AppBar(
        title: const Text("Recycle Bin", style: TextStyle(color: Color(0xFF05398F), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF05398F)),
          onPressed: () => Navigator.pop(context, true),
        ),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))
        ]
      ),
      child: Row(
        children: [
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
          TextButton.icon(
            onPressed: () => _restoreItem(item['id'].toString(), item['type']),
            icon: const Icon(Icons.restore_rounded, size: 18),
            label: const Text("Restore", style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF05398F),
              backgroundColor: const Color(0xFFE3F2FD),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
            ),
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
