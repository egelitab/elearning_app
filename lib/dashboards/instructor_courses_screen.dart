import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'instructor_materials_screen.dart';
import 'instructor_groups_screen.dart';
import 'instructor_assessments_screen.dart';
import 'instructor_grades_screen.dart';
import 'course_details_screen.dart';

class InstructorCoursesScreen extends StatefulWidget {
  const InstructorCoursesScreen({super.key});

  @override
  State<InstructorCoursesScreen> createState() => _InstructorCoursesScreenState();
}

class _InstructorCoursesScreenState extends State<InstructorCoursesScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _courses = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    try {
      final courses = await _apiService.getInstructorCourses().timeout(const Duration(seconds: 10));
      if (mounted) {
        setState(() {
          _courses = courses;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC), // Match home screen background
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F7FC),
        elevation: 0,
        centerTitle: false,
        title: const Text("My Courses", style: TextStyle(color: Color(0xFF05398F), fontSize: 24, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Sleek Category Grid (Materials, Assessments, etc.)
            _buildCategoryGrid(context),
            
            const SizedBox(height: 35),
            
            // 2. Section Header
            const Text(
              "Assigned Courses",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            
            // 3. List of Courses
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
            else if (_error != null)
              Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
            else if (_courses.isEmpty)
              const Center(child: Text("No courses assigned yet."))
            else
              ..._courses.map((course) {
                // Get initials
                String title = course['title'] ?? 'Unknown Course';
                String initials = title.split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join();
                return _buildCourseItem(
                  course,
                  initials,
                  Colors.blue, // Dynamic color could be implemented here
                );
              }).toList(),
            
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 15,
      mainAxisSpacing: 15,
      childAspectRatio: 1.4,
      children: [
        _buildCategoryTile(
          "Materials", 
          Icons.layers_rounded, 
          const Color(0xFF09AEF5), 
          const Color(0xFF05398F),
          () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const InstructorMaterialsScreen()),
            );
          }
        ),
        _buildCategoryTile("Assessments", Icons.description_rounded, const Color(0xFF66BB6A), const Color(0xFF2E7D32), () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InstructorAssessmentsScreen()),
          );
        }),
        _buildCategoryTile("Grades", Icons.bar_chart_rounded, const Color(0xFFFFCA28), const Color(0xFFFF8F00), () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InstructorGradesScreen()),
          );
        }),
        _buildCategoryTile("Groups", Icons.groups_rounded, const Color(0xFFAB47BC), const Color(0xFF6A1B9A), () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const InstructorGroupsScreen()),
          );
        }),
      ],
    );
  }

  Widget _buildCategoryTile(String title, IconData icon, Color gradientStart, Color gradientEnd, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradientStart, gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradientEnd.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Stack(
        children: [
          // Background Icon (Partially visible watermark style)
          Positioned(
            right: -15,
            bottom: -15,
            child: Icon(icon, size: 90, color: Colors.white.withOpacity(0.15)),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: Icon(icon, size: 24, color: Colors.white),
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildCourseItem(dynamic course, String initials, Color avatarColor) {
    String title = course['title'] ?? 'Unknown Course';
    String code = course['course_code'] ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CourseDetailsScreen(
                  course: course,
                  themeColor: avatarColor,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Circular leading with initials and gradient
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: avatarColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      initials, 
                      style: TextStyle(color: avatarColor, fontWeight: FontWeight.bold, fontSize: 16)
                    )
                  ),
                ),
                const SizedBox(width: 16),
                // Course Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text(code, style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7FC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF05398F), size: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}