import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import '../auth/welcome_screen.dart';
import 'student_profile_account_screen.dart';
import 'student_profile_downloads_screen.dart';
import 'student_profile_settings_screen.dart';
import 'help_support_screen.dart';
import 'student_profile_ask_question_screen.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  String _title = '';
  String _firstName = '';
  String _middleName = '';
  String _lastName = '';
  String _email = '';
  String _institutionalId = '';

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
      _middleName = prefs.getString('middle_name') ?? '';
      _lastName = prefs.getString('last_name') ?? '';
      _email = prefs.getString('email') ?? 'student@bdu.edu.et';
      _institutionalId = prefs.getString('institutional_id') ?? 'N/A';
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
                        backgroundColor: Color(0xFFE3F2FD), // Profile placeholder
                        child: Icon(Icons.person_outline_rounded, size: 70, color: Color(0xFF09AEF5)),
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
            
            Text("${_title.isNotEmpty ? '$_title ' : ''}$_firstName $_middleName $_lastName".replaceAll(RegExp(r'\s+'), ' ').trim(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.black87)),
            const SizedBox(height: 4),
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
            const SizedBox(height: 4),
            if (_institutionalId.isNotEmpty && _institutionalId != 'N/A')
              Text(
                "ID: $_institutionalId",
                style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w500, fontSize: 13)
              ),

            const SizedBox(height: 40),

            // 2. Settings Options List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildProfileOption(Icons.person_rounded, "Account", Colors.blue, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentProfileAccountScreen()));
                  }),
                  _buildProfileOption(Icons.download_rounded, "Downloads", Colors.green, subtitle: "Manage download memory usage limit", onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentProfileDownloadsScreen()));
                  }),
                  _buildProfileOption(Icons.settings_rounded, "Settings", Colors.grey.shade700, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentProfileSettingsScreen()));
                  }),
                  _buildProfileOption(Icons.security_rounded, "Privacy and Security", Colors.red, onTap: () {}),
                  _buildProfileOption(Icons.help_outline_rounded, "Support and Help (FAQ)", Colors.purple, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen()));
                  }),
                  _buildProfileOption(Icons.question_answer_rounded, "Ask a Question", Colors.orange, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentProfileAskQuestionScreen()));
                  }),
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

  Widget _buildProfileOption(IconData icon, String title, Color color, {String? subtitle, VoidCallback? onTap}) {
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
          onTap: onTap ?? () {},
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.black87)),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      ]
                    ],
                  ),
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
