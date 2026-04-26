import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'course_details_screen.dart';

class StudentCoursesScreen extends StatefulWidget {
  const StudentCoursesScreen({super.key});

  @override
  State<StudentCoursesScreen> createState() => _StudentCoursesScreenState();
}

class _StudentCoursesScreenState extends State<StudentCoursesScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _courses = [];
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
      setState(() {
        _courses = courses;
        _isLoading = false;
      });
    } catch (e) {
      print(e);
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
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
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildOverviewCard(),
                ),
                const SizedBox(height: 35),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Enrolled Courses",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF05398F),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text("See All", style: TextStyle(color: Color(0xFF09AEF5), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                
                if (_courses.isEmpty)
                  const Center(child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text("You are not enrolled in any courses yet.", style: TextStyle(color: Colors.black38)),
                  ))
                else
                  SizedBox(
                    height: 230,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: _courses.length,
                      itemBuilder: (context, index) {
                        final course = _courses[index];
                        final colorIndex = index % _cardColors.length;
                        return _buildCourseCard(
                          course,
                          _cardColors[colorIndex],
                          _lightColors[colorIndex],
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 35),
                
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "View",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF05398F)),
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
          BoxShadow(color: const Color(0xFF09AEF5).withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 10)),
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
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Text("Spring 2026", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                ),
                const SizedBox(height: 16),
                const Text("Welcome Back!", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text("Check your courses for new materials.", style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(width: 20),
          const Icon(Icons.school_rounded, color: Colors.white, size: 60),
        ],
      ),
    );
  }

  Widget _buildCourseCard(dynamic course, Color darkColor, Color lightColor) {
    return Container(
      width: 170,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 5))],
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
                      "50%",
                      style: TextStyle(fontSize: 12, color: darkColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: 0.5,
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

  Widget _buildActionChip(String label, IconData icon, Color darkColor, Color lightColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: lightColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: darkColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(color: Colors.blueGrey.shade800, fontWeight: FontWeight.bold, fontSize: 15),
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

