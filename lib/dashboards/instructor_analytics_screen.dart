import 'package:flutter/material.dart';
import '../services/api_service.dart';

class InstructorAnalyticsScreen extends StatefulWidget {
  const InstructorAnalyticsScreen({super.key});

  @override
  State<InstructorAnalyticsScreen> createState() => _InstructorAnalyticsScreenState();
}

class _InstructorAnalyticsScreenState extends State<InstructorAnalyticsScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _data;
  List<dynamic> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final data = await _apiService.getInstructorAnalytics();
      final courses = await _apiService.getInstructorCourses();
      if (mounted) setState(() { _data = data; _courses = courses; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text("Analytics", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF5C6BC0), Color(0xFF3949AB)]),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? const Center(child: Text("No data available", style: TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _fetch,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Overview stat cards
                        Row(
                          children: [
                            _statCard("Courses", "${_data!['courses_taught'] ?? 0}", Icons.school_rounded, Colors.blue),
                            const SizedBox(width: 12),
                            _statCard("Students", "${_data!['total_students'] ?? 0}", Icons.people_rounded, Colors.teal),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _statCard("Assignments", "${_data!['assignments_created'] ?? 0}", Icons.assignment_rounded, Colors.orange),
                            const SizedBox(width: 12),
                            _statCard("Submissions", "${_data!['submissions_received'] ?? 0}", Icons.upload_file_rounded, Colors.green),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _statCard("Quizzes", "${_data!['quizzes_created'] ?? 0}", Icons.quiz_rounded, Colors.pink),
                            const SizedBox(width: 12),
                            _statCard("Materials", "${_data!['materials_uploaded'] ?? 0}", Icons.folder_rounded, Colors.purple),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _wideStatCard("Attendance Sessions", "${_data!['attendance_sessions'] ?? 0}", Icons.how_to_reg_rounded, Colors.cyan),

                        const SizedBox(height: 28),

                        // Per-course analytics
                        const Text("Course Analytics", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3949AB))),
                        const SizedBox(height: 4),
                        const Text("Tap a course for detailed breakdown", style: TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 16),
                        ..._courses.map((course) => _buildCourseItem(course)),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  Widget _wideStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          begin: Alignment.centerLeft, end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: TextStyle(fontSize: 15, color: color.withOpacity(0.8)))),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildCourseItem(dynamic course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFF5C6BC0).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.analytics_rounded, color: Color(0xFF5C6BC0)),
        ),
        title: Text(course['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(course['course_code'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => _CourseAnalyticsScreen(
              courseId: course['id'].toString(),
              courseTitle: course['title'] ?? '',
            ),
          ));
        },
      ),
    );
  }
}

class _CourseAnalyticsScreen extends StatefulWidget {
  final String courseId, courseTitle;
  const _CourseAnalyticsScreen({required this.courseId, required this.courseTitle});

  @override
  State<_CourseAnalyticsScreen> createState() => _CourseAnalyticsScreenState();
}

class _CourseAnalyticsScreenState extends State<_CourseAnalyticsScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final data = await _apiService.getCourseAnalytics(widget.courseId);
      if (mounted) setState(() { _data = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: Text(widget.courseTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF5C6BC0), Color(0xFF3949AB)])),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _data == null
              ? const Center(child: Text("No data", style: TextStyle(color: Colors.grey)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Enrollment & Submissions
                      _section("Overview"),
                      _card([
                        _row("Enrolled Students", "${_data!['enrolled_students'] ?? 0}", Colors.blue),
                        _row("Assignments Created", "${_data!['assignment_count'] ?? 0}", Colors.orange),
                        _row("Submissions Received", "${_data!['submission_count'] ?? 0}", Colors.green),
                        _row("Average Grade", "${_data!['average_grade'] ?? 0}%", Colors.purple),
                      ]),
                      const SizedBox(height: 20),

                      // Attendance
                      _section("Attendance"),
                      _card([
                        _row("Sessions Held", "${_data!['session_count'] ?? 0}", Colors.blue),
                        _row("Present Marks", "${_data!['attendance_present'] ?? 0}", Colors.green),
                        _row("Late Marks", "${_data!['attendance_late'] ?? 0}", Colors.orange),
                        _row("Absent Marks", "${_data!['attendance_absent'] ?? 0}", Colors.red),
                      ]),
                      const SizedBox(height: 20),

                      // Quizzes
                      _section("Quizzes"),
                      _card([
                        _row("Quizzes Created", "${_data!['quiz_count'] ?? 0}", Colors.pink),
                        _row("Avg Quiz Score", "${_data!['avg_quiz_score'] ?? 0}%", Colors.purple),
                      ]),
                      const SizedBox(height: 20),

                      // Top Students
                      if ((_data!['top_students'] as List?)?.isNotEmpty == true) ...[
                        _section("Top Performers"),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                          ),
                          child: Column(
                            children: [
                              ...(_data!['top_students'] as List).asMap().entries.map((entry) {
                                final idx = entry.key;
                                final student = entry.value;
                                final medals = [
                                  const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                                  const Icon(Icons.emoji_events, color: Colors.grey, size: 20),
                                  Icon(Icons.emoji_events, color: Colors.brown.shade300, size: 20),
                                ];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    children: [
                                      if (idx < 3) medals[idx] else Text("  ${idx + 1}.", style: const TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text(student['name'] ?? '', style: const TextStyle(fontSize: 15))),
                                      Text("${student['avg_grade']}%", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],

                      // Grade distribution visual
                      const SizedBox(height: 20),
                      _section("Class Average"),
                      const SizedBox(height: 8),
                      _progressBar(double.tryParse(_data!['average_grade'].toString()) ?? 0),
                    ],
                  ),
                ),
    );
  }

  Widget _section(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3949AB))),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  Widget _row(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 15), overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _progressBar(double pct) {
    final clamped = pct.clamp(0, 100).toDouble();
    final color = clamped >= 70 ? Colors.green : clamped >= 50 ? Colors.orange : Colors.red;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${clamped.toStringAsFixed(1)}%", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              Text(clamped >= 70 ? "Good" : clamped >= 50 ? "Average" : "Low",
                style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: clamped / 100,
              minHeight: 10,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}
