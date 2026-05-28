import 'dart:async';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'chat_detail_screen.dart';
import 'announcement_detail_screen.dart';
import '../utils/app_colors.dart';
import '../main.dart';

class StudentInboxScreen extends StatefulWidget {
  const StudentInboxScreen({super.key});

  @override
  State<StudentInboxScreen> createState() => _StudentInboxScreenState();
}

class _StudentInboxScreenState extends State<StudentInboxScreen> {
  final ApiService _apiService = ApiService();
  bool isChatSelected = false;

  List<dynamic> _announcements = [];
  List<dynamic> _chats = [];
  bool _isLoading = true;
  String? _error;

  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  Timer? _refreshTimer;


  // Tracks locally-opened items (like system notifications)
  Set<String> _openedChatIds = {};
  Set<String> _openedAnnouncementIds = {};

  // ── Unread counts ──────────────────────────────────────────────────────────

  int get _unreadChats => _chats.where((c) {
        final id = c['group_id']?.toString() ?? '';
        return id.isNotEmpty && !_openedChatIds.contains(id);
      }).length;

  int get _unreadAnnouncements => _announcements.where((a) {
        final id = a['id']?.toString() ?? a['created_at']?.toString() ?? '';
        return id.isNotEmpty && !_openedAnnouncementIds.contains(id);
      }).length;

  @override
  void initState() {
    super.initState();
    _fetchData();
    // Auto-refresh every 30 seconds to show new groups as soon as they are created
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && !_isSearching) {
        _fetchData(showLoading: false);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }


  // ── SharedPreferences helpers ──────────────────────────────────────────────

  Future<void> _loadOpenedIds() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? 'default';
    final chatList =
        prefs.getStringList('student_inbox_opened_chats_$email') ?? [];
    final annList =
        prefs.getStringList('student_inbox_opened_announcements_$email') ?? [];
    if (mounted) {
      setState(() {
        _openedChatIds = chatList.toSet();
        _openedAnnouncementIds = annList.toSet();
      });
    }
  }

  Future<void> _markChatOpened(String id) async {
    if (_openedChatIds.contains(id)) return;
    setState(() => _openedChatIds.add(id));
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? 'default';
    await prefs.setStringList(
        'student_inbox_opened_chats_$email', _openedChatIds.toList());
  }

  Future<void> _markAnnouncementOpened(String id) async {
    if (_openedAnnouncementIds.contains(id)) return;
    setState(() => _openedAnnouncementIds.add(id));
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('email') ?? 'default';
    await prefs.setStringList('student_inbox_opened_announcements_$email',
        _openedAnnouncementIds.toList());
  }

  // ── Data fetching ──────────────────────────────────────────────────────────

  Future<void> _fetchData({bool showLoading = true}) async {
    if (showLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final ann = await _apiService.getAnnouncements('student');
      final inbox = await _apiService.getGroupInbox();
      await _loadOpenedIds();
      if (mounted) {
        setState(() {
          _announcements = ann;
          _chats = inbox;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDark, _) => Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: AppBar(
          backgroundColor: AppColors.appBar,
          elevation: 0,
          centerTitle: false,
          title: _isSearching
              ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: "Search...",
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: AppColors.secondaryText),
                  ),
                  style:
                      TextStyle(color: AppColors.primaryText, fontSize: 18),
                  onChanged: (value) =>
                      setState(() => _searchQuery = value),
                )
              : Text(
                  "Inbox",
                  style: TextStyle(
                    color: AppColors.appBarForeground,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          actions: [
            IconButton(
              icon: Icon(
                _isSearching
                    ? Icons.close_rounded
                    : Icons.search_rounded,
                color: AppColors.appBarForeground,
              ),
              onPressed: () {
                setState(() {
                  if (_isSearching) {
                    _isSearching = false;
                    _searchQuery = "";
                    _searchController.clear();
                  } else {
                    _isSearching = true;
                  }
                });
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Text(_error!,
                        style: const TextStyle(color: Colors.red)),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchData,
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        _buildToggleSwitch(),
                        const SizedBox(height: 20),
                        Expanded(
                          child: isChatSelected
                              ? _buildChatList()
                              : _buildAnnouncementsList(),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  // ── Toggle switch ──────────────────────────────────────────────────────────

  Widget _buildToggleSwitch() {
    final annBadge = _unreadAnnouncements;
    final chatBadge = _unreadChats;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isChatSelected = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color:
                      !isChatSelected ? AppColors.card : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !isChatSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Announcements",
                        style: TextStyle(
                          color: !isChatSelected
                              ? AppColors.primary
                              : AppColors.secondaryText,
                          fontWeight: !isChatSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                        ),
                      ),
                      if (annBadge > 0) ...
                        [
                          const SizedBox(width: 6),
                          _buildBadge(annBadge),
                        ],
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => isChatSelected = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color:
                      isChatSelected ? AppColors.card : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isChatSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Chats",
                        style: TextStyle(
                          color: isChatSelected
                              ? AppColors.primary
                              : AppColors.secondaryText,
                          fontWeight: isChatSelected
                              ? FontWeight.bold
                              : FontWeight.w600,
                        ),
                      ),
                      if (chatBadge > 0) ...
                        [
                          const SizedBox(width: 6),
                          _buildBadge(chatBadge),
                        ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Badge helper ───────────────────────────────────────────────────────────

  Widget _buildBadge(int count) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey(count),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
        child: Text(
          count > 99 ? '99+' : '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }


  Widget _buildAnnouncementsList() {
    var filtered = _announcements;

    if (_searchQuery.isNotEmpty) {
      filtered = _announcements.where((a) {
        final title = (a['title'] ?? '').toString().toLowerCase();
        final content = (a['content'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return title.contains(query) || content.contains(query);
      }).toList();
    }

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty ? "No announcements yet" : "No results found",
          style: TextStyle(color: AppColors.secondaryText),
        ),
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final a = filtered[index];
        final fName = a['instructor_first_name'] ?? '';
        final mName = a['instructor_middle_name'] ?? '';
        final titleStr =
            a['instructor_title'] != null &&
                    a['instructor_title'].toString().isNotEmpty &&
                    a['instructor_title'] != 'None'
                ? "${a['instructor_title']} "
                : "";
        final sender = "$titleStr$fName $mName".trim();
        final title = a['title'] ?? '';
        final content = a['content'] ?? '';
        final course = a['course_code'] ?? 'Global';
        final courseTitle = a['course_title'];
        final section = a['section'];
        final attachments = a['attachment_details'] ?? [];
        final time = _formatTime(a['created_at']);
        final annId =
            a['id']?.toString() ?? a['created_at']?.toString() ?? '$index';
        final isRead = _openedAnnouncementIds.contains(annId);

        final List<Color> colors = [
          Colors.purple,
          Colors.orange,
          Colors.blue,
          Colors.red,
          Colors.green,
        ];
        final color = colors[index % colors.length];

        return _buildAnnouncementTile(
          sender,
          title,
          content,
          course,
          time,
          color,
          isRead: isRead,
          section: section,
          attachments: attachments,
          courseTitle: courseTitle,
          onTap: () async {
            await _markAnnouncementOpened(annId);
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AnnouncementDetailScreen(announcement: a),
              ),
            );
          },
        );
      },
    );
  }

  // ── Chats list ─────────────────────────────────────────────────────────────

  Widget _buildChatList() {
    var filtered = _chats;

    if (_searchQuery.isNotEmpty) {
      filtered = _chats.where((c) {
        final name = (c['group_name'] ?? '').toString().toLowerCase();
        final message = (c['last_message'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || message.contains(query);
      }).toList();
    }

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty ? "No group chats yet" : "No results found",
          style: TextStyle(color: AppColors.secondaryText),
        ),
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final chat = filtered[index];
        final name = chat['group_name'] ?? 'Group';
        final course =
            "${chat['course_title']} (${chat['course_code']})";
        final message = chat['last_message'] ?? '';
        final time = _formatTime(
            chat['last_message_at'] ?? chat['created_at']);
        final chatId = chat['group_id']?.toString() ?? '$index';
        final isRead = _openedChatIds.contains(chatId);

        final List<Color> colors = [
          Colors.blue,
          Colors.purple,
          Colors.orange,
          Colors.green,
          Colors.red,
        ];
        final color = colors[name.length % colors.length];

        return _buildChatTile(
          name,
          course,
          message,
          time,
          color,
          chatId,
          isRead: isRead,
        );
      },
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      if (date.day == now.day &&
          date.month == now.month &&
          date.year == now.year) {
        return DateFormat('HH:mm').format(date);
      } else if (now.difference(date).inDays < 7) {
        return DateFormat('E').format(date);
      } else {
        return DateFormat('MMM d').format(date);
      }
    } catch (_) {
      return '';
    }
  }

  // ── Chat tile ──────────────────────────────────────────────────────────────

  Widget _buildChatTile(
    String name,
    String course,
    String message,
    String time,
    Color avatarColor,
    String groupId, {
    bool isRead = true,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: isRead
            ? Border.all(color: Colors.transparent, width: 1)
            : Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1.2,
              ),
        boxShadow: [
          BoxShadow(
            color: isRead
                ? Colors.black.withOpacity(0.03)
                : AppColors.primary.withOpacity(0.10),
            blurRadius: isRead ? 8 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Blue left line for unread
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 5,
                color: isRead
                    ? Colors.transparent
                    : AppColors.primary,
              ),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      await _markChatOpened(groupId);
                      if (!mounted) return;
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatDetailScreen(
                            groupId: groupId,
                            name: name,
                            isGroup: true,
                          ),
                        ),
                      );
                      _fetchData();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor:
                                avatarColor.withOpacity(0.15),
                            child: Text(
                              name[0],
                              style: TextStyle(
                                color: avatarColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Blue dot + name row
                                    Expanded(
                                      child: Row(
                                        children: [
                                          if (!isRead)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(
                                                      right: 6),
                                              child: Container(
                                                width: 8,
                                                height: 8,
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                          Expanded(
                                            child: Text(
                                              name,
                                              style: TextStyle(
                                                fontWeight: isRead
                                                    ? FontWeight.w600
                                                    : FontWeight.bold,
                                                fontSize: 16,
                                                color:
                                                    AppColors.primaryText,
                                              ),
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      time,
                                      style: TextStyle(
                                        color: isRead
                                            ? AppColors.secondaryText
                                            : AppColors.primary,
                                        fontSize: 12,
                                        fontWeight: isRead
                                            ? FontWeight.normal
                                            : FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  course,
                                  style: TextStyle(
                                    color: Colors.blueGrey.shade400,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  message.isNotEmpty
                                      ? message
                                      : "No messages yet",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: !isRead && message.isNotEmpty
                                        ? AppColors.primaryText
                                        : message.isNotEmpty
                                            ? Colors.black54
                                            : Colors.blueGrey
                                                .withOpacity(0.3),
                                    fontStyle: message.isNotEmpty
                                        ? FontStyle.normal
                                        : FontStyle.italic,
                                    fontWeight: !isRead &&
                                            message.isNotEmpty
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Announcement tile ──────────────────────────────────────────────────────

  Widget _buildAnnouncementTile(
    String sender,
    String header,
    String content,
    String course,
    String time,
    Color accentColor, {
    bool isRead = true,
    String? section,
    List<dynamic>? attachments,
    String? courseTitle,
    VoidCallback? onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: isRead
            ? Border.all(color: Colors.transparent, width: 1)
            : Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 1.2,
              ),
        boxShadow: [
          BoxShadow(
            color: isRead
                ? Colors.black.withOpacity(0.03)
                : AppColors.primary.withOpacity(0.10),
            blurRadius: isRead ? 8 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Blue left line for unread
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 5,
                color: isRead
                    ? Colors.transparent
                    : AppColors.primary,
              ),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.campaign_rounded,
                              color: accentColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                if (courseTitle != null) ...[
                                  Text(
                                    courseTitle,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.blueGrey.shade800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.divider,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          section != null
                                              ? "$course • Sec $section"
                                              : course,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                            color: Colors.grey.shade700,
                                          ),
                                          overflow:
                                              TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      time,
                                      style: TextStyle(
                                        color: isRead
                                            ? AppColors.secondaryText
                                            : AppColors.primary,
                                        fontSize: 11,
                                        fontWeight: isRead
                                            ? FontWeight.normal
                                            : FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Blue dot + header row
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    if (!isRead)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 3, right: 6),
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    Expanded(
                                      child: Text(
                                        header,
                                        style: TextStyle(
                                          fontWeight: isRead
                                              ? FontWeight.w600
                                              : FontWeight.bold,
                                          fontSize: 15,
                                          color: AppColors.primaryText,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  content,
                                  style: TextStyle(
                                    color: isRead
                                        ? AppColors.secondaryText
                                        : AppColors.primaryText
                                            .withOpacity(0.75),
                                    fontSize: 13,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (attachments != null &&
                                    attachments.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 30,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: attachments.length,
                                      itemBuilder: (context, i) {
                                        final file = attachments[i];
                                        return Container(
                                          margin: const EdgeInsets.only(
                                              right: 8),
                                          padding: const EdgeInsets
                                              .symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: accentColor
                                                .withOpacity(0.05),
                                            borderRadius:
                                                BorderRadius.circular(
                                                    8),
                                            border: Border.all(
                                              color: accentColor
                                                  .withOpacity(0.1),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons
                                                    .insert_drive_file_rounded,
                                                size: 14,
                                                color: accentColor,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                file['name'] ?? 'File',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  color: accentColor
                                                      .withOpacity(0.8),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Text(
                                  "Posted by $sender",
                                  style: TextStyle(
                                    color: AppColors.secondaryText,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
