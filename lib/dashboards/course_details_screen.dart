import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'instructor_materials_screen.dart';

class CourseDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> course;
  final Color themeColor;

  const CourseDetailsScreen({super.key, required this.course, this.themeColor = Colors.blue});

  @override
  State<CourseDetailsScreen> createState() => _CourseDetailsScreenState();
}

class _CourseDetailsScreenState extends State<CourseDetailsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _chapters = [];
  List<dynamic> _courseMaterials = []; // Materials not assigned to a chapter
  Map<String, List<dynamic>> _chapterMaterials = {};
  bool _isLoading = true;
  bool _isInstructor = false;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() => _isLoading = true);
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('user_role');
      setState(() => _isInstructor = role == 'instructor');

      final chapters = await _apiService.getCourseChapters(widget.course['id'].toString());
      setState(() => _chapters = chapters);

      // Fetch main materials (those not assigned to a chapter)
      final mainMaterials = await _apiService.getMaterialsByCourse(widget.course['id'].toString());
      setState(() => _courseMaterials = mainMaterials);
      
      // Fetch materials for each chapter
      for (var chapter in chapters) {
        final materials = await _apiService.getMaterialsByCourse(
          widget.course['id'].toString(), 
          chapterId: chapter['id'].toString()
        );
        setState(() => _chapterMaterials[chapter['id'].toString()] = materials);
      }
    } catch (e) {
      print("Error fetching details: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openGuide() async {
    final urlStr = widget.course['course_guide_url'];
    if (urlStr == null) return;
    
    // Normalize URL
    String baseUrl = ApiService.baseUrl.replaceAll('/api', '');
    final uri = Uri.parse('$baseUrl$urlStr');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open guide.")));
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: widget.themeColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.course['title'] ?? 'Course Details', 
          style: TextStyle(color: widget.themeColor, fontWeight: FontWeight.bold)),
        actions: [
          if (_isInstructor)
            IconButton(
              icon: Icon(Icons.add_circle_outline_rounded, color: widget.themeColor),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InstructorMaterialsScreen(
                      selectMode: true,
                      initialCourseId: widget.course['id'].toString(),
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
              // Course Header
              Text(widget.course['title'] ?? '', 
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text(widget.course['instructor_name'] ?? '', 
                style: const TextStyle(color: Colors.black54, fontSize: 16)),
              
              const SizedBox(height: 25),
              
              // Course Guide Card
              if (widget.course['course_guide_url'] != null)
                _buildGuideCard()
              else
                _buildNoGuideCard(),
              
              const SizedBox(height: 30),
              
              // NEW: Main Course Materials (Unassigned to chapters)
              if (_courseMaterials.isNotEmpty) ...[
                const Text("General Materials", 
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
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
                const Text("Course Guide", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("Official PDF syllabus and guidelines", style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
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
                        style: TextStyle(color: widget.themeColor, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(chapter['title'] ?? '', 
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
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
              child: Text("No materials shared for this chapter.", style: TextStyle(color: Colors.black38, fontSize: 13, fontStyle: FontStyle.italic)),
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: widget.themeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(Icons.description_rounded, color: widget.themeColor, size: 20),
      ),
      title: Text(material['title'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black12),
      onTap: () {
        // Open material logic
      },
    );
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
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF05398F))),
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
                            widget.course['id'].toString(), 
                            widget.course['department_id'].toString(), 
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
