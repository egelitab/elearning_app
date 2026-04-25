import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'chat_detail_screen.dart';
import 'announcement_detail_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final ann = await _apiService.getAnnouncements('student');
      final inbox = await _apiService.getInbox();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC), 
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F7FC),
        elevation: 0,
        centerTitle: false,
        title: const Text("Inbox", style: TextStyle(color: Color(0xFF05398F), fontSize: 24, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF05398F)), 
            onPressed: _fetchData
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Color(0xFF05398F)), 
            onPressed: () {}
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _error != null
          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
          : Column(
              children: [
                const SizedBox(height: 10),
                _buildToggleSwitch(),
                const SizedBox(height: 20),
                Expanded(
                  child: isChatSelected ? _buildChatList() : _buildAnnouncementsList(),
                ),
              ],
            ),
      // 3. Floating Action Button for New Message
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF09AEF5),
        elevation: 4,
        child: const Icon(Icons.edit_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildToggleSwitch() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
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
                  color: !isChatSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: !isChatSelected ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))] : [],
                ),
                child: Center(
                  child: Text(
                    "Announcements",
                    style: TextStyle(
                      color: !isChatSelected ? const Color(0xFF05398F) : Colors.black54,
                      fontWeight: !isChatSelected ? FontWeight.bold : FontWeight.w600,
                    ),
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
                  color: isChatSelected ? Colors.white : Colors.transparent, 
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isChatSelected ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))] : [],
                ),
                child: Center(
                  child: Text(
                    "Chats",
                    style: TextStyle(
                      color: isChatSelected ? const Color(0xFF05398F) : Colors.black54,
                      fontWeight: isChatSelected ? FontWeight.bold : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsList() {
    if (_announcements.isEmpty) {
      return const Center(child: Text("No announcements", style: TextStyle(color: Colors.black54)));
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _announcements.length,
      itemBuilder: (context, index) {
        final a = _announcements[index];
        final sender = "${a['instructor_first_name'] ?? ''} ${a['instructor_last_name'] ?? ''}";
        final title = a['title'] ?? '';
        final content = a['content'] ?? '';
        final course = a['course_code'] ?? 'Global';
        final section = a['section'];
        final attachments = a['attachment_details'] ?? [];
        final time = _formatTime(a['created_at']);
        
        final List<Color> colors = [Colors.purple, Colors.orange, Colors.blue, Colors.red, Colors.green];
        final color = colors[index % colors.length];

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AnnouncementDetailScreen(announcement: a))
          ),
          child: _buildAnnouncementTile(sender, title, content, course, time, color, section: section, attachments: attachments),
        );
      },
    );
  }

  Widget _buildChatList() {
    if (_chats.isEmpty) {
      return const Center(child: Text("No messages", style: TextStyle(color: Colors.black54)));
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _chats.length,
      itemBuilder: (context, index) {
        final chat = _chats[index];
        final name = "${chat['first_name'] ?? ''} ${chat['last_name'] ?? ''}";
        final message = chat['content'] ?? '';
        final time = _formatTime(chat['created_at']);
        final isUnread = chat['is_read'] == false;
        
        final List<Color> colors = [Colors.blue, Colors.purple, Colors.orange, Colors.green, Colors.red];
        final color = colors[name.length % colors.length];

        return _buildChatTile(name, message, isUnread ? "1" : "", time, color, chat['conversation_user_id'].toString());
      },
    );
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      if (date.day == now.day && date.month == now.month && date.year == now.year) {
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

  Widget _buildChatTile(String name, String message, String count, String time, Color avatarColor, String userId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ChatDetailScreen(userId: userId, name: name)));
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: avatarColor.withOpacity(0.15),
                  child: Text(name[0], style: TextStyle(color: avatarColor, fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                          Text(time, style: TextStyle(color: count.isNotEmpty ? const Color(0xFF09AEF5) : Colors.black38, fontSize: 12, fontWeight: count.isNotEmpty ? FontWeight.bold : FontWeight.normal)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              message, 
                              maxLines: 1, 
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: count.isNotEmpty ? Colors.black87 : Colors.black54, fontWeight: count.isNotEmpty ? FontWeight.w600 : FontWeight.normal),
                            ),
                          ),
                          if (count.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: Color(0xFF09AEF5), shape: BoxShape.circle),
                              child: Text(count, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnnouncementTile(String sender, String header, String content, String course, String time, Color accentColor, {String? section, List<dynamic>? attachments}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
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
                  child: Icon(Icons.campaign_rounded, color: accentColor, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              section != null ? "$course • Sec $section" : course, 
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey.shade700)
                            ),
                          ),
                          Text(time, style: const TextStyle(color: Colors.black38, fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(header, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(
                        content, 
                        style: const TextStyle(color: Colors.black54, fontSize: 13, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (attachments != null && attachments.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 30,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: attachments.length,
                            itemBuilder: (context, i) {
                              final file = attachments[i];
                              return Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: accentColor.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: accentColor.withOpacity(0.1)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.insert_drive_file_rounded, size: 14, color: accentColor),
                                    const SizedBox(width: 6),
                                    Text(
                                      file['name'] ?? 'File', 
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: accentColor.withOpacity(0.8))
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text("Posted by $sender", style: const TextStyle(color: Colors.black45, fontSize: 11, fontWeight: FontWeight.w500)),
                    ],
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
