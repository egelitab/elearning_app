import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'student_courses_screen.dart';
import 'student_downloads_screen.dart';
import 'help_support_screen.dart';
import 'account_settings_screen.dart';
import 'system_messages_screen.dart';
import 'academic_calendar_screen.dart';
import 'student_schedule_screen.dart';
import 'student_all_courses_screen.dart';
import 'student_grades_screen.dart';
import 'student_groups_screen.dart';
import 'student_materials_screen.dart';
import 'student_assignments_screen.dart';
import 'student_quiz_screen.dart';
import 'student_analytics_screen.dart';
import '../services/api_service.dart';

class StudentMenuScreen extends StatefulWidget {
  const StudentMenuScreen({super.key});

  @override
  State<StudentMenuScreen> createState() => _StudentMenuScreenState();
}

class _StudentMenuScreenState extends State<StudentMenuScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _fetchAndNavigateToAllCourses() async {
    setState(() => _isLoading = true);
    try {
      final courses = await _apiService.getStudentCourses();
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.push(context, MaterialPageRoute(builder: (context) => StudentAllCoursesScreen(courses: courses)));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F7FC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF05398F)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("All Services", style: TextStyle(color: Color(0xFF05398F), fontWeight: FontWeight.bold)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 25,
              crossAxisSpacing: 20,
              children: [
                _buildMenuIcon(Icons.folder_shared_rounded, "Materials", const Color(0xFFFFF3E0), Colors.orange, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentMaterialsScreen()));
                }),
                _buildMenuIcon(Icons.assignment_rounded, "Tasks", const Color(0xFFE3F2FD), Colors.blue, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentAssignmentsScreen()));
                }),
                _buildMenuIcon(Icons.book_rounded, "Courses", const Color(0xFFE8F5E9), Colors.green, () {
                  _fetchAndNavigateToAllCourses();
                }),
                _buildMenuIcon(Icons.schedule_rounded, "Schedule", const Color(0xFFF3E5F5), Colors.purple, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentScheduleScreen()));
                }),
                _buildMenuIcon(Icons.grade_rounded, "Grades", const Color(0xFFFFEBEE), Colors.red, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentGradesScreen()));
                }),
                _buildMenuIcon(Icons.groups_rounded, "Groups", const Color(0xFFE0F7FA), Colors.cyan, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentGroupsScreen()));
                }),
                _buildMenuIcon(Icons.calendar_month_rounded, "Calendar", const Color(0xFFFFFDE7), Colors.amber, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AcademicCalendarScreen()));
                }),
                _buildMenuIcon(Icons.download_rounded, "Downloads", const Color(0xFFE1F5FE), Colors.lightBlue, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentDownloadsScreen()));
                }),
                _buildMenuIcon(Icons.quiz_rounded, "Quizzes", const Color(0xFFFCE4EC), Colors.pink, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentQuizScreen()));
                }),

              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuIcon(IconData icon, String label, Color bgColor, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))]
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 28),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildListAction(IconData icon, String title, String sub, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))]
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: const Color(0xFF09AEF5)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black26),
      ),
    );
  }
}
