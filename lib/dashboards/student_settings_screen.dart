import 'package:flutter/material.dart';

class StudentSettingsScreen extends StatefulWidget {
  const StudentSettingsScreen({super.key});

  @override
  State<StudentSettingsScreen> createState() => _StudentSettingsScreenState();
}

class _StudentSettingsScreenState extends State<StudentSettingsScreen> {
  // Notification Behavior
  bool _silentMode = false;
  bool _dailyDigest = true;
  String _priorityOverrides = 'Core Classes';

  // Display & Dashboard
  String _dashboardView = 'Card View';
  bool _darkMode = false;

  // Accessibility
  double _fontScaling = 1.0;
  bool _dyslexicFont = false;

  // Automation
  bool _autoDownload = true;
  bool _wifiOnlySync = true;

  // Track recent changes for auto-save indicators
  final Map<String, bool> _justSaved = {};

  void _triggerAutoSave(String key) {
    setState(() {
      _justSaved[key] = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _justSaved[key] = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Settings & Preferences",
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Notification Behavior"),
            _buildSettingsCard(
              children: [
                _buildToggleRow("Silent Mode", "Mute all standard notifications", Icons.notifications_off_outlined, _silentMode, (val) {
                  setState(() => _silentMode = val);
                  _triggerAutoSave('silentMode');
                }, 'silentMode'),
                const Divider(height: 1),
                _buildToggleRow("Daily Digest", "Receive one summary email per day", Icons.email_outlined, _dailyDigest, (val) {
                  setState(() => _dailyDigest = val);
                  _triggerAutoSave('dailyDigest');
                }, 'dailyDigest'),
                const Divider(height: 1),
                _buildDropdownRow("Priority Overrides", "Allow these to bypass silent mode", Icons.priority_high_rounded, _priorityOverrides, ['None', 'Core Classes', 'All Classes'], (val) {
                  setState(() => _priorityOverrides = val!);
                  _triggerAutoSave('priorityOverrides');
                }, 'priorityOverrides'),
              ],
            ),
            
            const SizedBox(height: 28),
            _buildSectionHeader("Display & Dashboard"),
            _buildSettingsCard(
              children: [
                _buildDropdownRow("Default View", "Dashboard layout style", Icons.dashboard_outlined, _dashboardView, ['Card View', 'List View'], (val) {
                  setState(() => _dashboardView = val!);
                  _triggerAutoSave('dashboardView');
                }, 'dashboardView'),
                const Divider(height: 1),
                _buildToggleRow("Dark Mode", "Toggle low-light theme", Icons.dark_mode_outlined, _darkMode, (val) {
                  setState(() => _darkMode = val);
                  _triggerAutoSave('darkMode');
                }, 'darkMode'),
              ],
            ),

            const SizedBox(height: 28),
            _buildSectionHeader("Accessibility"),
            _buildSettingsCard(
              children: [
                _buildSliderRow("Font Scaling", "Adjust text size globally", Icons.format_size_rounded, _fontScaling, 0.8, 1.5, (val) {
                  setState(() => _fontScaling = val);
                  _triggerAutoSave('fontScaling');
                }, 'fontScaling'),
                const Divider(height: 1),
                _buildToggleRow("Dyslexic Font", "Use specialized readable font", Icons.text_fields_rounded, _dyslexicFont, (val) {
                  setState(() => _dyslexicFont = val);
                  _triggerAutoSave('dyslexicFont');
                }, 'dyslexicFont'),
              ],
            ),

            const SizedBox(height: 28),
            _buildSectionHeader("Automation"),
            _buildSettingsCard(
              children: [
                _buildToggleRow("Auto-Download", "Automatically fetch course materials", Icons.download_done_rounded, _autoDownload, (val) {
                  setState(() => _autoDownload = val);
                  _triggerAutoSave('autoDownload');
                }, 'autoDownload'),
                const Divider(height: 1),
                _buildToggleRow("Wi-Fi Only Sync", "Restrict background sync to Wi-Fi", Icons.wifi_rounded, _wifiOnlySync, (val) {
                  setState(() => _wifiOnlySync = val);
                  _triggerAutoSave('wifiOnlySync');
                }, 'wifiOnlySync'),
              ],
            ),
            
            const SizedBox(height: 40),
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
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: Color(0xFF64748B), // slate-500
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)), // slate-200
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildAutoSaveIndicator(String key) {
    bool isSaving = _justSaved[key] ?? false;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isSaving ? 1.0 : 0.0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Text("Saved", style: TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
          SizedBox(width: 4),
          Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 14),
        ],
      ),
    );
  }

  Widget _buildToggleRow(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged, String saveKey) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9), // slate-100
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF0F172A), size: 22),
      ),
      title: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
          const SizedBox(width: 8),
          _buildAutoSaveIndicator(saveKey),
        ],
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF3B5BFF),
        activeTrackColor: const Color(0xFF3B5BFF).withOpacity(0.2),
      ),
    );
  }

  Widget _buildDropdownRow(String title, String subtitle, IconData icon, String currentValue, List<String> options, ValueChanged<String?> onChanged, String saveKey) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF0F172A), size: 22),
      ),
      title: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
          const SizedBox(width: 8),
          _buildAutoSaveIndicator(saveKey),
        ],
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: currentValue,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFF64748B)),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0F172A)),
            onChanged: onChanged,
            items: options.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSliderRow(String title, String subtitle, IconData icon, double value, double min, double max, ValueChanged<double> onChanged, String saveKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: const Color(0xFF0F172A), size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                          const SizedBox(width: 8),
                          _buildAutoSaveIndicator(saveKey),
                        ],
                      ),
                      Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                Text("${(value * 100).toInt()}%", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF3B5BFF))),
              ],
            ),
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: const Color(0xFF3B5BFF),
              inactiveTrackColor: const Color(0xFFE2E8F0),
              thumbColor: const Color(0xFF3B5BFF),
              overlayColor: const Color(0xFF3B5BFF).withOpacity(0.1),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
