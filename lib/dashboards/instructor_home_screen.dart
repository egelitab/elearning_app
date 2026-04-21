import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import 'instructor_materials_screen.dart';
import 'instructor_courses_screen.dart';
import 'instructor_schedule_screen.dart';
import 'instructor_grades_screen.dart';
import 'instructor_groups_screen.dart';
import 'instructor_files_screen.dart';
import 'help_support_screen.dart';
import 'account_settings_screen.dart';

class InstructorHomeScreen extends StatefulWidget {
  const InstructorHomeScreen({super.key});

  @override
  State<InstructorHomeScreen> createState() => _InstructorHomeScreenState();
}

class _InstructorHomeScreenState extends State<InstructorHomeScreen> {
  final ApiService _apiService = ApiService();
  String _title = 'Professor';
  String _firstName = '';
  List<dynamic> _courses = [];
  bool _isLoadingCourses = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    setState(() => _isLoadingCourses = true);
    try {
      final courses = await _apiService.getInstructorCourses();
      setState(() => _courses = courses);
    } catch (e) {
      print("Error fetching courses for home: $e");
    } finally {
      setState(() => _isLoadingCourses = false);
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _title = prefs.getString('title') ?? 'Professor';
      if (_title.isEmpty) _title = 'Professor';
      if (_title == 'None') _title = '';
      _firstName = prefs.getString('first_name') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC), // Professional light grayish blue background
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section with our primary gradient
            _buildHeader(),
            
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Horizontal Scrollable Cards
                  _buildHorizontalCards(context),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 25.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Grid Menu
                        const Text("Main Menu", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF05398F))),
                        const SizedBox(height: 15),
                        _buildMenuGrid(),
                        
                        const SizedBox(height: 25),
                        const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF05398F))),
                        const SizedBox(height: 15),
                        _buildQuickAction(Icons.send_rounded, "Post Announcement", "Notify all students", () {
                          _showPostAnnouncementDialog(context);
                        }),
                        _buildQuickAction(Icons.download_rounded, "Downloads", "Access offline materials", () {
                          // Could nav to Download screen if applicable for instructors
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Downloads coming soon!")));
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPostAnnouncementDialog(BuildContext context) {
    if (_courses.isEmpty && !_isLoadingCourses) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No courses found to post announcements to.")));
      return;
    }

    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String? selectedCourseId = _courses.isNotEmpty ? _courses.first['id'] : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          bool isPosting = false;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Post Announcement", style: TextStyle(color: Color(0xFF05398F), fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Select Course", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(color: const Color(0xFFF4F7FC), borderRadius: BorderRadius.circular(10)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedCourseId,
                        items: _courses.map((c) => DropdownMenuItem<String>(value: c['id'], child: Text(c['title'] ?? c['course_code'], overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (val) => setDialogState(() => selectedCourseId = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text("Title", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 5),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: "Announcement Title",
                      filled: true,
                      fillColor: const Color(0xFFF4F7FC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text("Content", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 5),
                  TextField(
                    controller: contentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Type your message here...",
                      filled: true,
                      fillColor: const Color(0xFFF4F7FC),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: isPosting ? null : () async {
                  if (selectedCourseId == null || titleController.text.isEmpty || contentController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all fields")));
                    return;
                  }

                  setDialogState(() => isPosting = true);
                  try {
                    await _apiService.createAnnouncement(selectedCourseId!, titleController.text, contentController.text);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Announcement published successfully!"), backgroundColor: Colors.green));
                  } catch (e) {
                    setDialogState(() => isPosting = false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF09AEF5), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: isPosting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Post"),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleDirectUpload() async {
    if (_courses.isEmpty && !_isLoadingCourses) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(behavior: SnackBarBehavior.floating, content: Text("No courses found. Please ensure you are assigned to at least one course.")));
      return;
    }

    try {
      FilePickerResult? result = await FilePicker.pickFiles();
      if (result != null) {
        if (!mounted) return;
        _showCourseSelectionForUpload(result.files.first);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text("Error picking file: $e")));
    }
  }

  void _showCourseSelectionForUpload(PlatformFile selectedFile) {
    String? selectedCourseId = _courses.isNotEmpty ? _courses.first['id'] : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            bool isUploading = false;

            return Container(
              padding: EdgeInsets.only(
                top: 20, left: 20, right: 20, 
                bottom: MediaQuery.of(context).viewInsets.bottom + 30
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)))),
                  const Text("Finalize Upload", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF05398F))),
                  const SizedBox(height: 10),
                  Text("File: ${selectedFile.name}", style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 25),
                  
                  // Course Dropdown
                  const Text("Select Course", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(10)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedCourseId,
                        items: _courses.map((course) {
                          return DropdownMenuItem<String>(
                            value: course['id'],
                            child: Text(course['title'] ?? course['course_code']),
                          );
                        }).toList(),
                        onChanged: (val) => setSheetState(() => selectedCourseId = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Upload Button
                  isUploading 
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF09AEF5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                          ),
                          onPressed: () async {
                            if (selectedCourseId == null) return;
                            
                            setSheetState(() => isUploading = true);
                            try {
                              await _apiService.uploadMaterial(selectedCourseId!, selectedFile.name, selectedFile.path!);
                              if (!mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(behavior: SnackBarBehavior.floating, content: Text("Uploaded Successfully", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
                            } catch (e) {
                              if (mounted) {
                                setSheetState(() => isUploading = false);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(e.toString())));
                              }
                            }
                          },
                          child: const Text("Upload Now", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      )
                ],
              ),
            );
          }
        );
      }
    );
  }


  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 35),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF09AEF5), Color(0xFF05398F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30), 
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
           BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Hello, $_title $_firstName".trim(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                const Text("Welcome to BDU ELMS", style: TextStyle(color: Colors.white70, fontSize: 14)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Notifications coming soon!")));
            },
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                 color: Colors.white24,
                 shape: BoxShape.circle,
              ),
              child: const CircleAvatar(
                backgroundColor: Colors.white, 
                radius: 22,
                child: Icon(Icons.notifications_none_rounded, color: Color(0xFF05398F), size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalCards(BuildContext context) {
    double cardWidth = MediaQuery.of(context).size.width * 0.75;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Blue Upcoming Class Card
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const InstructorScheduleScreen()),
              );
            },
            child: _buildBaseCard(
              width: cardWidth,
              gradient: const LinearGradient(
                colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text("Upcoming Class", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text("Mon 8:30 AM", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  const Text("Computer Science 101", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  const Text("Tap to view details ›", style: TextStyle(color: Colors.white60, fontSize: 12)),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 15),

          // Action Card for materials
          GestureDetector(
            onTap: _handleDirectUpload,
            child: _buildBaseCard(
              width: cardWidth,
              gradient: const LinearGradient(
                colors: [Color(0xFF26A69A), Color(0xFF00695C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text("Quick Action", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                      SizedBox(height: 8),
                      Text("Upload", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
                      Text("Files", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 36),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBaseCard({required double width, Gradient? gradient, required Widget child}) {
    return Container(
      width: width,
      height: 150,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: child,
    );
  }

  Widget _buildMenuGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 25,
      crossAxisSpacing: 10,
      children: [
        _buildIconBtn(Icons.folder_shared_rounded, "Materials", const Color(0xFFFFF3E0), Colors.orange, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const InstructorMaterialsScreen()));
        }),
        _buildIconBtn(Icons.cloud_upload_rounded, "Upload", const Color(0xFFE3F2FD), Colors.blue, _handleDirectUpload),
        _buildIconBtn(Icons.book_rounded, "Courses", const Color(0xFFE8F5E9), Colors.green, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const InstructorCoursesScreen()));
        }),
        _buildIconBtn(Icons.schedule_rounded, "Schedule", const Color(0xFFF3E5F5), Colors.purple, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const InstructorScheduleScreen()));
        }),
        _buildIconBtn(Icons.assessment_rounded, "Grades", const Color(0xFFFFEBEE), Colors.red, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const InstructorGradesScreen()));
        }),
        _buildIconBtn(Icons.groups_rounded, "Groups", const Color(0xFFE0F7FA), Colors.cyan, () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const InstructorGroupsScreen()));
        }),
        _buildIconBtn(Icons.calendar_month_rounded, "Calendar", const Color(0xFFFFFDE7), Colors.amber, () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Calendar coming soon!")));
        }),
        _buildIconBtn(Icons.more_horiz_rounded, "More", Colors.grey.shade200, Colors.grey.shade700, () {
          _showMoreOptions(context);
        }),
      ],
    );
  }

  Widget _buildIconBtn(IconData icon, String label, Color bgColor, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 55,
            width: 55,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04), 
                  blurRadius: 10,
                  offset: const Offset(0, 4)
                )
              ]
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label, 
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("More Options", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF05398F))),
            const SizedBox(height: 20),
            _buildQuickAction(Icons.help_outline_rounded, "Help & Support", "Get assistance", () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpSupportScreen()));
            }),
            _buildQuickAction(Icons.settings_outlined, "Settings", "Account & app settings", () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountSettingsScreen()));
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String title, String sub, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ]
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFF09AEF5), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text(sub, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.black26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}