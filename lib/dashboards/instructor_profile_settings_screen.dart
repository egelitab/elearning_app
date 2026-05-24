import 'package:flutter/material.dart';
import 'account_settings_screen.dart';
import 'instructor_notification_settings_screen.dart';
import 'app_preferences_screen.dart';
import 'student_profile_downloads_screen.dart';

class InstructorProfileSettingsScreen extends StatefulWidget {
  const InstructorProfileSettingsScreen({super.key});

  @override
  State<InstructorProfileSettingsScreen> createState() => _InstructorProfileSettingsScreenState();
}

class _InstructorProfileSettingsScreenState extends State<InstructorProfileSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(color: Color(0xFF05398F), fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF05398F)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            
            // Primary Categories
            _buildSettingsGroup([
              _buildSettingsTile(
                icon: Icons.person_rounded,
                iconColor: Colors.blue,
                title: "Account",
                subtitle: "Profile, Security, Email",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AccountSettingsScreen()),
                  );
                },
              ),
              _buildSettingsTile(
                icon: Icons.notifications_rounded,
                iconColor: Colors.redAccent,
                title: "Notifications",
                subtitle: "Manage alerts and system updates",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const InstructorNotificationSettingsScreen()),
                  );
                },
              ),
              _buildSettingsTile(
                icon: Icons.tune_rounded,
                iconColor: Colors.teal,
                title: "App Preferences",
                subtitle: "Theme, Font Size, Date/Time",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AppPreferencesScreen()),
                  );
                },
              ),
              _buildSettingsTile(
                icon: Icons.download_for_offline_rounded,
                iconColor: Colors.amber,
                title: "Offline Media",
                subtitle: "Manage offline storage & limits",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StudentProfileDownloadsScreen()),
                  );
                },
              ),
            ]),

            const SizedBox(height: 32),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 13, 
          fontWeight: FontWeight.w700, 
          color: Colors.blueGrey,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        children: List.generate(children.length, (index) {
          if (index == children.length - 1) return children[index];
          return Column(
            children: [
              children[index],
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Divider(height: 1, color: Color(0xFFF1F5F9)),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
      ),
      subtitle: subtitle != null 
          ? Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.black54))
          : null,
      trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 14),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
