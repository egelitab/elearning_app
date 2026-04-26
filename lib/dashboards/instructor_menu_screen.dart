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
    if (widget.courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No courses assigned.")));
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.pickFiles();
      if (result != null) {
        if (!mounted) return;
        _showCourseSelectionForUpload(result.files.first);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error picking file: $e")));
    }
  }

  void _showCourseSelectionForUpload(PlatformFile selectedFile) {
    String? selectedCourseId = widget.courses.first['id'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            bool isUploading = false;

            return Container(
              padding: EdgeInsets.only(top: 20, left: 20, right: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Finalize Upload", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF05398F))),
                  const SizedBox(height: 10),
                  Text("File: ${selectedFile.name}", style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 25),
                  const Text("Select Course", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(10)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedCourseId,
                        items: widget.courses.map((course) {
                          return DropdownMenuItem<String>(
                            value: course['id'],
                            child: Text(course['title'] ?? course['course_code']),
                          );
                        }).toList(),
                        onChanged: (val) => setSheetState(() => selectedCourseId = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  isUploading 
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF09AEF5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          onPressed: () async {
                            if (selectedCourseId == null) return;
                            setSheetState(() => isUploading = true);
                            try {
                              await _apiService.uploadMaterial(selectedCourseId!, selectedFile.name, selectedFile.path!);
                              if (!mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Uploaded Successfully"), backgroundColor: Colors.green));
                            } catch (e) {
                              setSheetState(() => isUploading = false);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                            }
                          },
                          child: const Text("Upload Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      )
                ],
              ),
            );
          }
        );
      }
    );
  }
}
