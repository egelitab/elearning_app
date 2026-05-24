import 'package:flutter/material.dart';
import '../services/api_service.dart';

class InstructorAttendanceScreen extends StatefulWidget {
  const InstructorAttendanceScreen({super.key});

  @override
  State<InstructorAttendanceScreen> createState() => _InstructorAttendanceScreenState();
}

class _InstructorAttendanceScreenState extends State<InstructorAttendanceScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    try {
      final courses = await _apiService.getInstructorCourses();
      if (mounted) setState(() { _courses = courses; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text("Attendance", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF09AEF5), Color(0xFF05398F)]),
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _courses.isEmpty
              ? const Center(child: Text("No courses found", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _courses.length,
                  itemBuilder: (context, index) {
                    final course = _courses[index];
                    return _buildCourseCard(course);
                  },
                ),
    );
  }

  Widget _buildCourseCard(dynamic course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFF05398F).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.how_to_reg_rounded, color: Color(0xFF05398F)),
        ),
        title: Text(course['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(course['course_code'] ?? '', style: const TextStyle(color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => _AttendanceSessionsScreen(
                courseId: course['id'].toString(),
                courseTitle: course['title'] ?? '',
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AttendanceSessionsScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  const _AttendanceSessionsScreen({required this.courseId, required this.courseTitle});

  @override
  State<_AttendanceSessionsScreen> createState() => _AttendanceSessionsScreenState();
}

class _AttendanceSessionsScreenState extends State<_AttendanceSessionsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  Future<void> _fetchSessions() async {
    setState(() => _isLoading = true);
    try {
      final sessions = await _apiService.getAttendanceSessions(widget.courseId);
      if (mounted) setState(() { _sessions = sessions; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _createSession() async {
    final titleController = TextEditingController(text: "Lecture ${_sessions.length + 1}");
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (date == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("New Attendance Session"),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(labelText: "Session Title", border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Create")),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _apiService.createAttendanceSession(
        widget.courseId,
        titleController.text,
        date.toIso8601String().split('T')[0],
      );
      _fetchSessions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: Text(widget.courseTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF09AEF5), Color(0xFF05398F)]),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createSession,
        backgroundColor: const Color(0xFF05398F),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Session", style: TextStyle(color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _sessions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text("No attendance sessions yet", style: TextStyle(color: Colors.grey, fontSize: 16)),
                      const SizedBox(height: 8),
                      const Text("Tap + to create one", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchSessions,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _sessions.length,
                    itemBuilder: (context, index) => _buildSessionCard(_sessions[index]),
                  ),
                ),
    );
  }

  Widget _buildSessionCard(dynamic session) {
    final present = session['present_count'] ?? 0;
    final late = session['late_count'] ?? 0;
    final absent = session['absent_count'] ?? 0;
    final total = session['total_count'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => _MarkAttendanceScreen(
                sessionId: session['id'].toString(),
                sessionTitle: session['title'] ?? 'Session',
              ),
            ),
          );
          _fetchSessions();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(session['title'] ?? 'Session', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  Text(
                    (session['session_date'] ?? '').toString().split('T')[0],
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _statusChip("Present", present, Colors.green),
                  const SizedBox(width: 8),
                  _statusChip("Late", late, Colors.orange),
                  const SizedBox(width: 8),
                  _statusChip("Absent", absent, Colors.red),
                  const Spacer(),
                  Text("$total students", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text("$count $label", style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}

class _MarkAttendanceScreen extends StatefulWidget {
  final String sessionId;
  final String sessionTitle;
  const _MarkAttendanceScreen({required this.sessionId, required this.sessionTitle});

  @override
  State<_MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<_MarkAttendanceScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isSaving = false;
  List<dynamic> _records = [];
  Map<String, String> _statusMap = {}; // student_id -> status

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final data = await _apiService.getAttendanceSessionDetail(widget.sessionId);
      final records = data['records'] as List<dynamic>;
      final Map<String, String> map = {};
      for (var r in records) {
        map[r['student_id'].toString()] = r['status'] ?? 'unmarked';
      }
      if (mounted) setState(() { _records = records; _statusMap = map; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _markAll(String status) {
    setState(() {
      for (var r in _records) {
        _statusMap[r['student_id'].toString()] = status;
      }
    });
  }

  void _save() async {
    setState(() => _isSaving = true);
    try {
      final records = _statusMap.entries
          .map((e) => {"student_id": e.key, "status": e.value == 'unmarked' ? 'absent' : e.value})
          .toList();
      await _apiService.markAttendance(widget.sessionId, records);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Attendance saved!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'present': return Colors.green;
      case 'late': return Colors.orange;
      case 'absent': return Colors.red;
      case 'excused': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _nextStatus(String current) {
    const cycle = ['present', 'late', 'absent', 'excused'];
    final idx = cycle.indexOf(current);
    return cycle[(idx + 1) % cycle.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: Text(widget.sessionTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF09AEF5), Color(0xFF05398F)]),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("SAVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Quick action bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  color: Colors.white,
                  child: Row(
                    children: [
                      const Text("Mark All: ", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      _quickButton("Present", Colors.green, () => _markAll('present')),
                      const SizedBox(width: 6),
                      _quickButton("Absent", Colors.red, () => _markAll('absent')),
                      const Spacer(),
                      Text("${_records.length} students", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
                // Student list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _records.length,
                    itemBuilder: (context, index) {
                      final record = _records[index];
                      final studentId = record['student_id'].toString();
                      final status = _statusMap[studentId] ?? 'unmarked';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _statusColor(status).withOpacity(0.3)),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _statusColor(status).withOpacity(0.15),
                            child: Text(
                              "${index + 1}",
                              style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            "${record['first_name'] ?? ''} ${record['last_name'] ?? ''}",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(record['institutional_id'] ?? '', style: const TextStyle(fontSize: 12)),
                          trailing: GestureDetector(
                            onTap: () {
                              setState(() {
                                _statusMap[studentId] = _nextStatus(status);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _statusColor(status).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _quickButton(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
        child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
