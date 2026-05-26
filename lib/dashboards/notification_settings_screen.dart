import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../main.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  
  bool _notifyChat = true;
  bool _notifyAnnouncement = true;
  bool _notifyMaterialTask = true;
  bool _notifySystem = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _apiService.getNotificationSettings();
      setState(() {
        _notifyChat = settings['notify_chat'] ?? true;
        _notifyAnnouncement = settings['notify_announcement'] ?? true;
        _notifyMaterialTask = settings['notify_material_task'] ?? true;
        _notifySystem = settings['notify_system'] ?? true;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load settings: $e")),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    // Optimistic update
    setState(() {
      if (key == 'notify_chat') _notifyChat = value;
      if (key == 'notify_announcement') _notifyAnnouncement = value;
      if (key == 'notify_material_task') _notifyMaterialTask = value;
      if (key == 'notify_system') _notifySystem = value;
    });

    try {
      await _apiService.updateNotificationSettings({key: value});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update setting: $e")),
        );
      }
      // Revert if failed
      setState(() {
        if (key == 'notify_chat') _notifyChat = !value;
        if (key == 'notify_announcement') _notifyAnnouncement = !value;
        if (key == 'notify_material_task') _notifyMaterialTask = !value;
        if (key == 'notify_system') _notifySystem = !value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDark, _) => Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: AppBar(
          title: Text('Notification Settings', style: TextStyle(color: AppColors.appBarForeground, fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.appBar,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.appBarForeground),
        ),
        body: _isLoading 
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Preferences",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Choose which notifications you'd like to receive on this device.",
                    style: TextStyle(fontSize: 14, color: AppColors.secondaryText),
                  ),
                  const SizedBox(height: 25),
                  
                  _buildToggleCard(
                    title: "Chat Messages",
                    subtitle: "Direct and group chat notifications",
                    icon: Icons.chat_bubble_outline_rounded,
                    iconColor: Colors.blue,
                    value: _notifyChat,
                    onChanged: (val) => _updateSetting('notify_chat', val),
                  ),
                  
                  _buildToggleCard(
                    title: "Announcements",
                    subtitle: "Important updates from your instructors",
                    icon: Icons.campaign_outlined,
                    iconColor: Colors.orange,
                    value: _notifyAnnouncement,
                    onChanged: (val) => _updateSetting('notify_announcement', val),
                  ),
                  
                  _buildToggleCard(
                    title: "New Material & Tasks",
                    subtitle: "Notifications for new course materials and assignments",
                    icon: Icons.assignment_outlined,
                    iconColor: Colors.green,
                    value: _notifyMaterialTask,
                    onChanged: (val) => _updateSetting('notify_material_task', val),
                  ),
                  
                  _buildToggleCard(
                    title: "System Notifications",
                    subtitle: "Security alerts and system updates",
                    icon: Icons.notifications_none_rounded,
                    iconColor: Colors.redAccent,
                    value: _notifySystem,
                    onChanged: (val) => _updateSetting('notify_system', val),
                  ),
  
                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      "Settings are automatically saved",
                      style: TextStyle(fontSize: 12, color: AppColors.secondaryText.withOpacity(0.5), fontStyle: FontStyle.italic),
                    ),
                  )
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primaryText)),
        subtitle: Text(subtitle, style: TextStyle(fontSize: 13, color: AppColors.secondaryText)),
        value: value,
        activeColor: const Color(0xFF09AEF5),
        onChanged: onChanged,
      ),
    );
  }
}
