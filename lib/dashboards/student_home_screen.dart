import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'system_notifications_screen.dart';
import 'student_menu_screen.dart';
import 'student_courses_screen.dart';
import 'chat_detail_screen.dart';
import 'student_assignments_screen.dart';
import 'student_materials_screen.dart';
import 'student_schedule_screen.dart';
import 'course_details_screen.dart';
import '../services/api_service.dart';

import '../utils/date_helper.dart';
import 'package:file_picker/file_picker.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  String _title = '';
  String _firstName = 'Student';

  @override
  void initState() {
    super.initState();
    DateHelper.init().then((_) {
      if (mounted) {
        _loadUserData();
        _fetchTodaySchedule();
        _fetchPendingTasks();
        _fetchSystemUnread();
        DateHelper.calendarFormat.addListener(_handlePreferenceChange);
      }
    });
  }

  void _handlePreferenceChange() {
    if (mounted) {
      // Re-run the schedule calculation so the DateHelper formats the times with the new setting
      _fetchTodaySchedule();
      setState(() {});
    }
  }

  @override
  void dispose() {
    DateHelper.calendarFormat.removeListener(_handlePreferenceChange);
    super.dispose();
  }

  Future<void> _fetchSystemUnread() async {
    try {
      final counts = await _apiService.getUnreadNotificationCounts();
      if (mounted) setState(() => _systemUnread = counts['system'] ?? 0);
    } catch (_) {}
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _title = prefs.getString('title') ?? '';
      if (_title == 'None') _title = '';
      _firstName = prefs.getString('first_name') ?? 'Student';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light background for contrast
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Gradient Section matches the image
            Container(
              padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 40),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF6A85E6), // Darker blue
                    Color(0xFF8FB0FF), // Lighter blue
                    Color(0xFFE5ECFF), // Almost white
                  ],
                  stops: [0.0, 0.6, 1.0],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6A85E6).withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                children: [
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 32),
                  // Search Bar
                  _buildSearchBar(),
                  const SizedBox(height: 32),
                  // Quick Access (Icon row)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickAccessItem(Icons.calendar_month_outlined, "Timetable"),
                        const SizedBox(width: 28),
                        _buildQuickAccessItem(Icons.grade_outlined, "Grades"),
                        const SizedBox(width: 28),
                        _buildQuickAccessItem(Icons.chat_bubble_outline, "Messages"),
                        const SizedBox(width: 28),
                        _buildQuickAccessItem(Icons.help_outline, "Help Me"),
                        const SizedBox(width: 28),
                        _buildQuickAccessItem(Icons.more_horiz, "More"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // White Bottom Section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Today's Classes",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E2843),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildClassCard("Computer Architecture", "10:00 AM", "Room B12"),
                  const SizedBox(height: 16),
                  _buildClassCard("Software Engineering", "1:30 PM", "Room C3"),
                  
                  const SizedBox(height: 32),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Tasks",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E2843),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text("See More", style: TextStyle(color: Color(0xFF3366FF), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildTaskCard("Database Assignment", "Due in 12 hours", true),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTaskCard("Final Project Presentation", "Due Friday", false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Quick Actions",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E2843),
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text("See More", style: TextStyle(color: Color(0xFF3366FF), fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Grid Menu
                        const Text("Main Menu", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF05398F))),
                        const SizedBox(height: 15),
                        _buildMenuGrid(),
                        
                        const SizedBox(height: 30),
                        const Text("Pending Assignments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF05398F))),
                        const SizedBox(height: 15),
                        _buildAssignmentTask("Security Principle Lab", "CS 4051", "Due Tomorrow", Colors.orange),
                        _buildAssignmentTask("Design Milestone 2", "CD 4022", "Due Friday", Colors.blue),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32), // bottom padding for nav bar scrolling
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildQuickActionCard(IconData icon, String label) {
    return Container(
      width: 110, // slightly wider to fit multiline labels comfortably
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Hi, ${_title.isNotEmpty ? '$_title ' : ''}$_firstName".trim(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                const Text("Let's start learning!", style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
               color: Colors.white24,
               shape: BoxShape.circle,
            ),
            child: const CircleAvatar(
              backgroundColor: Colors.white, 
              radius: 22,
              child: Icon(Icons.notifications_none_rounded, color: Color(0xFF05398F), size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalCards(BuildContext context) {
    double cardWidth = MediaQuery.of(context).size.width * 0.75;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Blue Continue Learning Card
          _buildBaseCard(
            width: cardWidth,
            gradient: const LinearGradient(
              colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text("Continue Learning", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                    Icon(Icons.play_circle_fill_rounded, color: Colors.white70, size: 20),
                  ],
                ),
                const SizedBox(height: 12),
                const Text("Ch 3: Firewalls", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const Spacer(),
                const Text("Computer Security", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: 0.65,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  borderRadius: BorderRadius.circular(5),
                )
              ],
            ),
          ),
          
          const SizedBox(width: 15),

          // Action Card for Academic Progress
          _buildBaseCard(
            width: cardWidth,
            gradient: const LinearGradient(
              colors: [Color(0xFF26A69A), Color(0xFF00695C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Current Semester", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                    SizedBox(height: 8),
                    Text("3.86", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 32)),
                    Text("Cumulative GPA", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 36),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBaseCard({required double width, Gradient? gradient, required Widget child}) {
    return Container(
      width: width,
      height: 150,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: child,
    );
  }

  Widget _buildMenuGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 25,
      crossAxisSpacing: 10,
      children: [
        _buildIconBtn(Icons.folder_shared_rounded, "Materials", const Color(0xFFFFF3E0), Colors.orange),
        _buildIconBtn(Icons.assignment_rounded, "Assessments", const Color(0xFFE3F2FD), Colors.blue),
        _buildIconBtn(Icons.book_rounded, "Registration", const Color(0xFFE8F5E9), Colors.green),
        _buildIconBtn(Icons.schedule_rounded, "Schedule", const Color(0xFFF3E5F5), Colors.purple),
        _buildIconBtn(Icons.grade_rounded, "Grades", const Color(0xFFFFEBEE), Colors.red),
        _buildIconBtn(Icons.groups_rounded, "Groups", const Color(0xFFE0F7FA), Colors.cyan),
        _buildIconBtn(Icons.calendar_month_rounded, "Calendar", const Color(0xFFFFFDE7), Colors.amber),
        _buildIconBtn(Icons.more_horiz_rounded, "More", Colors.grey.shade200, Colors.grey.shade700),
      ],
    );
  }

  Widget _buildIconBtn(IconData icon, String label, Color bgColor, Color iconColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          height: 55,
          width: 55,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04), 
                blurRadius: 10,
                offset: const Offset(0, 4)
              )
            ]
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label, 
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildAssignmentTask(String title, String subtitle, String dueTime, Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.assignment_late_rounded, color: accent, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10)
                            ),
                            child: Text(dueTime, style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.bold)),
                          )
                        ],
                      )
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.black26),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySchedule() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.event_available_rounded, size: 40, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            DateTime.now().weekday > 5 ? "Happy Weekend! No classes today." : "No classes scheduled for today.",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
