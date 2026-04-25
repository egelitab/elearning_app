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

  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

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
      final inbox = await _apiService.getGroupInbox();
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
        title: _isSearching 
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: "Search...",
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.black38),
              ),
              style: const TextStyle(color: Color(0xFF05398F), fontSize: 18),
              onChanged: (value) => setState(() => _searchQuery = value),
            )
          : const Text("Inbox", style: TextStyle(color: Color(0xFF05398F), fontSize: 24, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded, color: const Color(0xFF05398F)), 
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
            }
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
      // 3. Floating Action Button - Removed for Students as they only join existing groups
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
      return Center(child: Text(_searchQuery.isEmpty ? "No announcements yet" : "No results found", style: const TextStyle(color: Colors.black54)));
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final a = filtered[index];
        final sender = "${a['instructor_first_name'] ?? ''} ${a['instructor_last_name'] ?? ''}";
        final title = a['title'] ?? '';
        final content = a['content'] ?? '';
        final course = a['course_code'] ?? 'Global';
        final courseTitle = a['course_title'];
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
          child: _buildAnnouncementTile(sender, title, content, course, time, color, section: section, attachments: attachments, courseTitle: courseTitle),
        );
      },
    );
  }

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
      return Center(child: Text(_searchQuery.isEmpty ? "No group chats yet" : "No results found", style: const TextStyle(color: Colors.black54)));
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final chat = filtered[index];
        final name = chat['group_name'] ?? 'Group';
        final course = "${chat['course_title']} (${chat['course_code']})";
        final message = chat['last_message'] ?? '';
        final time = _formatTime(chat['last_message_at'] ?? chat['created_at']);
        
        final List<Color> colors = [Colors.blue, Colors.purple, Colors.orange, Colors.green, Colors.red];
        final color = colors[name.length % colors.length];

        return _buildChatTile(name, course, message, time, color, chat['group_id'].toString());
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

  Widget _buildChatTile(String name, String course, String message, String time, Color avatarColor, String groupId) {
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
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => ChatDetailScreen(groupId: groupId, name: name, isGroup: true)));
            _fetchData();
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
                          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87), overflow: TextOverflow.ellipsis)),
                          Text(time, style: const TextStyle(color: Colors.black38, fontSize: 12)),
                        ],
                      ),
                      Text(course, style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 6),
                      Text(
                        message.isNotEmpty ? message : "No messages yet", 
                        maxLines: 1, 
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: message.isNotEmpty ? Colors.black54 : Colors.blueGrey.withOpacity(0.3), fontStyle: message.isNotEmpty ? FontStyle.normal : FontStyle.italic),
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

  Widget _buildAnnouncementTile(String sender, String header, String content, String course, String time, Color accentColor, {String? section, List<dynamic>? attachments, String? courseTitle}) {
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
                      if (courseTitle != null) ...[
                        Text(
                          courseTitle,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueGrey.shade800),
                        ),
                        const SizedBox(height: 4),
                      ],
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
