import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'chat_detail_screen.dart';
import 'instructor_storage_explorer_screen.dart';
import 'announcement_detail_screen.dart';

class InstructorInboxScreen extends StatefulWidget {
  const InstructorInboxScreen({super.key});

  @override
  State<InstructorInboxScreen> createState() => _InstructorInboxScreenState();
}


class _InstructorInboxScreenState extends State<InstructorInboxScreen> {
  final ApiService _apiService = ApiService();
  bool isChatSelected = false; 
  
  List<dynamic> _chats = [];
  List<dynamic> _announcements = [];
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
      final chats = await _apiService.getInbox();
      final announcements = await _apiService.getAnnouncements('instructor');
      
      if (mounted) {
        setState(() {
          _chats = chats;
          _announcements = announcements;
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
      backgroundColor: const Color(0xFFF4F7FC), // Match background color to theme
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
        onPressed: () {
          if (isChatSelected) {
            // New Message - User Search
          } else {
            _showNewAnnouncementModal();
          }
        },
        backgroundColor: const Color(0xFF09AEF5),
        elevation: 4,
        child: Icon(
          isChatSelected ? Icons.maps_ugc_rounded : Icons.campaign_rounded, 
          color: Colors.white, 
          size: 28
        ),
      ),
    );
  }

  void _showNewAnnouncementModal() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String? selectedCourseId;
    String? selectedSection;
    List<dynamic> courses = [];
    List<dynamic> sections = [];
    bool isModalLoading = true;
    List<dynamic> selectedAttachments = [];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          if (isModalLoading && courses.isEmpty) {
            _apiService.getInstructorCourses().then((value) async {
              if (value.isNotEmpty) {
                final firstCourseId = value[0]['id'].toString();
                try {
                  final stats = await _apiService.getCourseEnrollmentStats(firstCourseId);
                  setModalState(() {
                    courses = value;
                    selectedCourseId = firstCourseId;
                    sections = stats;
                    isModalLoading = false;
                  });
                } catch (e) {
                  setModalState(() {
                    courses = value;
                    selectedCourseId = firstCourseId;
                    isModalLoading = false;
                  });
                }
              } else {
                setModalState(() {
                  courses = value;
                  isModalLoading = false;
                });
              }
            });
          }

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 30, left: 24, right: 24
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("New Announcement", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF05398F))),
                  const SizedBox(height: 25),
                  if (isModalLoading)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: "Select Course",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      value: selectedCourseId,
                      items: courses.map<DropdownMenuItem<String>>((course) {
                        return DropdownMenuItem<String>(
                          value: course['id'].toString(),
                          child: Text(course['title'] ?? 'No Title'),
                        );
                      }).toList(),
                      onChanged: (value) async {
                        setModalState(() {
                          selectedCourseId = value;
                          selectedSection = null;
                          sections = [];
                          isModalLoading = true;
                        });
                        try {
                          final stats = await _apiService.getCourseEnrollmentStats(value!);
                          setModalState(() {
                            sections = stats;
                            isModalLoading = false;
                          });
                        } catch (e) {
                          setModalState(() => isModalLoading = false);
                        }
                      },
                    ),
                    const SizedBox(height: 15),
                    if (selectedCourseId != null)
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: "Select Section (Optional)",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                        ),
                        value: selectedSection,
                        items: [
                          const DropdownMenuItem<String>(value: null, child: Text("All Sections")),
                          ...sections.map<DropdownMenuItem<String>>((s) {
                            return DropdownMenuItem<String>(
                              value: s['section'],
                              child: Text("Section ${s['section']} (${s['department_name']})"),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) => setModalState(() => selectedSection = value),
                      ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: "Title",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: contentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: "Content",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    // Attach Files Section
                    const Text("Attachments", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                    const SizedBox(height: 8),
                    if (selectedAttachments.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        children: selectedAttachments.map((item) => Chip(
                          label: Text(item['name'], style: const TextStyle(fontSize: 12)),
                          onDeleted: () => setModalState(() => selectedAttachments.remove(item)),
                        )).toList(),
                      ),
                    TextButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => InstructorStorageExplorerScreen(isPicker: true))
                        );
                        if (result != null && result is List) {
                          setModalState(() {
                            // Only allow files for now if folders are mixed in
                            for (var item in result) {
                              if (item['type'] == 'file' && !selectedAttachments.any((a) => a['id'] == item['id'])) {
                                selectedAttachments.add(item);
                              }
                            }
                          });
                        }
                      }, 
                      icon: const Icon(Icons.attach_file_rounded), 
                      label: const Text("Attach from Storage")
                    ),

                    const SizedBox(height: 25),
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (selectedCourseId != null && titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                             try {
                               final attachmentIds = selectedAttachments.map((a) => a['id'].toString()).toList();
                               await _apiService.createAnnouncement(
                                 selectedCourseId!, 
                                 titleController.text, 
                                 contentController.text,
                                 section: selectedSection,
                                 attachments: attachmentIds,
                               );
                               
                               if (mounted) {
                                 Navigator.pop(context);
                                 _fetchData();
                                 ScaffoldMessenger.of(context).showSnackBar(
                                   const SnackBar(content: Text("Announcement posted!"), backgroundColor: Colors.green)
                                 );
                               }
                             } catch (e) {
                               ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
                               );
                             }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please fill all fields and select a course"), backgroundColor: Colors.orange)
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF09AEF5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                        ),
                        child: const Text("Post Announcement", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        }
      )
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

  Widget _buildChatTile(String name, String message, String count, String time, Color avatarColor, String userId) {
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
  Widget _buildChatList() {
    if (_chats.isEmpty) {
      return const Center(child: Text("No chats yet", style: TextStyle(color: Colors.black54)));
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
        
        // Use a consistent color based on the name
        final List<Color> avatarColors = [Colors.blue, Colors.purple, Colors.orange, Colors.green, Colors.red, Colors.teal, Colors.indigo];
        final color = avatarColors[name.length % avatarColors.length];

        return _buildChatTile(
          name, 
          message, 
          isUnread ? "1" : "", // Backend currently doesn't provide unread count per chat, just a sample logic
          time, 
          color,
          chat['conversation_user_id'].toString()
        );
      },
    );
  }

  Widget _buildAnnouncementsList() {
    if (_announcements.isEmpty) {
      return const Center(child: Text("No announcements yet", style: TextStyle(color: Colors.black54)));
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _announcements.length,
      itemBuilder: (context, index) {
        final a = _announcements[index];
        final title = a['title'] ?? 'No Title';
        final description = a['content'] ?? '';
        final time = _formatTime(a['created_at']);
        final courseCode = a['course_code'] ?? '';
        final courseTitle = a['course_title'] ?? 'Global';
        final section = a['section'];
        final attachments = a['attachment_details'] ?? [];
        
        return GestureDetector(
          onTap: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AnnouncementDetailScreen(announcement: a, canEdit: true))
            );
            if (result == true) {
              _fetchData();
            }
          },
          child: _buildAnnouncementTile(
            title, 
            description, 
            time, 
            _getAnnouncementIcon(title),
            _getAnnouncementColor(title),
            courseCode: courseCode,
            courseTitle: courseTitle,
            section: section,
            attachments: attachments,
          ),
        );
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

  IconData _getAnnouncementIcon(String title) {
    final t = title.toLowerCase();
    if (t.contains('exam') || t.contains('schedule')) return Icons.event_note_rounded;
    if (t.contains('grade')) return Icons.grade_rounded;
    if (t.contains('speaker') || t.contains('mandatory')) return Icons.campaign_rounded;
    return Icons.info_outline_rounded;
  }

  Color _getAnnouncementColor(String title) {
    final t = title.toLowerCase();
    if (t.contains('exam')) return Colors.orange;
    if (t.contains('grade')) return Colors.green;
    if (t.contains('speaker')) return Colors.blue;
    return const Color(0xFF09AEF5);
  }

  Widget _buildAnnouncementTile(String title, String description, String time, IconData icon, Color iconColor, {String? courseCode, String? courseTitle, String? section, List<dynamic>? attachments}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
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
                if (courseCode != null) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          section != null ? "$courseCode • Sec $section" : courseCode, 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey.shade700)
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title, 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      )
                    ),
                    Text(time, style: const TextStyle(color: Colors.black45, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description, 
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
                            color: const Color(0xFF09AEF5).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF09AEF5).withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.description_rounded, size: 14, color: Color(0xFF09AEF5)),
                              const SizedBox(width: 6),
                              Text(
                                file['name'] ?? 'File', 
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF05398F))
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}