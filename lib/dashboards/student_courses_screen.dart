import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'course_details_screen.dart';
import 'student_all_courses_screen.dart';
import 'student_assignments_screen.dart';
import 'student_grades_screen.dart';
import 'student_schedule_screen.dart';
import 'student_materials_screen.dart';

class StudentCoursesScreen extends StatefulWidget {
  const StudentCoursesScreen({super.key});

  @override
  State<StudentCoursesScreen> createState() => _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends State<StudentCoursesScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _courses = [];
  List<dynamic> _myGoals = [];
  bool _isLoading = true;

  final List<Color> _cardColors = [
    const Color(0xFF05398F),
    const Color(0xFF6A1B9A),
    const Color(0xFFFF8F00),
    const Color(0xFF2E7D32),
  ];
  
  final List<Color> _lightColors = [
    const Color(0xFF09AEF5),
    const Color(0xFFAB47BC),
    const Color(0xFFFFCA28),
    const Color(0xFF66BB6A),
  ];

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    try {
      final courses = await _apiService.getStudentCourses();
      final goals = await _apiService.getMyGoals();
      if (mounted) {
        setState(() {
          _courses = courses;
          _myGoals = goals;
          _isLoading = false;
        });
      }
    } catch (e) {
      print(e);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC), // Match home screen background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "My Learning",
          style: TextStyle(
            color: Color(0xFF05398F),
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF05398F).withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.search_rounded, color: Color(0xFF05398F)),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            // Header Overview Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildOverviewCard(),
            ),
            const SizedBox(height: 35),
            
            // Horizontal Courses List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Active Courses",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF05398F),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      "See All", 
                      style: TextStyle(
                        color: Color(0xFF09AEF5), 
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            
            SizedBox(
              height: 230,
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  _buildCourseCard("Computer Security", "4 Tasks Pending", 0.65, const Color(0xFF05398F), const Color(0xFF09AEF5), Icons.security),
                  _buildCourseCard("Compiler Design", "1 Task Pending", 0.40, const Color(0xFF6A1B9A), const Color(0xFFAB47BC), Icons.code),
                  _buildCourseCard("Complexity Theory", "Up to date", 0.82, const Color(0xFFFF8F00), const Color(0xFFFFCA28), Icons.psychology),
                  _buildCourseCard("Research Methods", "Reading Assigned", 0.15, const Color(0xFF2E7D32), const Color(0xFF66BB6A), Icons.biotech),
                ],
              ),
            ),
            const SizedBox(height: 35),
            
            // Quick Actions section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Quick Actions",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF05398F),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildActionChip("Assignments", Icons.assignment_turned_in_rounded, const Color(0xFF2E7D32), const Color(0xFF66BB6A))),
                      const SizedBox(width: 15),
                      Expanded(child: _buildActionChip("Grades", Icons.military_tech_rounded, const Color(0xFFFF8F00), const Color(0xFFFFCA28))),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: _buildActionChip("Schedule", Icons.calendar_month_rounded, const Color(0xFF05398F), const Color(0xFF09AEF5))),
                      const SizedBox(width: 15),
                      Expanded(child: _buildActionChip("Discussions", Icons.forum_rounded, const Color(0xFF6A1B9A), const Color(0xFFAB47BC))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF05398F), Color(0xFF09AEF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF09AEF5).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "Spring 2026",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Great work!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "You have completed 60% of your weekly goals.",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Circular Progress 
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: 0.6,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  strokeCap: StrokeCap.round,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const Text(
                "60%",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCourseCard(String title, String subtitle, double progress, Color darkColor, Color lightColor, IconData icon) {
    return Container(
      width: 170,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
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
                allCourses: _courses,
                themeColor: darkColor
              )),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: lightColor.withOpacity(0.15), shape: BoxShape.circle),
                  child: Icon(_getIcon(course['title']), color: darkColor, size: 30),
                ),
                const Spacer(),
                Text(
                  course['title'] ?? '',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF05398F), height: 1.2),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  course['instructor_name'] ?? 'Not Assigned',
                  style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      course['course_code'] ?? '',
                      style: TextStyle(fontSize: 12, color: lightColor, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      courseGoals.isNotEmpty ? "${(progress * 100).toInt()}% (Goal Progress)" : "0%",
                      style: TextStyle(fontSize: 12, color: darkColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: lightColor.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(darkColor),
                  borderRadius: BorderRadius.circular(5),
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

  Widget _buildActionChip(String label, IconData icon, Color darkColor, Color lightColor, {VoidCallback? onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap ?? () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("$label feature coming soon.")),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: lightColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: darkColor, size: 24),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(color: Colors.blueGrey.shade800, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

