import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/date_helper.dart';

class StudentScheduleScreen extends StatefulWidget {
  const StudentScheduleScreen({super.key});

  @override
  State<StudentScheduleScreen> createState() => _StudentScheduleScreenState();
}

class _StudentScheduleScreenState extends State<StudentScheduleScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  
  // Matrix for the timetable: dayIdx -> slotIdx -> courseName
  Map<int, Map<int, String>> _timetable = {};
  int _maxSlotIdx = 3; // Minimum 4 slots
  final int _maxDayIdx = 6; // Mon-Sun

  final List<String> _dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
  final List<String> _slotTimes = [
    "02:00 - 03:45",
    "03:50 - 06:20",
    "07:35 - 09:20",
    "09:25 - 12:05",
    "12:10 - 01:50",
    "01:55 - 03:30"
  ];

  @override
  void initState() {
    super.initState();
    DateHelper.init().then((_) {
      if (mounted) {
        _fetchSchedule();
        DateHelper.calendarFormat.addListener(_handlePreferenceChange);
      }
    });
  }

  void _handlePreferenceChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    DateHelper.calendarFormat.removeListener(_handlePreferenceChange);
    super.dispose();
  }

  Future<void> _fetchSchedule() async {
    setState(() => _isLoading = true);
    try {
      final courses = await _apiService.getStudentCourses();
      final schedules = await _apiService.getMySchedules();
      
      final Set<String> myCourseIdentifiers = {};
      for (var course in courses) {
        if (course['title'] != null) myCourseIdentifiers.add(course['title'].toString().toLowerCase());
        if (course['course_code'] != null) myCourseIdentifiers.add(course['course_code'].toString().toLowerCase());
      }

      Map<int, Map<int, String>> newTimetable = {};

      for (var schedule in schedules) {
        if (schedule['file_path'] == 'DIGITAL_ENTRY') {
          final content = schedule['content'] as Map<String, dynamic>?;
          if (content != null) {
            content.forEach((key, value) {
              final parts = key.split('-');
              if (parts.length == 2) {
                try {
                  int slotIdx = int.parse(parts[0]);
                  int dayIdx = int.parse(parts[1]);
                  
                  String courseName = value.toString().trim();
                  String courseTitleOnly = courseName.split('|')[0].split('-')[0].trim().toLowerCase();
                  
                  bool isMyCourse = myCourseIdentifiers.contains(courseName.toLowerCase()) || 
                                   myCourseIdentifiers.contains(courseTitleOnly);
                  
                  if (!isMyCourse) {
                    isMyCourse = myCourseIdentifiers.any((id) => 
                      id.length > 3 && (courseName.toLowerCase().contains(id) || id.contains(courseName.toLowerCase()))
                    );
                  }

                  if (isMyCourse) {
                    if (slotIdx > _maxSlotIdx) _maxSlotIdx = slotIdx;
                    
                    newTimetable.putIfAbsent(dayIdx, () => {});
                    newTimetable[dayIdx]![slotIdx] = courseName;
                  }
                } catch (e) {
                  // Ignore parse errors
                }
              }
            });
          }
        }
      }

      if (mounted) {
        setState(() {
          _timetable = newTimetable;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading schedule: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text('Weekly Schedule', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF09AEF5), Color(0xFF05398F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _timetable.isEmpty 
          ? _buildEmptyState()
          : _buildTimetable(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No digital schedule found', 
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)
          ),
          const SizedBox(height: 8),
          const Text('Your class schedule will appear here once assigned.', 
            style: TextStyle(color: Colors.grey)
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchSchedule, 
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF05398F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTimetable() {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row (Time Slots)
            Row(
              children: [
                _buildCell("Day", isHeader: true, width: 80),
                ...List.generate(_maxSlotIdx + 1, (slotIdx) {
                  return _buildCell(
                    DateHelper.formatTimeSlot(_slotTimes[slotIdx % _slotTimes.length]), 
                    isHeader: true, 
                    width: 140,
                    isTime: true
                  );
                }),
              ],
            ),
            // Data Rows (Days)
            ...List.generate(7, (dayIdx) {
              return Row(
                children: [
                  _buildCell(_dayNames[dayIdx], isHeader: true, width: 80),
                  ...List.generate(_maxSlotIdx + 1, (slotIdx) {
                    final course = _timetable[dayIdx]?[slotIdx];
                    return _buildCell(course ?? "", isHeader: false, width: 140);
                  }),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(String text, {bool isHeader = false, double width = 120, bool isTime = false}) {
    // Determine color based on text
    Color bgColor = isHeader ? const Color(0xFF05398F).withOpacity(0.05) : Colors.white;
    Color textColor = isHeader ? const Color(0xFF05398F) : Colors.black87;
    
    if (text.isNotEmpty && !isHeader) {
      // Logic for background color for courses
      final int hash = text.hashCode;
      final List<Color> courseColors = [
        Colors.blue.shade50,
        Colors.green.shade50,
        Colors.orange.shade50,
        Colors.purple.shade50,
        Colors.red.shade50,
        Colors.teal.shade50,
        Colors.cyan.shade50,
      ];
      bgColor = courseColors[hash % courseColors.length];
      textColor = Color(0xFF05398F);
    }

    return Container(
      width: width,
      height: 70,
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isHeader ? const Color(0xFF05398F).withOpacity(0.1) : Colors.grey.withOpacity(0.1),
          width: 1
        ),
      ),
      child: Center(
        child: Text(
          text, 
          style: TextStyle(
            fontWeight: isHeader ? FontWeight.bold : FontWeight.w500,
            fontSize: isHeader ? 13 : 11,
            color: textColor,
          ),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
