import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    _loadUserData();
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
      backgroundColor: const Color(0xFFF4F7FC), // Professional light grayish blue background
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section with our primary gradient
            _buildHeader(),
            
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Horizontal Scrollable Cards
                  _buildHorizontalCards(context),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Grid Menu
                        const Text("Main Menu", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF05398F))),
                        const SizedBox(height: 15),
                        _buildMenuGrid(),
                        
                        const SizedBox(height: 30),
                        const Text("Today's Schedule", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF05398F))),
                        const SizedBox(height: 15),
                        _buildScheduleTask("Compiler (Lab)", "Room 302 • 10:00 AM", Colors.purple),
                        _buildScheduleTask("Data Structures (Lecture)", "Room 105 • 01:00 PM", Colors.green),

                        const SizedBox(height: 30),
                        const Text("Pending Tasks", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF05398F))),
                        const SizedBox(height: 15),
                        _buildTaskItem("AI Presentation", "Due in 12 hrs", Colors.orange, true),
                        _buildTaskItem("Security Assignment", "Due Friday", Colors.blue, false),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 35),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF09AEF5), Color(0xFF05398F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30), 
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
           BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
    double cardWidth = MediaQuery.of(context).size.width - 40; // Full width with 20 padding on each side

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: _buildBaseCard(
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
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text("Ch 3: Firewalls", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text("Computer Security", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
                SizedBox(
                  height: 60,
                  width: 60,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: 0.65,
                        strokeWidth: 6,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      const Center(
                        child: Text("65%", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
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
      crossAxisCount: 5,
      mainAxisSpacing: 25,
      crossAxisSpacing: 5,
      children: [
        _buildIconBtn(Icons.folder_shared_rounded, "Materials", const Color(0xFFFFF3E0), Colors.orange),
        _buildIconBtn(Icons.schedule_rounded, "Schedule", const Color(0xFFF3E5F5), Colors.purple),
        _buildIconBtn(Icons.groups_rounded, "Groups", const Color(0xFFE0F7FA), Colors.cyan),
        _buildIconBtn(Icons.grade_rounded, "Grades", const Color(0xFFFFEBEE), Colors.red),
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

  Widget _buildTaskItem(String title, String dueTime, Color accent, bool isUrgent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isUrgent ? Colors.red.shade50 : accent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10)
                        ),
                        child: Text(dueTime, style: TextStyle(color: isUrgent ? Colors.red : accent, fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),
                if (isUrgent)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                const Icon(Icons.chevron_right_rounded, color: Colors.black26),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleTask(String title, String timeDetails, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                  child: Icon(Icons.access_time_filled_rounded, color: accent, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text(timeDetails, style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.black26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
