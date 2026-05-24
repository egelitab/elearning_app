import 'package:flutter/material.dart';
import 'course_details_screen.dart';

class StudentAllCoursesScreen extends StatelessWidget {
  final List<dynamic> courses;
  final List<dynamic> myGoals;

  const StudentAllCoursesScreen({super.key, required this.courses, this.myGoals = const []});

  final List<Color> _cardColors = const [
    Color(0xFF05398F),
    Color(0xFF6A1B9A),
    Color(0xFFFF8F00),
    Color(0xFF2E7D32),
  ];
  
  final List<Color> _lightColors = const [
    Color(0xFF09AEF5),
    Color(0xFFAB47BC),
    Color(0xFFFFCA28),
    Color(0xFF66BB6A),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF05398F)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "All Courses",
          style: TextStyle(
            color: Color(0xFF05398F),
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: courses.isEmpty
          ? const Center(child: Text("No courses enrolled yet."))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                final colorIndex = index % _cardColors.length;
                return _buildFullWidthCourseCard(
                  context,
                  course,
                  _cardColors[colorIndex],
                  _lightColors[colorIndex],
                );
              },
            ),
    );
  }

  Widget _buildFullWidthCourseCard(BuildContext context, dynamic course, Color darkColor, Color lightColor) {
    final courseGoals = myGoals.where((g) => g['course_id'].toString() == course['id'].toString() && g['target_hours'] != null).toList();
    double progress = 0.0;
    if (courseGoals.isNotEmpty) {
      double totalTarget = 0.0;
      double totalProgress = 0.0;
      for (var g in courseGoals) {
        totalTarget += double.tryParse(g['target_hours'].toString()) ?? 0.0;
        totalProgress += double.tryParse(g['progress_hours']?.toString() ?? '0.0') ?? 0.0;
      }
      if (totalTarget > 0) progress = totalProgress / totalTarget;
      if (progress > 1.0) progress = 1.0;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CourseDetailsScreen(
                course: course, 
                allCourses: courses,
                themeColor: darkColor
              )),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: lightColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(_getIcon(course['title']), color: darkColor, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF05398F),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        course['instructor_name'] ?? 'Not Assigned',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: darkColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              course['course_code'] ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: darkColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            courseGoals.isNotEmpty ? "${(progress * 100).toInt()}% (Goal Progress)" : "0%",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black45,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: lightColor.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(darkColor),
                        borderRadius: BorderRadius.circular(10),
                        minHeight: 6,
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

  IconData _getIcon(String? title) {
    if (title == null) return Icons.book;
    final t = title.toLowerCase();
    if (t.contains('security')) return Icons.security;
    if (t.contains('code') || t.contains('compiler')) return Icons.code;
    if (t.contains('research')) return Icons.biotech;
    if (t.contains('theory')) return Icons.psychology;
    return Icons.menu_book_rounded;
  }
}
