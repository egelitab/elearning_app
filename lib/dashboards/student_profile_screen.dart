import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart'; 
import '../auth/welcome_screen.dart';
import 'student_profile_settings_screen.dart';
import 'help_support_screen.dart';
import '../services/api_service.dart';


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
  String? _profileImagePath;
  bool _isLoading = true;
  bool _isOnline = true; // Assume online if the user is in the profile screen
  int _totalStars = 0;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _title = prefs.getString('title') ?? '';
        if (_title == 'None') _title = '';
        _firstName = prefs.getString('first_name') ?? '';
        _middleName = prefs.getString('middle_name') ?? '';
        _lastName = prefs.getString('last_name') ?? '';
        _email = prefs.getString('email') ?? '';
        _institutionalId = prefs.getString('institutional_id') ?? 'N/A';
        _profileImagePath = prefs.getString('profile_image_path');
        _isLoading = false;
      });
      // Fetch stars from backend
      try {
        final stars = await _apiService.getStudentStarCount();
        if (mounted) setState(() => _totalStars = stars);
      } catch (e) {
        print("Error fetching profile stars: $e");
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
      );
      if (result != null && result.files.single.path != null) {
        final File file = File(result.files.single.path!);
        final directory = await getApplicationDocumentsDirectory();
        final String fileName = 'profile_picture_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final File localImage = await file.copy('${directory.path}/$fileName');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image_path', localImage.path);

        setState(() {
          _profileImagePath = localImage.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.orange.withOpacity(0.3))
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.orange, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      "$_totalStars",
                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
                    child: CircleAvatar(
                      radius: 65,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: const Color(0xFFE3F2FD), // Profile placeholder
                        backgroundImage: _profileImagePath != null ? FileImage(File(_profileImagePath!)) : null,
                        child: _profileImagePath == null
                            ? const Icon(Icons.person_rounded, size: 70, color: Color(0xFF09AEF5))
                            : null,
                      ),
                    ),
                  ),
                  if (_isOnline)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50), // Vibrant online green
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4CAF50).withOpacity(0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 4,
                      child: InkWell(
                        onTap: _pickImage,
                        borderRadius: BorderRadius.circular(30),
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
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            
            if (_isLoading)
               Container(
                 margin: const EdgeInsets.symmetric(vertical: 10),
                 height: 30,
                 width: 200,
                 decoration: BoxDecoration(
                   color: Colors.grey.shade200,
                   borderRadius: BorderRadius.circular(8),
                 ),
               )
            else
              Text("${_title.isNotEmpty ? '$_title ' : ''}$_firstName $_middleName $_lastName".replaceAll(RegExp(r'\s+'), ' ').trim(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.black87)),
            
            const SizedBox(height: 4),
            
            if (_isLoading)
              Container(
                 margin: const EdgeInsets.symmetric(vertical: 5),
                 height: 20,
                 width: 150,
                 decoration: BoxDecoration(
                   color: Colors.grey.shade200,
                   borderRadius: BorderRadius.circular(8),
                 ),
               )
            else ...[
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
            ],

            const SizedBox(height: 40),

            // 2. Settings Options List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildProfileOption(Icons.settings_rounded, "Settings", Colors.grey.shade700, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentProfileSettingsScreen()));
                  }),
                  _buildProfileOption(Icons.security_rounded, "Privacy and Security", Colors.red, onTap: () {}),
                  _buildProfileOption(Icons.help_outline_rounded, "Help Center", Colors.purple, onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen()));
                  }),
                  _buildProfileOption(Icons.feedback_outlined, "Send Feedback", Colors.teal, onTap: () {}),
                  _buildProfileOption(Icons.info_outline_rounded, "About ELMS", Colors.blueGrey, onTap: () {}),

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
