import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class SystemNotificationsScreen extends StatefulWidget {
  const SystemNotificationsScreen({super.key});

  @override
  State<SystemNotificationsScreen> createState() => _SystemNotificationsScreenState();
}

class _SystemNotificationsScreenState extends State<SystemNotificationsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _messages = [];
  bool _isLoading = true;
  Set<String> _openedIds = {};

  Future<String> _getOpenedIdsKey() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? 'default';
    return 'system_notifications_opened_ids_$email';
  }

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _apiService.getSystemMessages(),
        _loadOpenedIds(),
      ]);
      if (mounted) {
        setState(() {
          _messages = results[0] as List<dynamic>;
          _openedIds = results[1] as Set<String>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Set<String>> _loadOpenedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final key = await _getOpenedIdsKey();
    return (prefs.getStringList(key) ?? []).toSet();
  }

  Future<void> _markAsOpened(String msgId) async {
    if (_openedIds.contains(msgId)) return;
    setState(() => _openedIds.add(msgId));
    final prefs = await SharedPreferences.getInstance();
    final key = await _getOpenedIdsKey();
    await prefs.setStringList(key, _openedIds.toList());
  }

  Future<void> _markAllAsRead() async {
    final allIds = _messages
        .map((m) => m['id']?.toString() ?? m['created_at']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    setState(() => _openedIds = allIds);
    final prefs = await SharedPreferences.getInstance();
    final key = await _getOpenedIdsKey();
    await prefs.setStringList(key, allIds.toList());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("All notifications marked as read"),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _msgId(dynamic msg) =>
      msg['id']?.toString() ?? msg['created_at']?.toString() ?? '';

  int get _unreadCount =>
      _messages.where((m) => !_openedIds.contains(_msgId(m))).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "System Notifications",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18),
            ),
            if (_unreadCount > 0)
              Text(
                "$_unreadCount unread",
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF05398F), Color(0xFF09AEF5)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          if (_unreadCount > 0)
            TextButton.icon(
              onPressed: _markAllAsRead,
              icon: const Icon(Icons.done_all_rounded, color: Colors.white, size: 18),
              label: const Text(
                "Mark all read",
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _messages.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      "No system notifications",
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, index) => _buildItem(_messages[index]),
              ),
      ),
    );
  }

  Widget _buildItem(dynamic msg) {
    final String id = _msgId(msg);
    final bool isOpened = _openedIds.contains(id);
    final DateTime date = DateTime.tryParse(msg['created_at'] ?? '') ?? DateTime.now();
    final String formattedDate = DateFormat('MMM d, h:mm a').format(date.toLocal());
    final String title = msg['title'] ?? 'System Notification';
    final String content = msg['content'] ?? '';

    return GestureDetector(
      onTap: () async {
        await _markAsOpened(id);
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SystemNotificationDetailScreen(
              title: title,
              content: content,
              date: date,
            ),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isOpened ? const Color(0xFFF8FAFF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isOpened
              ? Border.all(color: Colors.grey.shade200, width: 1)
              : Border.all(color: const Color(0xFF09AEF5).withOpacity(0.3), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: isOpened
                  ? Colors.black.withOpacity(0.02)
                  : const Color(0xFF09AEF5).withOpacity(0.10),
              blurRadius: isOpened ? 4 : 10,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 5,
                  color: isOpened ? Colors.grey.shade300 : const Color(0xFF09AEF5),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isOpened)
                              Padding(
                                padding: const EdgeInsets.only(top: 4, right: 8),
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF09AEF5),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontWeight: isOpened ? FontWeight.w500 : FontWeight.bold,
                                  fontSize: 15,
                                  color: isOpened ? Colors.black54 : Colors.black87,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              formattedDate,
                              style: TextStyle(
                                color: isOpened ? Colors.grey.shade400 : Colors.grey.shade500,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: isOpened ? Colors.black12 : Colors.black26,
                              size: 18,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          content,
                          style: TextStyle(
                            color: isOpened ? Colors.grey.shade400 : Colors.grey.shade600,
                            fontSize: 13,
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail Screen
// ─────────────────────────────────────────────────────────────────────────────

class SystemNotificationDetailScreen extends StatelessWidget {
  final String title;
  final String content;
  final DateTime date;

  const SystemNotificationDetailScreen({
    super.key,
    required this.title,
    required this.content,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    final String formattedDate =
        DateFormat('MMMM d, yyyy  •  h:mm a').format(date.toLocal());

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text(
          "System Notification",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF05398F), Color(0xFF09AEF5)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF05398F), Color(0xFF09AEF5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF05398F).withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.campaign_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "SYSTEM",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, color: Colors.white60, size: 14),
                      const SizedBox(width: 5),
                      Text(
                        formattedDate,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "MESSAGE",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.blueGrey,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.7,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
