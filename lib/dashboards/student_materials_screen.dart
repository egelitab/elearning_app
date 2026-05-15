import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import '../widgets/downloadable_behavior.dart';

class StudentMaterialsScreen extends StatefulWidget {
  const StudentMaterialsScreen({super.key});

  @override
  State<StudentMaterialsScreen> createState() => _StudentMaterialsScreenState();
}

class _StudentMaterialsScreenState extends State<StudentMaterialsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, List<dynamic>> _categorizedMaterials = {};
  List<dynamic> _courses = [];

  @override
  void initState() {
    super.initState();
    _fetchMaterials();
  }

  Future<void> _fetchMaterials() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch courses
      final courses = await _apiService.getStudentCourses();
      
      Map<String, List<dynamic>> materialsMap = {};
      
      // 2. Fetch materials for each course
      for (var course in courses) {
        final courseId = course['id'].toString();
        final courseTitle = course['title'] ?? 'Unknown Course';
        final materials = await _apiService.getMaterialsByCourse(courseId);
        if (materials.isNotEmpty) {
          materialsMap[courseTitle] = materials;
        }
      }

      if (mounted) {
        setState(() {
          _courses = courses;
          _categorizedMaterials = materialsMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading materials: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text('Course Materials', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF09AEF5), Color(0xFF05398F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _categorizedMaterials.isEmpty 
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _fetchMaterials,
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _categorizedMaterials.length,
                itemBuilder: (context, index) {
                  String courseTitle = _categorizedMaterials.keys.elementAt(index);
                  List<dynamic> materials = _categorizedMaterials[courseTitle]!;
                  return _buildCourseSection(courseTitle, materials);
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No shared materials yet', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)
          ),
          const SizedBox(height: 8),
          const Text('Materials from your instructors will appear here.', 
            style: TextStyle(color: Colors.grey)
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchMaterials, 
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF05398F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCourseSection(String courseTitle, List<dynamic> materials) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12, top: 10),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF05398F),
                  borderRadius: BorderRadius.circular(2)
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  courseTitle, 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF05398F)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF05398F).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)
                ),
                child: Text(
                  '${materials.length}', 
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF05398F))
                ),
              ),
            ],
          ),
        ),
        ...materials.map((m) => _buildMaterialCard(m, courseTitle)).toList(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildMaterialCard(dynamic material, String courseTitle) {
    String title = material['title'] ?? 'Untitled Material';
    String description = material['description'] ?? '';
    String fileType = material['file_type'] ?? '';
    int fileSize = int.tryParse(material['file_size_bytes']?.toString() ?? '0') ?? 0;
    String date = '';
    if (material['created_at'] != null) {
      try {
        date = DateFormat('MMM d, yyyy').format(DateTime.parse(material['created_at']));
      } catch (e) {
        date = material['created_at'].toString().split('T')[0];
      }
    }

    IconData iconData = Icons.insert_drive_file_rounded;
    Color iconColor = Colors.blue;

    if (fileType.contains('pdf')) {
      iconData = Icons.picture_as_pdf_rounded;
      iconColor = Colors.red;
    } else if (fileType.contains('image')) {
      iconData = Icons.image_rounded;
      iconColor = Colors.green;
    } else if (fileType.contains('word') || fileType.contains('officedocument.word') || title.endsWith('.docx') || title.endsWith('.doc')) {
      iconData = Icons.description_rounded;
      iconColor = Colors.blue.shade700;
    } else if (fileType.contains('presentation') || fileType.contains('powerpoint') || title.endsWith('.pptx') || title.endsWith('.ppt')) {
      iconData = Icons.slideshow_rounded;
      iconColor = Colors.orange.shade800;
    } else if (fileType.contains('video')) {
      iconData = Icons.videocam_rounded;
      iconColor = Colors.purple;
    }

    return DownloadableBehavior(
      filePath: material['file_path']?.toString() ?? '',
      fileName: material['title'] ?? 'material',
      builder: (context, isDownloaded, isDownloading, isPaused, progress, onTap) {
        IconData currentIconData = iconData;
        Color currentIconColor = iconColor;

        if (!isDownloaded && !isDownloading) {
          currentIconData = Icons.download_rounded;
          currentIconColor = Colors.grey;
        } else if (isDownloading) {
          currentIconData = isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded;
          currentIconColor = Colors.orange;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                final courseId = _courses.firstWhere((c) => c['title'] == courseTitle, orElse: () => {'id': ''})['id'].toString();
                if (courseId.isNotEmpty) {
                  _apiService.logReadingDuration(courseId, material['id']?.toString() ?? 'unknown', 3600);
                  
                  // Save as recently opened
                  final Map<String, dynamic> recentMaterial = Map<String, dynamic>.from(material);
                  recentMaterial['course_title'] = courseTitle; // Include course title for display
                  recentMaterial['course_id'] = courseId; // Include course ID for navigation
                  _apiService.saveRecentlyOpenedMaterial(recentMaterial);

                }
                onTap();
              },


              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        if (isDownloading)
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: currentIconColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(currentIconData, color: currentIconColor, size: 24),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (description.isNotEmpty && description != 'null') ...[
                            const SizedBox(height: 2),
                            Text(description, 
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (date.isNotEmpty) ...[
                                Text(date, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                                const SizedBox(width: 12),
                              ],
                              Text(_formatFileSize(fileSize), style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    var i = (math.log(bytes) / math.log(1024)).floor();
    return ((bytes / math.pow(1024, i)).toStringAsFixed(1)) + ' ' + suffixes[i];
  }

}
