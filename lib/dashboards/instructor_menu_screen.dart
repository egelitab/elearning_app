import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import 'instructor_materials_screen.dart';
import 'instructor_courses_screen.dart';
import 'instructor_schedule_screen.dart';
import 'instructor_grades_screen.dart';
import 'instructor_groups_screen.dart';
import 'help_support_screen.dart';
import 'account_settings_screen.dart';
import 'course_details_screen.dart';
import 'instructor_files_screen.dart';

class InstructorMenuScreen extends StatefulWidget {
  final List<dynamic> courses;
  const InstructorMenuScreen({super.key, required this.courses});

  @override
  State<InstructorMenuScreen> createState() => _InstructorMenuScreenState();
}

class _InstructorMenuScreenState extends State<InstructorMenuScreen> {
  final ApiService _apiService = ApiService();

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("LMS Services", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF05398F))),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 25,
              crossAxisSpacing: 20,
              children: [
                _buildMenuIcon(Icons.folder_shared_rounded, "Materials", const Color(0xFFFFF3E0), Colors.orange, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const InstructorMaterialsScreen()));
                }),
                _buildMenuIcon(Icons.cloud_upload_rounded, "Upload", const Color(0xFFE3F2FD), Colors.blue, _handleDirectUpload),
                _buildMenuIcon(Icons.book_rounded, "Courses", const Color(0xFFE8F5E9), Colors.green, () {
                  if (widget.courses.isNotEmpty) {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => CourseDetailsScreen(
                      course: widget.courses.first,
                      allCourses: widget.courses,
                    )));
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const InstructorCoursesScreen()));
                  }
                }),
                _buildMenuIcon(Icons.schedule_rounded, "Schedule", const Color(0xFFF3E5F5), Colors.purple, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const InstructorScheduleScreen()));
                }),
                _buildMenuIcon(Icons.assessment_rounded, "Grades", const Color(0xFFFFEBEE), Colors.red, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const InstructorGradesScreen()));
                }),
                _buildMenuIcon(Icons.groups_rounded, "Groups", const Color(0xFFE0F7FA), Colors.cyan, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const InstructorGroupsScreen()));
                }),
                _buildMenuIcon(Icons.calendar_month_rounded, "Calendar", const Color(0xFFFFFDE7), Colors.amber, () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Calendar coming soon!")));
                }),
                _buildMenuIcon(Icons.download_rounded, "Downloads", const Color(0xFFE1F5FE), Colors.lightBlue, () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const InstructorFilesScreen(showToggle: false, startInDownloads: true)));
                }),
                _buildMenuIcon(Icons.picture_as_pdf_rounded, "To PDF", const Color(0xFFFBE9E7), Colors.deepOrange, () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Document conversion coming soon!")));
                }),
                _buildMenuIcon(Icons.analytics_rounded, "Analytics", const Color(0xFFE8EAF6), Colors.indigo, () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Analytics coming soon!")));
                }),
                _buildMenuIcon(Icons.how_to_reg_rounded, "Attendance", const Color(0xFFE0F2F1), Colors.teal, () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Attendance coming soon!")));
                }),
                _buildMenuIcon(Icons.quiz_rounded, "Quizzes", const Color(0xFFFCE4EC), Colors.pink, () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Quizzes coming soon!")));
                }),
              ],
            ),
            
            const SizedBox(height: 40),
            const Text("Account & Support", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF05398F))),
            const SizedBox(height: 20),
            _buildListAction(Icons.help_outline_rounded, "Help & Support", "Get assistance and tutorials", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen()));
            }),
            _buildListAction(Icons.settings_outlined, "Account Settings", "Manage your profile and security", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountSettingsScreen()));
            }),
            _buildListAction(Icons.info_outline_rounded, "About ELMS", "App version and information", () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("BDU ELMS v1.0.0")));
            }),
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
          Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87)),
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

  Future<void> _handleDirectUpload() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles();
      if (result != null) {
        if (!mounted) return;
        PlatformFile selectedFile = result.files.first;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(behavior: SnackBarBehavior.floating, content: Text("Uploading...")));
        try {
          await _apiService.uploadMaterial(null, selectedFile.name, selectedFile.path!);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(behavior: SnackBarBehavior.floating, content: Text("Uploaded Successfully", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(e.toString()), backgroundColor: Colors.red));
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text("Error picking file: $e")));
    }
  }
}
