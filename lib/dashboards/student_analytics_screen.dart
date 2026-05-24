import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StudentAnalyticsScreen extends StatefulWidget {
  const StudentAnalyticsScreen({super.key});

  @override
  State<StudentAnalyticsScreen> createState() => _StudentAnalyticsScreenState();
}

class _StudentAnalyticsScreenState extends State<StudentAnalyticsScreen> {
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
      final data = await _apiService.getStudentAnalytics();
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
        title: const Text("My Analytics", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
              ? const Center(child: Text("No analytics available", style: TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _fetch,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary cards row
                        Row(
                          children: [
                            _statCard("Courses", "${_data!['courses_enrolled'] ?? 0}", Icons.school_rounded, Colors.blue),
                            const SizedBox(width: 12),
                            _statCard("Avg Grade", "${_data!['average_grade'] ?? 0}%", Icons.grade_rounded, Colors.green),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _statCard("Attendance", "${_data!['attendance_rate'] ?? 0}%", Icons.how_to_reg_rounded, Colors.teal),
                            const SizedBox(width: 12),
                            _statCard("Quiz Avg", "${_data!['quiz_avg_score'] ?? 0}%", Icons.quiz_rounded, Colors.pink),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Assignments section
                        _sectionTitle("Assignments"),
                        const SizedBox(height: 12),
                        _detailCard([
                          _detailRow("Completed", "${_data!['assignments_completed'] ?? 0}", Colors.green),
                          _detailRow("Pending", "${_data!['assignments_pending'] ?? 0}", Colors.orange),
                        ]),
                        const SizedBox(height: 20),

                        // Attendance breakdown
                        _sectionTitle("Attendance Breakdown"),
                        const SizedBox(height: 12),
                        _detailCard([
                          _detailRow("Present", "${_data!['attendance_present'] ?? 0}", Colors.green),
                          _detailRow("Late", "${_data!['attendance_late'] ?? 0}", Colors.orange),
                          _detailRow("Total Sessions", "${_data!['attendance_total'] ?? 0}", Colors.blue),
                        ]),
                        const SizedBox(height: 20),

                        // Quiz performance
                        _sectionTitle("Quiz Performance"),
                        const SizedBox(height: 12),
                        _detailCard([
                          _detailRow("Quizzes Taken", "${_data!['quiz_attempts'] ?? 0}", Colors.purple),
                          _detailRow("Average Score", "${_data!['quiz_avg_score'] ?? 0}%", Colors.pink),
                        ]),

                        // Attendance visual bar
                        if ((_data!['attendance_total'] ?? 0) > 0) ...[
                          const SizedBox(height: 24),
                          _sectionTitle("Attendance Rate"),
                          const SizedBox(height: 12),
                          _progressBar(double.tryParse(_data!['attendance_rate'].toString()) ?? 0),
                        ],

                        // Grade visual bar
                        const SizedBox(height: 20),
                        _sectionTitle("Overall Grade"),
                        const SizedBox(height: 12),
                        _progressBar(double.tryParse(_data!['average_grade'].toString()) ?? 0),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
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
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 13, color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3949AB)));
  }

  Widget _detailCard(List<Widget> children) {
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

  Widget _detailRow(String label, String value, Color color) {
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

  Widget _progressBar(double percentage) {
    final clamped = percentage.clamp(0, 100).toDouble();
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
              Text(clamped >= 70 ? "Excellent" : clamped >= 50 ? "Good" : "Needs Improvement",
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
