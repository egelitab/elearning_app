import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import 'instructor_storage_explorer_screen.dart';

class AnnouncementDetailScreen extends StatefulWidget {
  final Map<String, dynamic> announcement;
  final bool canEdit;

  const AnnouncementDetailScreen({super.key, required this.announcement, this.canEdit = false});

  @override
  State<AnnouncementDetailScreen> createState() => _AnnouncementDetailScreenState();
}

class _AnnouncementDetailScreenState extends State<AnnouncementDetailScreen> {
  final ApiService _apiService = ApiService();
  late Map<String, dynamic> _currentAnnouncement;
  bool _isDeleting = false;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _currentAnnouncement = widget.announcement;
  }

  Future<void> _deleteAnnouncement() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Announcement"),
        content: const Text("Are you sure you want to permanently delete this announcement?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Delete", style: TextStyle(color: Colors.red))
          ),
        ],
      )
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);
    try {
      await _apiService.deleteAnnouncement(_currentAnnouncement['id'].toString());
      if (mounted) {
        Navigator.pop(context, true); // true indicates deleted
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Announcement deleted"), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Delete failed: $e"), backgroundColor: Colors.red)
        );
      }
    }
  }

  void _showEditModal() {
    final titleController = TextEditingController(text: _currentAnnouncement['title']);
    final contentController = TextEditingController(text: _currentAnnouncement['content']);
    String? selectedSection = _currentAnnouncement['section'];
    List<dynamic> sections = [];
    bool isModalLoading = false;
    List<dynamic> selectedAttachments = List.from(_currentAnnouncement['attachment_details'] ?? []);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // Initialize sections if not loaded
          if (sections.isEmpty && !isModalLoading) {
            isModalLoading = true;
            _apiService.getCourseEnrollmentStats(_currentAnnouncement['course_id'].toString()).then((value) {
              setModalState(() {
                sections = value;
                isModalLoading = false;
              });
            }).catchError((_) {
              setModalState(() => isModalLoading = false);
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
                  const Text("Edit Announcement", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF05398F))),
                  const SizedBox(height: 25),
                  
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
                  
                  const Text("Attachments", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 8),
                  if (selectedAttachments.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      children: selectedAttachments.map((item) => Chip(
                        label: Text(item['name'] ?? 'File', style: const TextStyle(fontSize: 12)),
                        onDeleted: () => setModalState(() => selectedAttachments.remove(item)),
                      )).toList(),
                    ),
                  TextButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => const InstructorStorageExplorerScreen(isPicker: true))
                      );
                      if (result != null && result is List) {
                        setModalState(() {
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
                        if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                           try {
                             final attachmentIds = selectedAttachments.map((a) => a['id'].toString()).toList();
                             await _apiService.updateAnnouncement(
                               _currentAnnouncement['id'].toString(), 
                               titleController.text, 
                               contentController.text,
                               section: selectedSection,
                               attachments: attachmentIds,
                             );
                             
                             // Close modal and refresh screen
                             if (context.mounted) {
                               Navigator.pop(context);
                               ScaffoldMessenger.of(context).showSnackBar(
                                 const SnackBar(content: Text("Announcement updated!"), backgroundColor: Colors.green)
                               );
                               
                               setState(() {
                                 _hasChanged = true;
                                 _currentAnnouncement = {
                                   ..._currentAnnouncement,
                                   'title': titleController.text,
                                   'content': contentController.text,
                                   'section': selectedSection,
                                   'attachment_details': selectedAttachments,
                                 };
                               });
                               // We can't easily return a value here because we stay on the screen
                               // But we can notify the parent when the detail screen itself is popped.
                             }
                           } catch (e) {
                             ScaffoldMessenger.of(context).showSnackBar(
                               SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
                             );
                           }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF09AEF5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                      ),
                      child: const Text("Update Announcement", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        }
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _currentAnnouncement['title'] ?? 'No Title';
    final content = _currentAnnouncement['content'] ?? '';
    final courseCode = _currentAnnouncement['course_code'] ?? '';
    final courseTitle = _currentAnnouncement['course_title'] ?? '';
    final section = _currentAnnouncement['section'];
    final instructor = _currentAnnouncement['instructor_first_name'] != null 
        ? "${_currentAnnouncement['instructor_first_name']} ${_currentAnnouncement['instructor_last_name']}"
        : null;
    final attachments = _currentAnnouncement['attachment_details'] as List<dynamic>? ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF05398F)),
          onPressed: () => Navigator.pop(context, _hasChanged),
        ),
        title: const Text("Announcement Details", style: TextStyle(color: Color(0xFF05398F), fontWeight: FontWeight.bold)),
        actions: widget.canEdit ? [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFF05398F)),
            onPressed: _showEditModal,
            tooltip: "Edit",
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            onPressed: _isDeleting ? null : _deleteAnnouncement,
            tooltip: "Remove",
          ),
          const SizedBox(width: 8),
        ] : null,
      ),
      body: _isDeleting 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF09AEF5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    section != null ? "$courseCode • Section $section" : courseCode,
                    style: const TextStyle(color: Color(0xFF05398F), fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF05398F), height: 1.2),
                ),
                const Divider(height: 48, thickness: 1, color: Colors.black12),

                // Metadata
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color(0xFF05398F),
                      radius: 20,
                      child: Text(
                        (instructor ?? 'A').substring(0, 1).toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          instructor ?? "Course Announcement",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                        ),
                        Text(
                          courseTitle,
                          style: const TextStyle(color: Colors.black45, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Content
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 16, 
                    color: Colors.black87, 
                    height: 1.6,
                    letterSpacing: 0.2,
                  ),
                ),

                if (attachments.isNotEmpty) ...[
                  const SizedBox(height: 48),
                  const Text(
                    "Attachments",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF05398F)),
                  ),
                  const SizedBox(height: 16),
                  ...attachments.map((file) => _buildAttachmentTile(context, file)),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  Widget _buildAttachmentTile(BuildContext context, dynamic file) {
    final String name = file['name'] ?? 'Attachment';
    final String path = file['file_path'] ?? '';
    final String type = file['file_type'] ?? '';
    
    final String cleanBaseUrl = ApiService.baseUrl.replaceFirst('/api', '');
    final String fileUrl = "$cleanBaseUrl/uploads/$path";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF09AEF5).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(_getIconForType(type), color: const Color(0xFF09AEF5), size: 24),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(type.toUpperCase(), style: const TextStyle(fontSize: 11, color: Colors.black38)),
        trailing: IconButton(
          icon: const Icon(Icons.open_in_new_rounded, color: Color(0xFF05398F)),
          onPressed: () => _launchURL(context, fileUrl),
        ),
        onTap: () => _launchURL(context, fileUrl),
      ),
    );
  }

  IconData _getIconForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('pdf')) return Icons.picture_as_pdf_rounded;
    if (t.contains('image') || t.contains('jpg') || t.contains('png')) return Icons.image_rounded;
    if (t.contains('video')) return Icons.video_collection_rounded;
    if (t.contains('word') || t.contains('doc')) return Icons.description_rounded;
    return Icons.insert_drive_file_rounded;
  }

  Future<void> _launchURL(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not open file")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }
}
