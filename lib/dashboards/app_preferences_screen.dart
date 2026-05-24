import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/date_helper.dart';

class AppPreferencesScreen extends StatefulWidget {
  const AppPreferencesScreen({super.key});

  @override
  State<AppPreferencesScreen> createState() => _AppPreferencesScreenState();
}

class _AppPreferencesScreenState extends State<AppPreferencesScreen> {
  String _fontSize = 'Medium';
  bool _darkMode = false;
  String _calendarFormat = 'Global';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getString('pref_font_size') ?? 'Medium';
      _darkMode = prefs.getBool('pref_dark_mode') ?? false;
      _calendarFormat = prefs.getString('pref_calendar_format') ?? 'Global';
    });
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('App Preferences', style: TextStyle(color: Color(0xFF05398F), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF05398F)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Mode
            const Text("Appearance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildPreferenceCard(
              child: SwitchListTile(
                secondary: Icon(Icons.dark_mode_rounded, color: Colors.indigo.shade700),
                title: const Text("Dark Theme", style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text("Enable dark interface"),
                value: _darkMode,
                activeColor: const Color(0xFF09AEF5),
                onChanged: (val) {
                  setState(() => _darkMode = val);
                  _savePreference('pref_dark_mode', val);
                },
              ),
            ),

            const SizedBox(height: 30),
            
            // Font Size
            const Text("Typography", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildPreferenceCard(
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.text_fields_rounded, color: Colors.purple),
                    title: Text("Font Size", style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text("Adjust text clarity"),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: ['Small', 'Medium', 'Large'].map((size) {
                        bool isSelected = _fontSize == size;
                        return ChoiceChip(
                          label: Text(size),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _fontSize = size);
                              _savePreference('pref_font_size', size);
                            }
                          },
                          selectedColor: const Color(0xFF09AEF5).withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: isSelected ? const Color(0xFF09AEF5) : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Regional Settings
            const Text("Regional Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildPreferenceCard(
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(Icons.calendar_month_rounded, color: Colors.orange),
                    title: Text("Date & Time Format", style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text("Switch between Global and Ethiopian calendars"),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: ['Global', 'Ethiopian'].map((format) {
                        bool isSelected = _calendarFormat == format;
                        return ChoiceChip(
                          label: Text(format),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _calendarFormat = format);
                              _savePreference('pref_calendar_format', format).then((_) {
                                DateHelper.refresh();
                              });
                            }
                          },
                          selectedColor: const Color(0xFFF57C00).withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: isSelected ? const Color(0xFFF57C00) : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: child,
    );
  }
}
