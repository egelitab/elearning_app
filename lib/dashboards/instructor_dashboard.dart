import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'instructor_home_screen.dart';
import 'instructor_courses_screen.dart';
import 'instructor_inbox_screen.dart';
import 'instructor_files_screen.dart';
import 'instructor_profile_screen.dart';
import '../services/api_service.dart';

class InstructorDashboard extends StatefulWidget {
  const InstructorDashboard({super.key});
  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
  int _index = 0;
  DateTime? currentBackPressTime;
  final ApiService _apiService = ApiService();

  // Instructors only get chat badge on Inbox tab.
  // System notifications are handled by the bell icon in InstructorHomeScreen.
  int _chatUnread = 0;

  Timer? _pollTimer;

  late final List<Widget> _screens = [
    const InstructorHomeScreen(),
    const InstructorCoursesScreen(),
    const InstructorInboxScreen(),
    const InstructorFilesScreen(),
    InstructorProfileScreen(onBack: () => setState(() => _index = 0)),
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
          // system unread is handled by the bell icon in InstructorHomeScreen
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
        body: _screens[_index],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, -5),
              )
            ],
          ),
          child: BottomNavigationBar(
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            currentIndex: _index,
            selectedItemColor: const Color(0xFF09AEF5),
            unselectedItemColor: Colors.grey.shade400,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
            onTap: (i) {
              setState(() => _index = i);
              if (i == 2 && _chatUnread > 0) setState(() => _chatUnread = 0);
            },
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.book_outlined),
                activeIcon: Icon(Icons.book),
                label: 'Courses',
              ),
              BottomNavigationBarItem(
                icon: _badgeIcon(const Icon(Icons.chat_bubble_outline), _chatUnread),
                activeIcon: _badgeIcon(const Icon(Icons.chat_bubble), _chatUnread),
                label: 'Inbox',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.folder_outlined),
                activeIcon: Icon(Icons.folder),
                label: 'Files',
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
  }
}