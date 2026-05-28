import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../auth/welcome_screen.dart';
import 'student_profile_settings_screen.dart';
import 'help_support_screen.dart';
import 'privacy_security_screen.dart';
import 'send_feedback_screen.dart';
import 'about_lms_screen.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../main.dart';

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
  String _gpa = 'N/A';
  String _userRole = '';
  String? _profileImagePath;
  bool _isLoading = true;
  bool _isOnline = true; // Assume online if the user is in the profile screen
  int _totalStars = 0;
  Map<String, dynamic>? _fullProfile;
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
        if (_title == '[null]' || _title == 'None') _title = '';
        _firstName = prefs.getString('first_name') ?? '';
        _middleName = prefs.getString('middle_name') ?? '';
        _lastName = prefs.getString('last_name') ?? '';
        _email = prefs.getString('email') ?? '';
        _institutionalId = prefs.getString('institutional_id') ?? 'N/A';
        _gpa = prefs.getString('gpa') ?? 'N/A';
        _userRole = prefs.getString('user_role') ?? 'student';
        _profileImagePath = prefs.getString('profile_image_path');
        _isLoading = true;
      });

      try {
        // Fetch full profile from backend to get all details (department, sex, etc.)
        final fullProfile = await _apiService.getUserProfile();
        final stars = await _apiService.getStudentStarCount();

        if (mounted) {
          setState(() {
            _fullProfile = fullProfile;
            _totalStars = stars;
            _isLoading = false;

            // Update basic info from full profile if available
            _firstName = fullProfile['first_name'] ?? _firstName;
            _lastName = fullProfile['last_name'] ?? _lastName;
            _middleName = fullProfile['middle_name'] ?? _middleName;
            _title = fullProfile['title'] ?? _title;
            if (_title == 'None' || _title == '[null]') _title = '';
            _email = fullProfile['email'] ?? _email;
            _institutionalId = fullProfile['institutional_id'] ?? _institutionalId;
            _gpa = fullProfile['gpa']?.toString() ?? _gpa;
          });
        }
      } catch (e) {
        print("Error fetching full profile: $e");
        if (mounted) setState(() => _isLoading = false);
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
        final String fileName =
            'profile_picture_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final File localImage = await file.copy('${directory.path}/$fileName');

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image_path', localImage.path);

        setState(() {
          _profileImagePath = localImage.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDark, _) {
        return Scaffold(
          backgroundColor: AppColors.scaffold,
          appBar: AppBar(
            backgroundColor: AppColors.appBar,
            elevation: 0,
            centerTitle: false,
            title: Text(
              "Profile",
              style: TextStyle(
                color: AppColors.appBarForeground,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.appBarForeground,
                ),
                onPressed: _showInfoBottomSheet,
              ),

              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "$_totalStars",
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
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
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 65,
                          backgroundColor:
                              isDark ? const Color(0xFF2C2C2C) : Colors.white,
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: const Color(
                              0xFFE3F2FD,
                            ), // Profile placeholder
                            backgroundImage: _profileImagePath != null
                                ? FileImage(File(_profileImagePath!))
                                : null,
                            child: _profileImagePath == null
                                ? Icon(
                                    Icons.person_rounded,
                                    size: 70,
                                    color: Theme.of(context).primaryColor,
                                  )
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
                              color: const Color(
                                0xFF4CAF50,
                              ), // Vibrant online green
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF121212)
                                    : Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF4CAF50).withOpacity(0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
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
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).primaryColor,
                                  Theme.of(context).colorScheme.secondary,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF121212)
                                    : Colors.white,
                                width: 3,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
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
                  Text(
                    "${_title.isNotEmpty ? '$_title ' : ''}$_firstName $_middleName"
                        .replaceAll(RegExp(r'\s+'), ' ')
                        .trim(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryText,
                    ),
                  ),

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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _email,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                ],

                const SizedBox(height: 10),
                if (_userRole == 'student' && _gpa != 'N/A')
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade700, Colors.blue.shade400],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.school, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          "GPA: $_gpa",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 40),

                // 2. Settings Options List
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildProfileOption(
                        Icons.settings_rounded,
                        "Settings",
                        Colors.grey.shade700,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const StudentProfileSettingsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildProfileOption(
                        Icons.security_rounded,
                        "Privacy and Security",
                        Colors.red,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const PrivacySecurityScreen(),
                            ),
                          );
                        },
                      ),
                      _buildProfileOption(
                        Icons.help_outline_rounded,
                        "Help Center",
                        Colors.purple,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HelpSupportScreen(),
                            ),
                          );
                        },
                      ),
                      _buildProfileOption(
                        Icons.feedback_outlined,
                        "Send Feedback",
                        Colors.teal,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SendFeedbackScreen(),
                            ),
                          );
                        },
                      ),
                      _buildProfileOption(
                        Icons.info_outline_rounded,
                        "About ELMS",
                        Colors.blueGrey,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AboutLmsScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // 3. Logout Button (Updated Logic)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      // PERSISTENCE: Clear locally stored data except notification states
                      final SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      final keys = prefs.getKeys();
                      for (final key in keys) {
                        if (!key
                            .startsWith('system_notifications_opened_ids_')) {
                          await prefs.remove(key);
                        }
                      }

                      // Ensure the context is still valid before navigating
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const WelcomeScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFFD32F2F,
                      ), // Strong professional red
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 5,
                      shadowColor: const Color(0xFFD32F2F).withOpacity(0.4),
                    ),
                    label: const Text(
                      "Log Out",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileOption(
    IconData icon,
    String title,
    Color color, {
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
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
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppColors.labelText,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryText,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.navUnselected,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInfoBottomSheet() {
    if (_fullProfile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile information still loading...")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ListView(
            controller: controller,
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.badge_rounded,
                      color: Theme.of(context).primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "User Information",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              _buildInfoSection("Basic Information", [
                _buildInfoRow(Icons.person_outline, "Full Name",
                    "${_fullProfile!['title'] != null && _fullProfile!['title'] != '[null]' && _fullProfile!['title'] != 'None' ? _fullProfile!['title'] + ' ' : ''}${_fullProfile!['first_name'] ?? ''} ${_fullProfile!['middle_name'] ?? ''} ${_fullProfile!['last_name'] ?? ''}"),
                _buildInfoRow(Icons.email_outlined, "Email",
                    _fullProfile!['email'] ?? 'N/A'),
                _buildInfoRow(Icons.fingerprint_rounded, "Institutional ID",
                    _fullProfile!['institutional_id'] ?? 'N/A'),
                _buildInfoRow(Icons.phone_android_rounded, "Phone Number",
                    _fullProfile!['phone_number'] ?? 'N/A'),
                _buildInfoRow(Icons.wc_rounded, "Sex",
                    _fullProfile!['sex'] ?? 'N/A'),
              ]),
              const SizedBox(height: 24),
              _buildInfoSection("Academic Information", [
                _buildInfoRow(Icons.account_balance_rounded, "Faculty",
                    _fullProfile!['faculty_name'] ?? 'N/A'),
                _buildInfoRow(Icons.business_rounded, "Department",
                    _fullProfile!['department_name'] ?? 'N/A'),
                _buildInfoRow(Icons.groups_rounded, "Section",
                    _fullProfile!['section']?.toString() ?? 'N/A'),
                _buildInfoRow(Icons.calendar_today_rounded, "Year / Semester",
                    "${_fullProfile!['year'] ?? 'N/A'} / ${_fullProfile!['semester'] ?? 'N/A'}"),
                if (_userRole == 'student')
                  _buildInfoRow(Icons.grade_rounded, "Current GPA",
                      _fullProfile!['gpa']?.toString() ?? 'N/A'),
              ]),
              const SizedBox(height: 24),
              _buildInfoSection("Account Status", [
                _buildInfoRow(Icons.verified_user_rounded, "Role",
                    _fullProfile!['role']?.toString().toUpperCase() ?? 'N/A'),
                _buildInfoRow(Icons.power_settings_new_rounded, "Status",
                    _fullProfile!['account_status']?.toString().toUpperCase() ??
                        'N/A'),
                _buildInfoRow(Icons.alternate_email_rounded, "Recovery Email",
                    _fullProfile!['recovery_email'] ?? 'N/A'),
              ]),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor.withOpacity(0.8),
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade500),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

