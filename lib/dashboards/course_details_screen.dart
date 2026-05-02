import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'instructor_materials_screen.dart';

class CourseDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> course;
  final List<dynamic>? allCourses;
  final Color themeColor;

  const CourseDetailsScreen({
    super.key, 
    required this.course, 
    this.allCourses,
    this.themeColor = Colors.blue
  });

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  final ApiService _apiService = ApiService();
  late Map<String, dynamic> _currentCourse;
  List<dynamic> _allCourses = [];
  List<dynamic> _chapters = [];
  List<dynamic> _courseMaterials = []; // Materials not assigned to a chapter
  Map<String, List<dynamic>> _chapterMaterials = {};
  Set<String> _selectedIds = {}; // For multi-selection
  bool _isLoading = true;
  bool _isInstructor = false;

  @override
  void initState() {
    super.initState();
    _currentCourse = widget.course;
    _allCourses = widget.allCourses ?? [];
    _fetchDetails();
    if (_allCourses.isEmpty) {
      _fetchAllAvailableCourses();
    }
  }

  Future<void> _fetchAllAvailableCourses() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('user_role');
      List<dynamic> courses = [];
      if (role == 'instructor') {
        courses = await _apiService.getInstructorCourses();
      } else {
        courses = await _apiService.getStudentCourses();
      }
      if (mounted) {
        setState(() => _allCourses = courses);
      }
    } catch (e) {
      print("Error fetching all courses: $e");
    }
  }

  Future<void> _fetchDetails() async {
    setState(() => _isLoading = true);
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('user_role');
      setState(() => _isInstructor = role == 'instructor');

      // Fetch chapters
      final chapters = await _apiService.getCourseChapters(_currentCourse['id'].toString());
      setState(() => _chapters = chapters);

      // Fetch ALL materials for the course in one go
      final allMaterials = await _apiService.getMaterialsByCourse(_currentCourse['id'].toString());
      
      // Filter materials: those without a chapter_id go to _courseMaterials
      setState(() {
        // Use a set to track IDs to avoid duplicates in General Materials
        final Set<String> generalIds = {};
        _courseMaterials = allMaterials.where((m) {
          if (m['chapter_id'] != null) return false;
          String mId = m['id'].toString();
          if (generalIds.contains(mId)) return false;
          generalIds.add(mId);
          return true;
        }).toList();
        
        // Initialize chapter materials map
        _chapterMaterials = {};
        for (var chapter in chapters) {
          String chId = chapter['id'].toString();
          final Set<String> chapterMatIds = {};
          _chapterMaterials[chId] = allMaterials.where((m) {
            if (m['chapter_id']?.toString() != chId) return false;
            String mId = m['id'].toString();
            if (chapterMatIds.contains(mId)) return false;
            chapterMatIds.add(mId);
            return true;
          }).toList();
        }
      });
    } catch (e) {
      print("Error fetching details: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openGuide() async {
    final urlStr = _currentCourse['course_guide_url'];
    if (urlStr == null) return;
    
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Downloading and opening guide...")));
    try {
      await _apiService.downloadAndOpenFile(urlStr);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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
        leading: _selectedIds.isNotEmpty
        ? IconButton(
            icon: const Icon(Icons.close_rounded, color: Color(0xFF05398F)),
            onPressed: () => setState(() => _selectedIds.clear()),
          )
        : IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: widget.themeColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
      title: _selectedIds.isNotEmpty 
        ? Text("${_selectedIds.length} Selected", style: TextStyle(color: widget.themeColor, fontWeight: FontWeight.bold))
        : _buildCourseSwitcher(),
      actions: [
        if (_selectedIds.isNotEmpty && _isInstructor)
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            onPressed: _showRemoveConfirmation,
            tooltip: "Remove Selected",
          ),
        if (_selectedIds.isEmpty && _isInstructor)
          IconButton(
            icon: Icon(Icons.add_circle_outline_rounded, color: widget.themeColor),
            onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InstructorMaterialsScreen(
                      selectMode: true,
                      initialCourseId: _currentCourse['id'].toString(),
                    ),
                  ),
                );
                _fetchDetails(); // Refresh after adding
              },
              tooltip: "Add Materials",
            ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Course Info (Name removed as it is now in AppBar)
              Text(_currentCourse['instructor_name'] ?? '', 
                style: const TextStyle(color: Colors.black54, fontSize: 18)),
              
              const SizedBox(height: 25),
              
              // Course Guide Card
              if (_currentCourse['course_guide_url'] != null)
                _buildGuideCard()
              else
                _buildNoGuideCard(),
              
              const SizedBox(height: 30),
              
              // NEW: Main Course Materials (Unassigned to chapters)
              if (_courseMaterials.isNotEmpty) ...[
                const Text("General Materials", 
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: _courseMaterials.map((m) => _buildMaterialItem(m)).toList(),
                  ),
                ),
                const SizedBox(height: 30),
              ],
              
              const Text("Chapters & Materials", 
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 15),
              
              if (_chapters.isEmpty)
                const Center(child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Text("No chapters added for this course yet.", style: TextStyle(color: Colors.black38)),
                ))
              else
                ..._chapters.map((ch) => _buildChapterTile(ch)).toList(),
            ],
          ),
    );
  }

  Widget _buildCourseSwitcher() {
    if (_allCourses.length <= 1) {
      return Text(_currentCourse['title'] ?? 'Course Details', 
        style: TextStyle(color: widget.themeColor, fontWeight: FontWeight.bold));
    }

    return PopupMenuButton<dynamic>(
      offset: const Offset(0, 40),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              _currentCourse['title'] ?? 'Course Details',
              style: TextStyle(color: widget.themeColor, fontWeight: FontWeight.bold, fontSize: 20),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded, color: widget.themeColor),
        ],
      ),
      onSelected: (course) {
        if (course['id'] != _currentCourse['id']) {
          setState(() {
            _currentCourse = course;
            _selectedIds.clear();
          });
          _fetchDetails();
        }
      },
      itemBuilder: (context) => _allCourses
          .where((c) => c['id'] != _currentCourse['id'])
          .map((c) => PopupMenuItem<dynamic>(
        value: c,
        child: Text(
          c['title'] ?? c['course_code'],
          style: TextStyle(fontWeight: FontWeight.w500, color: widget.themeColor, fontSize: 20),
        ),
      )).toList(),
    );
  }

  Widget _buildGuideCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [widget.themeColor, widget.themeColor.withOpacity(0.8)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: widget.themeColor.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Course Guide", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("Official PDF syllabus and guidelines", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 15)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _openGuide,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: widget.themeColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text("View"),
          ),
        ],
      ),
    );
  }

  Widget _buildNoGuideCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black12),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.black38),
          SizedBox(width: 15),
          Text("No course guide uploaded yet.", style: TextStyle(color: Colors.black45, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildChapterTile(dynamic chapter) {
    String chId = chapter['id'].toString();
    List<dynamic> materials = _chapterMaterials[chId] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Chapter ${chapter['order_index'] + 1}", 
                        style: TextStyle(color: widget.themeColor, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(chapter['title'] ?? '', 
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                    ],
                  ),
                ),
                if (_isInstructor)
                  IconButton(
                    onPressed: () => _showShareDialog(chapter),
                    icon: Icon(Icons.add_circle_outline_rounded, color: widget.themeColor),
                    tooltip: "Share material to this chapter",
                  ),
              ],
            ),
          ),
          
          if (materials.isEmpty)
            const Padding(
              padding: EdgeInsets.only(left: 20, right: 20, bottom: 20),
              child: Text("No materials shared for this chapter.", style: TextStyle(color: Colors.black38, fontSize: 15, fontStyle: FontStyle.italic)),
            )
          else
            Container(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: materials.map((m) => _buildMaterialItem(m)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMaterialItem(dynamic material) {
    String mId = material['id'].toString();
    bool isSelected = _selectedIds.contains(mId);

    return InkWell(
      onTap: () {
        if (_selectedIds.isNotEmpty) {
          _toggleSelection(mId);
        } else {
          _openMaterial(material);
        }
      },
      onLongPress: () {
        if (_isInstructor) {
          _toggleSelection(mId);
        }
      },
      child: Container(
        color: isSelected ? widget.themeColor.withOpacity(0.1) : null,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSelected ? widget.themeColor : widget.themeColor.withOpacity(0.1), 
              borderRadius: BorderRadius.circular(10)
            ),
            child: Icon(
              isSelected ? Icons.check_rounded : Icons.description_rounded, 
              color: isSelected ? Colors.white : widget.themeColor, 
              size: 20
            ),
          ),
          title: Text(material['title'] ?? '', 
            style: TextStyle(
              fontSize: 16, 
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? widget.themeColor : Colors.black87
            )
          ),
          trailing: isSelected 
            ? Icon(Icons.check_circle_rounded, color: widget.themeColor, size: 20)
            : const Icon(Icons.chevron_right_rounded, color: Colors.black12),
        ),
      ),
    );
  }

  Future<void> _openMaterial(dynamic material) async {
    final urlStr = material['file_path'];
    if (urlStr == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("File not found")));
      return;
    }
    
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Downloading and opening material...")));
    try {
      await _apiService.downloadAndOpenFile(urlStr);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _showRemoveConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remove Materials"),
        content: Text("Are you sure you want to remove ${_selectedIds.length} material(s) from this course?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _removeSelectedMaterials();
            }, 
            child: const Text("Remove", style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  Future<void> _removeSelectedMaterials() async {
    setState(() => _isLoading = true);
    try {
      await _apiService.unshareMaterials(_selectedIds.toList(), _currentCourse['id'].toString());
      _selectedIds.clear();
      await _fetchDetails();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Materials removed successfully.")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showShareDialog(dynamic chapter) async {
    // Fetch instructor storage
    List<dynamic> myMaterials = [];
    try {
      myMaterials = await _apiService.getInstructorMaterials();
    } catch (e) {
      print(e);
      return;
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        Set<String> selectedIds = {};
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(25),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Share to ${chapter['title']}", 
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF05398F))),
                  const SizedBox(height: 10),
                  const Text("Select materials from your storage to assign to this chapter.", 
                    style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 20),
                  
                  Expanded(
                    child: myMaterials.isEmpty 
                      ? const Center(child: Text("Your storage is empty."))
                      : ListView.builder(
                          itemCount: myMaterials.length,
                          itemBuilder: (context, index) {
                            final mat = myMaterials[index];
                            final matId = mat['id'].toString();
                            final isSelected = selectedIds.contains(matId);
                            
                            return CheckboxListTile(
                              value: isSelected,
                              title: Text(mat['title'] ?? ''),
                              secondary: const Icon(Icons.insert_drive_file_rounded),
                              activeColor: widget.themeColor,
                              onChanged: (val) {
                                setSheetState(() {
                                  if (val == true) selectedIds.add(matId);
                                  else selectedIds.remove(matId);
                                });
                              },
                            );
                          },
                        ),
                  ),
                  
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: selectedIds.isEmpty ? null : () async {
                        try {
                          await _apiService.shareMaterials(
                            selectedIds.toList(), 
                            _currentCourse['id'].toString(), 
                            _currentCourse['department_id'].toString(), 
                            null, // section
                            chapterId: chapter['id'].toString()
                          );
                          Navigator.pop(context);
                          _fetchDetails();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Materials shared successfully!")));
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error sharing: $e")));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.themeColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text("Share Selected", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
