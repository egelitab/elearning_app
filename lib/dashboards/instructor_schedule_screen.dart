import 'package:flutter/material.dart';
import '../services/api_service.dart';

class InstructorScheduleScreen extends StatefulWidget {
  const InstructorScheduleScreen({super.key});

  @override
  State<InstructorScheduleScreen> createState() => _InstructorScheduleScreenState();
}

class _InstructorScheduleScreenState extends State<InstructorScheduleScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _weeklyClasses = [];
  List<dynamic> _fileSchedules = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final courses = await _apiService.getInstructorCourses();
      final schedules = await _apiService.getMySchedules();

      _processSchedules(courses, schedules);
    } catch (e) {
      print("Error fetching schedule data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _processSchedules(List<dynamic> courses, List<dynamic> schedules) {
    final Set<String> myCourseTitles = courses.map((c) => (c['title'] as String).toLowerCase()).toSet();
    myCourseTitles.addAll(courses.map((c) => (c['course_code'] as String).toLowerCase()));

    List<Map<String, dynamic>> extractedClasses = [];
    List<dynamic> files = [];

    final dayNames = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];
    final slotTimes = [
      "08:00 AM - 09:45 AM",
      "09:50 AM - 12:20 PM",
      "01:35 PM - 03:20 PM",
      "03:25 PM - 06:05 PM"
    ];
    final List<Color> colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal];

    for (var schedule in schedules) {
      if (schedule['file_path'] == 'DIGITAL_ENTRY') {
        final content = schedule['content'] as Map<String, dynamic>?;
        if (content != null) {
          content.forEach((key, value) {
            if (myCourseTitles.contains(value.toString().toLowerCase())) {
              final parts = key.split('-');
              if (parts.length == 2) {
                int slotIdx = int.parse(parts[0]);
                int dayIdx = int.parse(parts[1]);
                
                extractedClasses.add({
                  'day': dayNames[dayIdx],
                  'dayIdx': dayIdx,
                  'slotIdx': slotIdx,
                  'course': value,
                  'time': slotTimes[slotIdx % slotTimes.length],
                  'location': "See Digital Schedule", // Location not explicitly in slot yet
                  'color': colors[extractedClasses.length % colors.length]
                });
              }
            }
          });
        }
      } else {
        files.add(schedule);
      }
    }

    // Sort by day then by time
    extractedClasses.sort((a, b) {
      if (a['dayIdx'] != b['dayIdx']) return a['dayIdx'].compareTo(b['dayIdx']);
      return a['slotIdx'].compareTo(b['slotIdx']);
    });

    setState(() {
      _weeklyClasses = extractedClasses;
      _fileSchedules = files;
    });
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
        title: const Text("Schedule & Office Hours", style: TextStyle(color: Color(0xFF05398F), fontWeight: FontWeight.bold)),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader("Weekly Class Schedule"),
                  const SizedBox(height: 15),
                  
                  if (_weeklyClasses.isEmpty && _fileSchedules.isEmpty)
                    _buildEmptyState("No classes scheduled yet.")
                  else ...[
                    ..._weeklyClasses.map((c) => _buildScheduleItem(
                      c['day'], c['course'], c['time'], c['location'], c['color']
                    )),
                    
                    if (_fileSchedules.isNotEmpty) ...[
                      const SizedBox(height: 25),
                      _buildSectionHeader("Uploaded Schedule Files"),
                      const SizedBox(height: 15),
                      ..._fileSchedules.map((fs) => _buildFileItem(fs)),
                    ],
                  ],
                  
                  const SizedBox(height: 35),
                  _buildSectionHeader("Office Hours"),
                  const SizedBox(height: 15),
                  _buildOfficeHourItem("Tuesdays & Thursdays", "10:00 AM - 12:00 PM", "Block 4, Office 412"),
                  
                  const SizedBox(height: 40),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Editing schedule will be available in the next update.")));
                      },
                      icon: const Icon(Icons.edit_calendar_rounded),
                      label: const Text("Request Schedule Change"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF05398F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(30),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.calendar_today_outlined, size: 50, color: Colors.grey.shade300),
          const SizedBox(height: 15),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87));
  }

  Widget _buildScheduleItem(String day, String course, String time, String location, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 50,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text("$day | $time", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                Text(location, style: const TextStyle(color: Color(0xFF09AEF5), fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(dynamic fileSchedule) {
    final String title = fileSchedule['title'] ?? "Class Schedule";
    final String path = fileSchedule['file_path'];
    final String fileName = path.split('\\').last.split('/').last;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 32),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(fileName, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Downloading schedule file...")));
            },
            child: const Text("Open"),
          )
        ],
      ),
    );
  }

  Widget _buildOfficeHourItem(String days, String time, String location) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade50, Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_filled_rounded, color: Color(0xFF05398F), size: 40),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(days, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(time, style: const TextStyle(color: Colors.black54, fontSize: 14)),
              Text(location, style: const TextStyle(color: Color(0xFF05398F), fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}
