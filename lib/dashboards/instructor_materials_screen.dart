import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';

class InstructorMaterialsScreen extends StatefulWidget {
  const InstructorMaterialsScreen({super.key});

  @override
  State<InstructorMaterialsScreen> createState() => _InstructorMaterialsScreenState();
}

class _InstructorMaterialsScreenState extends State<InstructorMaterialsScreen> {
  final ApiService _apiService = ApiService();
  
  List<dynamic> _materials = [];
  List<dynamic> _courses = [];
  
  bool _isLoading = true;
  String? _error;
  bool _isSelecting = false;
  
  List<dynamic> _targets = [];
  
  final Set<String> _selectedMaterials = {};

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
      final materials = await _apiService.getInstructorMaterials();
      final courses = await _apiService.getInstructorCourses();
      final targetsData = await _apiService.getInstructorTargets();
      
      // The backend now returns a List of {id, name, sections: []}
      List<dynamic> targets = (targetsData is List) ? (targetsData as List) : [];
      
      setState(() {
        _materials = materials;
        _courses = courses;
        _targets = targets;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedMaterials.contains(id)) {
        _selectedMaterials.remove(id);
      } else {
        _selectedMaterials.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedMaterials.clear();
      _isSelecting = false;
    });
  }

  void _showUploadDialog() {
    if (_courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You need to be assigned to a course first.")),
      );
      return;
    }

    String? selectedCourseId = _courses.first['id'];
    String title = "";
    PlatformFile? selectedFile;

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
                  const Text("Upload Material", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF05398F))),
                  const SizedBox(height: 20),
                  
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
                  const SizedBox(height: 15),

                  // File Picker
                  const Text("File", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  GestureDetector(
                    onTap: () async {
                      FilePickerResult? result = await FilePicker.pickFiles();
                      if (result != null) {
                        setSheetState(() => selectedFile = result.files.first);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7FC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.black12)
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.attach_file, color: Color(0xFF05398F)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              selectedFile != null ? selectedFile!.name : "Tap to select a file",
                              style: TextStyle(color: selectedFile != null ? Colors.black87 : Colors.black54),
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Upload Button
                  isUploading 
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF09AEF5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                          ),
                          onPressed: () async {
                            if (selectedFile == null || selectedCourseId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a course and a file.")));
                              return;
                            }
                            
                            String autoTitle = selectedFile!.name;
                            
                            setSheetState(() => isUploading = true);
                            try {
                              await _apiService.uploadMaterial(selectedCourseId!, autoTitle, selectedFile!.path!);
                              if (!mounted) return;
                              Navigator.pop(context);
                              _fetchData(); // reload
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Uploaded Successfully")));
                            } catch (e) {
                              setSheetState(() => isUploading = false);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                            }
                          },
                          child: const Text("Upload", style: TextStyle(color: Colors.white, fontSize: 16)),
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

  // Define helper UI builders ...
  
  IconData _getIconForFile(String ext) {
    ext = ext.toLowerCase();
    if (ext.contains('pdf')) return Icons.picture_as_pdf_rounded;
    if (ext.contains('doc') || ext.contains('txt')) return Icons.description_rounded;
    if (ext.contains('mp4') || ext.contains('avi') || ext.contains('mov')) return Icons.video_collection_rounded;
    if (ext.contains('zip') || ext.contains('rar') || ext.contains('7z')) return Icons.folder_zip_rounded;
    if (ext.contains('jpg') || ext.contains('jpeg') || ext.contains('png') || ext.contains('gif')) return Icons.image_rounded;
    if (ext.contains('ppt') || ext.contains('pptx')) return Icons.slideshow_rounded;
    if (ext.contains('xls') || ext.contains('xlsx') || ext.contains('csv')) return Icons.table_chart_rounded;
    if (ext.contains('mp3') || ext.contains('wav') || ext.contains('aac')) return Icons.audiotrack_rounded;
    
    return Icons.insert_drive_file_rounded;
  }

  Color _getColorForFile(String ext) {
    ext = ext.toLowerCase();
    if (ext.contains('pdf')) return Colors.red.shade600;
    if (ext.contains('doc') || ext.contains('txt')) return Colors.blue.shade700;
    if (ext.contains('mp4') || ext.contains('avi') || ext.contains('mov')) return Colors.deepPurple;
    if (ext.contains('zip') || ext.contains('rar') || ext.contains('7z')) return Colors.orange.shade800;
    if (ext.contains('jpg') || ext.contains('jpeg') || ext.contains('png') || ext.contains('gif')) return Colors.teal;
    if (ext.contains('ppt') || ext.contains('pptx')) return Colors.orange.shade900;
    if (ext.contains('xls') || ext.contains('xlsx') || ext.contains('csv')) return Colors.green.shade700;
    if (ext.contains('mp3') || ext.contains('wav') || ext.contains('aac')) return Colors.pink.shade400;

    return Colors.blueGrey;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1048576) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    return "${(bytes / 1048576).toStringAsFixed(2)} MB";
  }

  void _showShareBottomSheet() {
    String selectedCourseTitle = "Selected Course";
    if (_selectedMaterials.isNotEmpty) {
      try {
        var firstMatId = _selectedMaterials.first;
        var firstMat = _materials.firstWhere((m) => m['id'].toString() == firstMatId);
        var courseMatch = _courses.firstWhere((c) => c['id'].toString() == firstMat['course_id'].toString(), orElse: () => <String, dynamic>{});
        if (courseMatch.isNotEmpty) {
           selectedCourseTitle = courseMatch['title'] ?? courseMatch['course_code'] ?? "Course";
        }
      } catch (e) {}
    }

    String? selectedDeptId = _targets.isNotEmpty ? _targets.first['id'].toString() : null;
    
    // Helper to get sections for a dept
    List<String> getCleanedSections(String? deptId) {
      if (deptId == null) return [];
      var dept = _targets.firstWhere((t) => t['id'].toString() == deptId, orElse: () => null);
      if (dept == null) return [];
      
      List<String> raw = List<String>.from(dept['sections'] ?? []);
      Set<String> cleaned = {};
      for (String s in raw) {
        String c = s.trim();
        if (c.length == 1) c = "Section $c";
        else if (!c.toLowerCase().startsWith('section ')) c = "Section $c";
        cleaned.add(c);
      }
      return cleaned.toList()..sort();
    }

    List<String> currentSections = getCleanedSections(selectedDeptId);
    String? selectedSection = currentSections.isNotEmpty ? currentSections.first : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("Share Materials", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF05398F))),
                  const SizedBox(height: 8),
                  Text("You are sharing ${_selectedMaterials.length} material(s).", style: const TextStyle(color: Colors.black54, fontSize: 14)),
                  const SizedBox(height: 20),
                  
                  const Text("Course", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 5),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(color: const Color(0xFFF4F7FC), borderRadius: BorderRadius.circular(10)),
                    child: Text(selectedCourseTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF05398F), fontSize: 16)),
                  ),
                  const SizedBox(height: 20),

                  const Text("Select Department", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(10)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedDeptId,
                        items: _targets.map((d) => DropdownMenuItem<String>(value: d['id'].toString(), child: Text(d['name']))).toList(),
                        onChanged: (val) {
                          setSheetState(() {
                            selectedDeptId = val;
                            currentSections = getCleanedSections(val);
                            selectedSection = currentSections.isNotEmpty ? currentSections.first : null;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text("Select Section", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(10)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedSection,
                        hint: const Text("No sections available"),
                        items: currentSections.map((s) => DropdownMenuItem<String>(value: s, child: Text(s))).toList(),
                        onChanged: (val) => setSheetState(() => selectedSection = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                       onPressed: () {
                          // TODO: implement actual share to groups API logic
                          Navigator.pop(context);
                          _clearSelection();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Materials Successfully Shared!"), backgroundColor: Colors.green)
                          );
                       },
                       style: ElevatedButton.styleFrom(
                         backgroundColor: const Color(0xFF09AEF5),
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                       ),
                       child: const Text("Share Now", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  List<Widget> _buildMaterialsList() {
    List<Widget> widgets = [];
    String? lastDateStr;
    const months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

    for (var mat in _materials) {
      if (mat['created_at'] != null) {
        DateTime dt = DateTime.parse(mat['created_at']).toLocal();
        String dateStr = "${months[dt.month - 1]} ${dt.day} ${dt.year}";
        
        if (lastDateStr != dateStr) {
          widgets.add(Padding(
            padding: const EdgeInsets.only(bottom: 12.0, top: 15.0),
            child: Text(dateStr, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87)),
          ));
          lastDateStr = dateStr;
        }
      }
      widgets.add(_buildMaterialTile(mat));
    }
    return widgets;
  }

  Widget _buildMaterialTile(Map<String, dynamic> material) {
    String mId = material['id'] ?? material['id'].toString();
    bool isSelected = _selectedMaterials.contains(mId);

    String ext = (material['file_path'] ?? material['title'] ?? '').split('.').last.toLowerCase();
    
    // Fallback to file_type if no extension found in path/title
    if (ext.isEmpty || !ext.contains(RegExp(r'[a-z0-9]'))) {
      ext = (material['file_type'] ?? '').toLowerCase();
    }
    
    IconData iconData = _getIconForFile(ext);
    Color colorData = _getColorForFile(ext);

    String timeStr = "Unknown Time";
    if (material['created_at'] != null) {
      DateTime dt = DateTime.parse(material['created_at']).toLocal();
      timeStr = "${dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour)}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'pm' : 'am'}";
    }

    bool isSelectionMode = _selectedMaterials.isNotEmpty || _isSelecting;

    return GestureDetector(
      onTap: () {
        if (isSelectionMode) {
          _toggleSelection(mId);
        } else {
          // Open material...
        }
      },
      onLongPress: () => _toggleSelection(mId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF09AEF5) : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorData.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: colorData, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    material["title"] ?? "Untitled", 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 15, 
                      color: isSelected ? const Color(0xFF05398F) : Colors.black87
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(_formatBytes(int.tryParse(material["file_size_bytes"]?.toString() ?? '0') ?? 0), style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      const Text("•", style: TextStyle(color: Colors.black38, fontSize: 13)),
                      const SizedBox(width: 8),
                      Text(timeStr, style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: Color(0xFF09AEF5))
            else if (_selectedMaterials.isNotEmpty)
              const Icon(Icons.circle_outlined, color: Colors.black26)
            else
              const Icon(Icons.more_vert_rounded, color: Colors.black38),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isSelectionMode = _selectedMaterials.isNotEmpty || _isSelecting;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: isSelectionMode ? const Color(0xFFE3F2FD) : const Color(0xFFF4F7FC),
        elevation: 0,
        leading: isSelectionMode 
          ? IconButton(
              icon: const Icon(Icons.close_rounded, color: Color(0xFF05398F)),
              onPressed: _clearSelection,
            )
          : IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF05398F), size: 20),
              onPressed: () => Navigator.pop(context),
            ),
        title: Text(
          isSelectionMode ? "${_selectedMaterials.length} Selected" : "My Materials", 
          style: const TextStyle(color: Color(0xFF05398F), fontSize: 22, fontWeight: FontWeight.bold)
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : _error != null 
          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isSelectionMode)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 15),
                      child: Text(
                        "All Uploaded Materials",
                        style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w600),
                      ),
                    ),

                  if (_materials.isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(30), child: Text("No materials uploaded yet.")))
                  else
                    ..._buildMaterialsList(),

                  const SizedBox(height: 100),
                ],
              ),
            ),
      floatingActionButton: isSelectionMode ? null : Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "upload_btn",
            onPressed: _showUploadDialog,
            backgroundColor: const Color(0xFF09AEF5),
            elevation: 4,
            child: const Icon(Icons.cloud_upload_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 15),
          FloatingActionButton(
            heroTag: "share_btn",
            onPressed: () {
               setState(() {
                 _isSelecting = true;
               });
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tap on the materials you wish to share.")));
            },
            backgroundColor: const Color(0xFF09AEF5),
            elevation: 4,
            child: const Icon(Icons.share_rounded, color: Colors.white, size: 28),
          ),
        ],
      ),
      bottomNavigationBar: isSelectionMode 
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))
                  ]
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    onPressed: () {
                       if (_selectedMaterials.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select at least one material.")));
                       } else {
                          _showShareBottomSheet();
                       }
                    },
                    icon: const Icon(Icons.share_rounded, color: Colors.white, size: 24),
                    label: const Text("Share", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF09AEF5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
