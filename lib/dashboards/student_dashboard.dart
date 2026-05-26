import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  int _chatUnread = 0; // Inbox tab  ← new chat messages
  int _announcementUnread = 0; // Home tab   ← course announcements
  int _materialUnread = 0; // Courses tab ← new materials/tasks

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
    _pollTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _fetchBadges(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchBadges() async {
    try {
      // 1. Server-side push notification counts
      final counts = await _apiService.getUnreadNotificationCounts();

      // 2. Local SharedPreferences counts (same keys as StudentInboxScreen)
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email') ?? 'default';

      // -- Chats: count group_id entries not yet in opened set
      final openedChatIds =
          (prefs.getStringList('student_inbox_opened_chats_$email') ?? [])
              .toSet();
      final inbox = await _apiService.getGroupInbox();
      final localUnreadChats = inbox
          .where((c) {
            final id = c['group_id']?.toString() ?? '';
            return id.isNotEmpty && !openedChatIds.contains(id);
          })
          .length;

      // -- Announcements: count announcement ids not yet in opened set
      final openedAnnIds =
          (prefs.getStringList(
                  'student_inbox_opened_announcements_$email') ??
              [])
              .toSet();
      final announcements = await _apiService.getAnnouncements('student');
      final localUnreadAnn = announcements
          .where((a) {
            final id = a['id']?.toString() ?? a['created_at']?.toString() ?? '';
            return id.isNotEmpty && !openedAnnIds.contains(id);
          })
          .length;

      if (mounted) {
        setState(() {
          // Inbox icon  = max of server chat count OR local unread chats
          _chatUnread =
              localUnreadChats > (counts['chat'] ?? 0)
                  ? localUnreadChats
                  : (counts['chat'] ?? 0);
          // Home icon   = max of server announcement count OR local unread anns
          _announcementUnread =
              localUnreadAnn > (counts['announcement'] ?? 0)
                  ? localUnreadAnn
                  : (counts['announcement'] ?? 0);
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
                now.difference(currentBackPressTime!) >
                    const Duration(seconds: 2)) {
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
                  ),
                ],
              ),
              child: BottomNavigationBar(
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                backgroundColor: AppColors.navBar,
                currentIndex: _index,
                selectedItemColor: AppColors.navSelected,
                unselectedItemColor: AppColors.navUnselected,
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
                onTap: (i) {
                  setState(() => _index = i);
                  // Only clear the in-memory badge for the current session.
                  // SharedPreferences is written only when the student
                  // actually opens an item inside the Inbox screen — or uses
                  // the "Mark all read" button inside System Notifications.
                  if (i == 0 && _announcementUnread > 0)
                    setState(() => _announcementUnread = 0);
                  if (i == 1 && _materialUnread > 0)
                    setState(() => _materialUnread = 0);
                  if (i == 2 && _chatUnread > 0)
                    setState(() => _chatUnread = 0);
                },
                items: [
                  BottomNavigationBarItem(
                    icon: _badgeIcon(
                      const Icon(Icons.home_outlined),
                      _announcementUnread,
                    ),
                    activeIcon: _badgeIcon(
                      const Icon(Icons.home),
                      _announcementUnread,
                    ),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: _badgeIcon(
                      const Icon(Icons.book_outlined),
                      _materialUnread,
                    ),
                    activeIcon: _badgeIcon(
                      const Icon(Icons.book),
                      _materialUnread,
                    ),
                    label: 'Courses',
                  ),
                  BottomNavigationBarItem(
                    icon: _badgeIcon(
                      const Icon(Icons.chat_bubble_outline),
                      _chatUnread,
                    ),
                    activeIcon: _badgeIcon(
                      const Icon(Icons.chat_bubble),
                      _chatUnread,
                    ),
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
