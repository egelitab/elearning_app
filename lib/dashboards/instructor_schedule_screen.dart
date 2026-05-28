import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/date_helper.dart';
import 'digital_schedule_view_screen.dart';

class InstructorScheduleScreen extends StatefulWidget {
  const InstructorScheduleScreen({super.key});

  @override
  State<InstructorScheduleScreen> createState() =>
      _InstructorScheduleScreenState();
}

class _InstructorScheduleScreenState extends State<InstructorScheduleScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _weeklyClasses = [];
  List<dynamic> _fileSchedules = [];
  final TextEditingController _changeRequestController = TextEditingController();
  bool _isSendingRequest = false;

  @override
  void initState() {
    super.initState();
    DateHelper.init().then((_) {
      if (mounted) {
        _fetchData();
        DateHelper.calendarFormat.addListener(_handlePreferenceChange);
      }
    });
  }

  void _handlePreferenceChange() {
    if (mounted) _fetchData();
  }

  @override
  void dispose() {
    DateHelper.calendarFormat.removeListener(_handlePreferenceChange);
    _changeRequestController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _apiService.getUserProfile();
      final courses = await _apiService.getInstructorCourses();
      final schedules = await _apiService.getMySchedules();

      _processSchedules(courses, schedules, profile);
    } catch (e) {
      print("Error fetching schedule data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _processSchedules(List<dynamic> courses, List<dynamic> schedules, Map<String, dynamic> profile) {
    final String? instructorDept = profile['department_name'];
    final Set<String> myCourseTitles = courses
        .map((c) => (c['title'] as String).toLowerCase())
        .toSet();
    myCourseTitles.addAll(
      courses.map((c) => (c['course_code'] as String).toLowerCase()),
    );

    List<Map<String, dynamic>> extractedClasses = [];
    List<dynamic> files = [];

    final dayNames = [
      "Monday",
      "Tuesday",
      "Wednesday",
      "Thursday",
      "Friday",
    ];
    final slotTimes = [
      "02:00 - 03:45",
      "03:50 - 06:20",
      "07:35 - 09:20",
      "09:25 - 12:05",
    ];
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    for (var schedule in schedules) {
      if (schedule['file_path'] == 'DIGITAL_ENTRY') {
        final content = schedule['content'] as Map<String, dynamic>?;
        if (content != null) {
          content.forEach((key, value) {
            String courseName = value.toString().trim();
            String courseTitleOnly = courseName
                .split('|')[0]
                .split('-')[0]
                .trim()
                .toLowerCase();

            bool isMyCourse =
                myCourseTitles.contains(courseName.toLowerCase()) ||
                myCourseTitles.contains(courseTitleOnly);

            if (!isMyCourse) {
              isMyCourse = myCourseTitles.any(
                (id) =>
                    id.length > 3 &&
                    (courseName.toLowerCase().contains(id) ||
                        id.contains(courseName.toLowerCase())),
              );
            }

            if (isMyCourse) {
              final parts = key.split('-');
              if (parts.length == 2) {
                int slotIdx = int.parse(parts[0]);
                int dayIdx = int.parse(parts[1]);

                // Skip Saturday and Sunday (Idx 5 and 6)
                if (dayIdx >= 5) return;

                // 1. Try to extract from the courseName string (e.g. "Programming | Sec 1 | CS")
                final courseParts = courseName.split('|').map((p) => p.trim()).toList();
                
                String? extractedSection;
                String? extractedDept;

                if (courseParts.length > 1) {
                  for (int i = 1; i < courseParts.length; i++) {
                    String p = courseParts[i].toLowerCase();
                    if (p.contains('sec') || RegExp(r'^s[0-9]+').hasMatch(p) || (p.length <= 3 && int.tryParse(p) != null)) {
                      extractedSection = courseParts[i].replaceAll(RegExp(r'sec', caseSensitive: false), '').trim();
                    } else if (p.length > 3) {
                      extractedDept = courseParts[i];
                    }
                  }
                }

                // 2. Fallback to schedule metadata
                String deptInfo = extractedDept ?? "N/A";
                if (deptInfo == "N/A" && schedule['departments'] != null) {
                  final depts = schedule['departments'];
                  if (depts is List && depts.isNotEmpty) {
                    deptInfo = depts.join(", ");
                  } else if (depts is String && depts != "[]") {
                     deptInfo = depts.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '');
                  }
                }
                
                // 3. Final Fallback to instructor's own department
                if (deptInfo == "N/A" || deptInfo == "All Departments") {
                  deptInfo = instructorDept ?? deptInfo;
                }

                String sectionInfo = extractedSection ?? "General";
                if (sectionInfo == "General" && schedule['sections'] != null) {
                  final sects = schedule['sections'];
                   if (sects is List && sects.isNotEmpty) {
                    sectionInfo = sects.join(", ");
                  } else if (sects is String && sects != "[]") {
                     sectionInfo = sects.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '');
                  }
                }

                // Final Cleanups
                if (sectionInfo == "[]") sectionInfo = "General";

                extractedClasses.add({
                  'day': dayNames[dayIdx],
                  'dayIdx': dayIdx,
                  'slotIdx': slotIdx,
                  'course': courseName,
                  'department': deptInfo,
                  'section': sectionInfo,
                  'time': DateHelper.formatTimeSlot(
                    slotTimes[slotIdx % slotTimes.length],
                  ),
                  'location': "See Digital Schedule",
                  'color': colors[extractedClasses.length % colors.length],
                  'sourceSchedule': schedule,
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

  void _showScheduleChangeDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Request Schedule Change"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Please describe the changes you'd like to make to your schedule. An admin will review and update it.",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _changeRequestController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "Type your request here...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: _isSendingRequest
                    ? null
                    : () async {
                        final text = _changeRequestController.text.trim();
                        if (text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please type your request first."),
                            ),
                          );
                          return;
                        }

                        setDialogState(() => _isSendingRequest = true);
                        await _submitScheduleChangeRequest();
                        if (mounted) {
                          setDialogState(() => _isSendingRequest = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSendingRequest
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text("Send Request"),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submitScheduleChangeRequest() async {
    final text = _changeRequestController.text.trim();
    setState(() => _isSendingRequest = true);

    try {
      await _apiService.createSupportTicket(
        "Schedule Change Request",
        text,
        priority: "High",
      );

      if (mounted) {
        Navigator.pop(context); // Close dialog
        _changeRequestController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Request sent successfully! Admin will review it."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to send request: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingRequest = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: Theme.of(context).colorScheme.secondary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Weekly Schedule",
          style: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader("Weekly Class Schedule"),
                    SizedBox(height: 15),

                    if (_weeklyClasses.isEmpty && _fileSchedules.isEmpty)
                      _buildEmptyState("No classes scheduled yet.")
                    else ...[
                      ..._weeklyClasses.map(
                        (c) => _buildScheduleItem(
                          c['day'],
                          c['course'],
                          c['time'],
                          c['location'],
                          c['color'],
                          c['department'] ?? "N/A",
                          c['section'] ?? "General",
                          c['sourceSchedule'],
                        ),
                      ),

                      if (_fileSchedules.isNotEmpty) ...[
                        SizedBox(height: 25),
                        _buildSectionHeader("Uploaded Schedule Files"),
                        SizedBox(height: 15),
                        ..._fileSchedules.map((fs) => _buildFileItem(fs)),
                      ],
                    ],



                    SizedBox(height: 40),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _showScheduleChangeDialog,
                        icon: const Icon(Icons.edit_calendar_rounded),
                        label: const Text("Request Schedule Change"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 50,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 15),
          Text(message, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildScheduleItem(
    String day,
    String course,
    String time,
    String location,
    Color color,
    String department,
    String section,
    dynamic sourceSchedule,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.business_rounded, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        department,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(Icons.groups_rounded, size: 12, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      "Section $section",
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "$day | $time",
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
                if (location == "See Digital Schedule")
                  InkWell(
                    onTap: () {
                      if (sourceSchedule != null &&
                          sourceSchedule['content'] != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DigitalScheduleViewScreen(
                              scheduleContent: sourceSchedule['content'],
                              title: "Full Schedule: $section",
                            ),
                          ),
                        );
                      }
                    },
                    child: Text(
                      location,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                else
                  Text(
                    location,
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.picture_as_pdf_rounded,
            color: Colors.redAccent,
            size: 32,
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  fileName,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Downloading schedule file...")),
              );
            },
            child: const Text("Open"),
          ),
        ],
      ),
    );
  }


}
