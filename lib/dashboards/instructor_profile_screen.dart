import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import '../auth/welcome_screen.dart';

class InstructorProfileScreen extends StatefulWidget {
  const InstructorProfileScreen({super.key});

  @override
  State<InstructorProfileScreen> createState() => _InstructorProfileScreenState();
}

class _InstructorProfileScreenState extends State<InstructorProfileScreen> {
  String _title = 'Dr.';
  String _firstName = '';
  String _middleName = '';
  String _lastName = 'Alemu';
  String _email = 'alemu.instructor@bdu.edu';

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
      _firstName = prefs.getString('first_name') ?? '';
      _middleName = prefs.getString('middle_name') ?? '';
      _lastName = prefs.getString('last_name') ?? '';
      _email = prefs.getString('email') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F7FC),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Profile",
          style: TextStyle(color: Color(0xFF05398F), fontSize: 24, fontWeight: FontWeight.bold)
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // 1. Profile Header Hero
            Center(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF09AEF5).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ]
                    ),
                    child: const CircleAvatar(
                      radius: 65,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Color(0xFFE3F2FD),
                        child: Icon(Icons.person_rounded, size: 70, color: Color(0xFF09AEF5)),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF09AEF5), Color(0xFF05398F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ]
                      ),
                      child: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            
            Text("$_title $_firstName $_middleName $_lastName".replaceAll(RegExp(r'\s+'), ' ').trim(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.black87)),
            const SizedBox(height: 4),
            if (_email.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF09AEF5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _email,
                  style: const TextStyle(color: Color(0xFF05398F), fontWeight: FontWeight.bold, fontSize: 13)
                ),
              ),

            const SizedBox(height: 40),

            // 2. Settings Options List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildProfileOption(Icons.menu_book_rounded, "Assigned Courses", Colors.blue),
                  _buildProfileOption(Icons.calendar_month_rounded, "Schedule & Office Hours", Colors.orange),
                  _buildProfileOption(Icons.business_rounded, "Department Information", Colors.green),
                  _buildProfileOption(Icons.settings_rounded, "Account Settings", Colors.grey.shade700),
                  _buildProfileOption(Icons.help_outline_rounded, "Help & Support", Colors.purple),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // 3. Logout Button (Updated Logic)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              child: ElevatedButton.icon(
                onPressed: () async {
                  // PERSISTENCE: Clear all locally stored data
                  final SharedPreferences prefs = await SharedPreferences.getInstance();
                  await prefs.clear();

                  // Ensure the context is still valid before navigating
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const WelcomeScreen()),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F), // Strong professional red
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                  shadowColor: const Color(0xFFD32F2F).withOpacity(0.4),
                ),
                label: const Text("Log Out", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1), 
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87)),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.black38),
              ],
            ),
          ),
        ),
      ),
    );
  }
}