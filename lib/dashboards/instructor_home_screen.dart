import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:async';
import '../services/api_service.dart';
import 'instructor_materials_screen.dart';
import 'instructor_courses_screen.dart';
import 'instructor_schedule_screen.dart';
import 'instructor_grades_screen.dart';
import 'instructor_groups_screen.dart';
import 'instructor_files_screen.dart';
import 'help_support_screen.dart';
import 'account_settings_screen.dart';
import 'course_details_screen.dart';
import 'instructor_storage_explorer_screen.dart';
import 'instructor_menu_screen.dart';
import 'system_messages_screen.dart';


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
  List<dynamic> _schedules = [];
  bool _isLoadingSchedules = false;
  Map<String, dynamic>? _upcomingClass;

  final PageController _pageController = PageController(viewportFraction: 0.85);
  Timer? _carouselTimer;
  int _currentCardIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initData();
    _startCarouselTimer();
  }

  void _startCarouselTimer() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _pageController.page!.round() + 1;
        if (nextPage > 1) { // We have 2 cards, so index 0 and 1
          nextPage = 0;
          _pageController.animateToPage(nextPage, duration: const Duration(milliseconds: 800), curve: Curves.easeInOut);
        } else {
          _pageController.animateToPage(nextPage, duration: const Duration(milliseconds: 400), curve: Curves.easeIn);
        }
      }
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    await _fetchCourses();
    await _fetchSchedules();
  }

  Future<void> _fetchSchedules() async {
    setState(() => _isLoadingSchedules = true);
    try {
      final schedules = await _apiService.getMySchedules();
      setState(() {
        _schedules = schedules;
        _calculateUpcomingClass();
      });
    } catch (e) {
      print("Error fetching schedules: $e");
    } finally {
      if (mounted) setState(() => _isLoadingSchedules = false);
    }
  }

  void _calculateUpcomingClass() {
    if (_courses.isEmpty && _schedules.isEmpty) return;

    final now = DateTime.now();
    int currentDayIdx = now.weekday - 1; // 0 = Mon, 6 = Sun

    // Filter for digital schedules
    final digitalSchedules = _schedules.where((s) => s['file_path'] == 'DIGITAL_ENTRY').toList();
    
    // Find matching slots for instructor's courses
    final Set<String> myCourseTitles = _courses.map((c) => (c['title'] as String).toLowerCase()).toSet();
    myCourseTitles.addAll(_courses.map((c) => (c['course_code'] as String).toLowerCase()));

    List<Map<String, dynamic>> slots = [];
    
    for (var schedule in digitalSchedules) {
      if (schedule['content'] == null) continue;
      final content = schedule['content'] as Map<String, dynamic>;
      content.forEach((key, value) {
        if (myCourseTitles.contains(value.toString().toLowerCase())) {
          final parts = key.split('-');
          if (parts.length == 2) {
            int slotIdx = int.parse(parts[0]);
            int dayIdx = int.parse(parts[1]);
            slots.add({
              'dayIdx': dayIdx,
              'slotIdx': slotIdx,
              'course': value,
              'schedule': schedule
            });
          }
        }
      });
    }

    if (slots.isEmpty) {
      // Check for uploaded files
      final fileSchedules = _schedules.where((s) => s['file_path'] != 'DIGITAL_ENTRY').toList();
      if (fileSchedules.isNotEmpty) {
        setState(() {
          _upcomingClass = {
            'type': 'file',
            'title': fileSchedules.first['title'] ?? 'Class Schedule',
            'fileName': fileSchedules.first['file_path'].split('\\').last.split('/').last,
          };
        });
      } else {
        setState(() {
          _upcomingClass = null;
        });
      }
      return;
    }

    // Sort slots by day and time
    slots.sort((a, b) {
      if (a['dayIdx'] != b['dayIdx']) return a['dayIdx'].compareTo(b['dayIdx']);
      return a['slotIdx'].compareTo(b['slotIdx']);
    });

    // Find next slot starting from today
    Map<String, dynamic>? nextSlot;
    for (var slot in slots) {
      if (slot['dayIdx'] >= currentDayIdx) {
        nextSlot = slot;
        break;
      }
    }
    
    // If none found for the rest of the week, pick first one next week
    nextSlot ??= slots.first;

    final dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    final slotTimes = ["8:30 AM", "10:45 AM", "1:35 PM", "3:25 PM"]; 

    setState(() {
      _upcomingClass = {
        'type': 'digital',
        'day': dayNames[nextSlot!['dayIdx']],
        'time': slotTimes[nextSlot['slotIdx'] % slotTimes.length],
        'course': nextSlot['course'],
      };
    });
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
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const InstructorFilesScreen(showToggle: false, startInDownloads: true)));
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
    String? selectedSection;
    List<dynamic> sections = [];
    bool isModalLoading = false;
    List<dynamic> selectedAttachments = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          // If we have courses but haven't loaded sections for the first one yet
          if (selectedCourseId != null && sections.isEmpty && !isModalLoading) {
            isModalLoading = true;
            _apiService.getCourseEnrollmentStats(selectedCourseId!).then((stats) {
              setModalState(() {
                sections = stats;
                isModalLoading = false;
              });
            }).catchError((e) {
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
                   const Text("New Announcement", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF05398F))),
                   const SizedBox(height: 25),
                   
                   DropdownButtonFormField<String>(
                     decoration: InputDecoration(
                       labelText: "Select Course",
                       border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                     ),
                     value: selectedCourseId,
                     items: _courses.map<DropdownMenuItem<String>>((course) {
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
                   
                   if (isModalLoading)
                     const Center(child: CircularProgressIndicator())
                   else
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
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Announcement published successfully!"), backgroundColor: Colors.green)
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
                   const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      )
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
        await _showCourseSelectionForUpload(result.files.first);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text("Error picking file: $e")));
    }
  }

  Future<void> _showCourseSelectionForUpload(PlatformFile selectedFile) async {
    String? selectedCourseId = _courses.isNotEmpty ? _courses.first['id'] : null;

    await showModalBottomSheet(
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
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SystemMessagesScreen()));
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
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: Listener(
            onPointerDown: (_) {
              _carouselTimer?.cancel();
            },
            child: PageView(
              controller: _pageController,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (int index) {
                setState(() {
                  _currentCardIndex = index;
                });
              },
              children: [
          // Blue Upcoming Class Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7.5),
            child: GestureDetector(
              onTap: () {
                _carouselTimer?.cancel();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InstructorScheduleScreen()),
                ).then((_) {
                  _startCarouselTimer();
                });
              },
              child: _buildBaseCard(
                width: double.infinity,
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
                    if (_isLoadingSchedules)
                      const SizedBox(height: 30, width: 30, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    else if (_upcomingClass != null) ...[
                      if (_upcomingClass!['type'] == 'digital')
                        Text("${_upcomingClass!['day']} ${_upcomingClass!['time']}", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold))
                      else
                        const Text("Upload Available", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      
                      const Spacer(),
                      Text(_upcomingClass!['type'] == 'digital' ? _upcomingClass!['course'] : _upcomingClass!['title'], 
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else ...[
                      const Text("Not Available", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      const Text("Schedule is not available", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                    const SizedBox(height: 2),
                    const Text("Tap to view details ›", style: TextStyle(color: Colors.white60, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ),

          // Action Card for materials
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7.5),
            child: GestureDetector(
              onTap: () async {
                _carouselTimer?.cancel();
                await _handleDirectUpload();
                _startCarouselTimer();
              },
              child: _buildBaseCard(
                width: double.infinity,
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
          ),
        ],
      ),
     ),
    ),
    const SizedBox(height: 15),
    Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (index) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 6,
          width: _currentCardIndex == index ? 24 : 8,
          decoration: BoxDecoration(
            color: _currentCardIndex == index ? const Color(0xFF09AEF5) : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    ),
  ],
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
          if (_courses.isNotEmpty) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => CourseDetailsScreen(
              course: _courses.first,
              allCourses: _courses,
              themeColor: Colors.blue,
            )));
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const InstructorCoursesScreen()));
          }
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
          Navigator.push(context, MaterialPageRoute(builder: (context) => InstructorMenuScreen(courses: _courses)));
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