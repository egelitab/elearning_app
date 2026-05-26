import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/date_helper.dart';
import '../utils/app_colors.dart';
import '../main.dart';

class AppPreferencesScreen extends StatefulWidget {
  const AppPreferencesScreen({super.key});

  @override
  State<AppPreferencesScreen> createState() => _AppPreferencesScreenState();
}

class _AppPreferencesScreenState extends State<AppPreferencesScreen> {
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
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDark, _) => Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: AppBar(
          title: Text('App Preferences', style: TextStyle(color: AppColors.appBarForeground, fontWeight: FontWeight.bold)),
          backgroundColor: AppColors.appBar,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.appBarForeground),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Theme Mode
              Text("Appearance", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
              const SizedBox(height: 15),
              _buildPreferenceCard(
                child: SwitchListTile(
                  secondary: Icon(Icons.dark_mode_rounded, color: isDark ? const Color(0xFF09AEF5) : Colors.indigo.shade700),
                  title: Text("Dark Theme", style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryText)),
                  subtitle: Text("Enable dark interface", style: TextStyle(color: AppColors.secondaryText)),
                  value: _darkMode,
                  activeColor: const Color(0xFF09AEF5),
                  onChanged: (val) {
                    setState(() => _darkMode = val);
                    _savePreference('pref_dark_mode', val);
                    darkModeNotifier.value = val;
                  },
                ),
              ),
              const SizedBox(height: 30),
  
              // Regional Settings
              Text("Regional Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
              const SizedBox(height: 15),
              _buildPreferenceCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.calendar_month_rounded, color: Colors.orange),
                      title: Text("Date & Time Format", style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primaryText)),
                      subtitle: Text("Switch between Global and Ethiopian calendars", style: TextStyle(color: AppColors.secondaryText)),
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
                              color: isSelected ? const Color(0xFFF57C00) : AppColors.primaryText,
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
      ),
    );
  }

  Widget _buildPreferenceCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: child,
    );
  }
}
