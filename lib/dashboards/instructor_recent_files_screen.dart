import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InstructorRecentFilesScreen extends StatelessWidget {
  final List<dynamic> recentFiles;

  const InstructorRecentFilesScreen({super.key, required this.recentFiles});

  @override
  Widget build(BuildContext context) {
    Map<String, List<dynamic>> groupedFiles = _groupFilesByTime(recentFiles);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F7FC),
        elevation: 0,
        title: const Text(
          "Recent Files",
          style: TextStyle(
            color: Color(0xFF05398F),
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF05398F)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: groupedFiles.isEmpty
          ? const Center(child: Text("No recent files"))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: groupedFiles.entries.map((entry) {
                if (entry.value.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10).copyWith(top: 15),
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    ...entry.value.map((file) => _buildFileTile(file)).toList(),
                  ],
                );
              }).toList(),
            ),
    );
  }

  Map<String, List<dynamic>> _groupFilesByTime(List<dynamic> files) {
    Map<String, List<dynamic>> grouped = {
      'Today': [],
      'This week': [],
      'This month': [],
      'Older': []
    };

    final now = DateTime.now();

    for (var file in files) {
      if (file['created_at'] == null) continue;
      final date = DateTime.parse(file['created_at']);
      final diff = now.difference(date);

      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        grouped['Today']!.add(file);
      } else if (diff.inDays < 7) {
        grouped['This week']!.add(file);
      } else if (diff.inDays < 30) {
        grouped['This month']!.add(file);
      } else {
        grouped['Older']!.add(file);
      }
    }

    return grouped;
  }

  Widget _buildFileTile(dynamic file) {
    String name = file['name'] ?? 'Unknown File';
    String dateStr = file['created_at'] ?? '';

    String formattedDate = "";
    if (dateStr.isNotEmpty) {
      formattedDate = _getRelativeTime(dateStr);
    }

    IconData icon = _getIconForFile(name);
    Color iconColor = _getColorForFile(name);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
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
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  formattedDate,
                  style: const TextStyle(color: Colors.black38, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.more_vert_rounded, color: Colors.black26),
        ],
      ),
    );
  }

  String _getRelativeTime(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} mins ago";
    if (diff.inHours < 24) return "${diff.inHours} hrs ago";
    if (diff.inDays == 1) return "Yesterday";
    return DateFormat('MMM dd, yyyy').format(date);
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
