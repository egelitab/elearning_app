import 'package:flutter/material.dart';

class StudentProfileSettingsScreen extends StatefulWidget {
  const StudentProfileSettingsScreen({super.key});

  @override
  State<StudentProfileSettingsScreen> createState() => _StudentProfileSettingsScreenState();
}

class _StudentProfileSettingsScreenState extends State<StudentProfileSettingsScreen> {
  String _fontSize = 'Medium';
  String _layoutView = 'Grid';
  bool _isSilent = false;
  List<String> _silentExceptions = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(color: Color(0xFF05398F), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF4F7FC),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF05398F)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "App Preferences",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 30),
            
            // Font Size Setting
            _buildSectionHeader("Font Size"),
            _buildRadioGroup(
              options: ['Small', 'Medium', 'Large'],
              groupValue: _fontSize,
              onChanged: (val) => setState(() => _fontSize = val!),
            ),
            const SizedBox(height: 30),

            // Layout View Setting
            _buildSectionHeader("Courses Layout View"),
            Row(
              children: [
                _buildLayoutButton('Grid', Icons.grid_view_rounded),
                const SizedBox(width: 16),
                _buildLayoutButton('List', Icons.view_list_rounded),
              ],
            ),
            const SizedBox(height: 30),

            // Notification / Silent Preference Setting
            _buildSectionHeader("Silent Mode"),
            Container(
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
              child: SwitchListTile(
                title: const Text("Enable Silent Mode", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                subtitle: const Text("Mute notifications based on exceptions", style: TextStyle(fontSize: 12, color: Colors.black54)),
                value: _isSilent,
                activeColor: const Color(0xFF09AEF5),
                onChanged: (val) => setState(() => _isSilent = val),
              ),
            ),
            
            if (_isSilent) ...[
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.only(left: 8.0, bottom: 8.0),
                child: Text("Allow Exceptions For (Check to allow):", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54)),
              ),
              _buildCheckboxGroup(['Chats', 'Only Announcements', 'System Notification', 'All']),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
    );
  }

  Widget _buildLayoutButton(String layoutName, IconData icon) {
    bool isSelected = _layoutView == layoutName;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _layoutView = layoutName),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF09AEF5).withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF09AEF5) : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? const Color(0xFF09AEF5) : Colors.grey.shade500, size: 30),
              const SizedBox(height: 8),
              Text(
                layoutName, 
                style: TextStyle(
                  color: isSelected ? const Color(0xFF09AEF5) : Colors.grey.shade600,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                )
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioGroup({required List<String> options, required String groupValue, required ValueChanged<String?> onChanged}) {
    return Container(
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
      child: Column(
        children: options.map((option) {
          return RadioListTile<String>(
            title: Text(option, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            value: option,
            groupValue: groupValue,
            activeColor: const Color(0xFF09AEF5),
            onChanged: onChanged,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCheckboxGroup(List<String> options) {
    return Container(
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
      child: Column(
        children: options.map((option) {
          return CheckboxListTile(
            title: Text(option, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            value: _silentExceptions.contains(option),
            activeColor: const Color(0xFF09AEF5),
            onChanged: (bool? checked) {
              setState(() {
                if (checked == true) {
                  // If 'All' is checked, uncheck others or just add 'All'
                  if (option == 'All') {
                    _silentExceptions = ['All'];
                  } else {
                    _silentExceptions.remove('All');
                    _silentExceptions.add(option);
                  }
                } else {
                  _silentExceptions.remove(option);
                }
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          );
        }).toList(),
      ),
    );
  }
}
