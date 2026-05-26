import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'student_home_screen.dart';
import 'student_courses_screen.dart';
import 'student_inbox_screen.dart';
import 'student_downloads_screen.dart';
import 'student_profile_screen.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../main.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _index = 0;
  DateTime? currentBackPressTime;
  final ApiService _apiService = ApiService();

  // Badge counts
  int _chatUnread = 0;         // Inbox tab  ← new chat messages
  int _announcementUnread = 0; // Home tab   ← course announcements
  int _materialUnread = 0;     // Courses tab ← new materials/tasks

  Timer? _pollTimer;

  final List<Widget> _screens = [
    const StudentHomeScreen(),
    const StudentCoursesScreen(),
    const StudentInboxScreen(),
    const StudentDownloadsScreen(),
    const StudentProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fetchBadges();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchBadges());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchBadges() async {
    try {
      final counts = await _apiService.getUnreadNotificationCounts();
      if (mounted) {
        setState(() {
          _chatUnread = counts['chat'] ?? 0;
          _announcementUnread = counts['announcement'] ?? 0;
          _materialUnread = counts['material'] ?? 0;
          // Note: system unread is handled by the bell icon in StudentHomeScreen
        });
      }
    } catch (_) {}
  }

  Widget _badgeIcon(Widget icon, int count) {
    if (count == 0) return icon;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          top: -4,
          right: -6,
          child: Container(
            padding: const EdgeInsets.all(2),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              shape: BoxShape.circle,
            ),
            child: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDark, _) {
        return WillPopScope(
          onWillPop: () async {
            DateTime now = DateTime.now();
            if (currentBackPressTime == null ||
                now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
              currentBackPressTime = now;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Press back again to exit')),
              );
              return Future.value(false);
            }
            SystemNavigator.pop();
            return Future.value(true);
          },
          child: Scaffold(
            backgroundColor: AppColors.scaffold,
            body: _screens[_index],
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: AppColors.navBar,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              child: BottomNavigationBar(
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                backgroundColor: AppColors.navBar,
                currentIndex: _index,
                selectedItemColor: AppColors.navSelected,
                unselectedItemColor: AppColors.navUnselected,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
                onTap: (i) {
                  setState(() => _index = i);
                  if (i == 0 && _announcementUnread > 0) setState(() => _announcementUnread = 0);
                  if (i == 1 && _materialUnread > 0) setState(() => _materialUnread = 0);
                  if (i == 2 && _chatUnread > 0) setState(() => _chatUnread = 0);
                },
                items: [
                  BottomNavigationBarItem(
                    icon: _badgeIcon(const Icon(Icons.home_outlined), _announcementUnread),
                    activeIcon: _badgeIcon(const Icon(Icons.home), _announcementUnread),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: _badgeIcon(const Icon(Icons.book_outlined), _materialUnread),
                    activeIcon: _badgeIcon(const Icon(Icons.book), _materialUnread),
                    label: 'Courses',
                  ),
                  BottomNavigationBarItem(
                    icon: _badgeIcon(const Icon(Icons.chat_bubble_outline), _chatUnread),
                    activeIcon: _badgeIcon(const Icon(Icons.chat_bubble), _chatUnread),
                    label: 'Inbox',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.download_for_offline_outlined),
                    activeIcon: Icon(Icons.download_for_offline_outlined),
                    label: 'Downloads',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}