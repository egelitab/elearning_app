import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';

class InstructorMaterialsScreen extends StatefulWidget {
  final bool selectMode;
  final String? initialCourseId;

  const InstructorMaterialsScreen({
    super.key, 
    this.selectMode = false,
    this.initialCourseId,
  });

  @override
  State<InstructorMaterialsScreen> createState() => _InstructorMaterialsScreenState();
}

class _InstructorMaterialsScreenState extends State<InstructorMaterialsScreen> {
  final ApiService _apiService = ApiService();
  
  List<dynamic> _materials = [];
  List<dynamic> _courses = [];
  List<dynamic> _chapters = []; // Added to store chapters for select mode
  
  bool _isLoading = true;
  String? _error;
  bool _isSelecting = false;
  
  // Search state
  bool _isSearching = false;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();
  
  List<dynamic> _targets = [];
  
  final Set<String> _selectedMaterials = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.selectMode) {
      _isSelecting = true;
    }
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Fetch all required data in parallel with timeouts
      final results = await Future.wait([
        _apiService.getInstructorMaterials().timeout(const Duration(seconds: 10)),
        _apiService.getInstructorCourses().timeout(const Duration(seconds: 10)),
        _apiService.getInstructorTargets().timeout(const Duration(seconds: 10)),
      ]);

      final materials = results[0] as List<dynamic>;
      final courses = results[1] as List<dynamic>;
      final targetsData = results[2];
      
      // The backend returns a List of {id, name, sections: []}
      List<dynamic> targets = (targetsData is List) ? (targetsData as List) : [];
      
      if (mounted) {
        setState(() {
          _materials = materials;
          _courses = courses;
          _targets = targets;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  Future<void> _handleDirectUpload() async {
    if (_courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(behavior: SnackBarBehavior.floating, content: Text("You need to be assigned to a course first.")),
      );
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
    String? selectedCourseId = _courses.first['id'];

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
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF09AEF5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                          ),
                          onPressed: () async {
                            if (selectedCourseId == null) return;
                            
                            setSheetState(() => isUploading = true);
                            try {
                              await _apiService.uploadMaterial(selectedCourseId!, selectedFile.name, selectedFile.path!);
                              if (!mounted) return;
                              Navigator.pop(context);
                              _fetchData(); // reload
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(behavior: SnackBarBehavior.floating, content: Text("Uploaded Successfully")));
                            } catch (e) {
                              if (mounted) {
                                setSheetState(() => isUploading = false);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(e.toString())));
                              }
                            }
                          },
                          child: const Text("Upload Now", style: TextStyle(color: Colors.white, fontSize: 16)),
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


  void _showRenameDialog(String id, String fullTitle) {
    // Separate the base name from the extension
    String baseName = fullTitle;
    String extension = "";
    if (fullTitle.contains('.') && fullTitle.lastIndexOf('.') > 0) {
      int extIndex = fullTitle.lastIndexOf('.');
      baseName = fullTitle.substring(0, extIndex);
      extension = fullTitle.substring(extIndex);
    }
    
    TextEditingController _controller = TextEditingController(text: baseName);
    _controller.selection = TextSelection(baseOffset: 0, extentOffset: baseName.length);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Rename Material", style: TextStyle(color: Color(0xFF05398F), fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Enter new name",
            filled: true,
            fillColor: const Color(0xFFF4F7FC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () async {
              // Re-attach the extension when saving
              String finalName = _controller.text.trim() + extension;
              
              Navigator.pop(context); // Close dialog early for better UX
              try {
                // Show loading snackbar
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(behavior: SnackBarBehavior.floating, content: Text("Renaming...")));
                await _apiService.renameMaterial(id, finalName);
                _fetchData();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text("Renamed to $finalName", style: const TextStyle(color: Colors.white)), backgroundColor: Colors.green));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(e.toString().replaceAll('Exception: Server Error: ', '')), backgroundColor: Colors.red));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF09AEF5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text("Save", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRemoveDialog(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Remove Material", style: TextStyle(color: Color(0xFF05398F), fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to permanently delete this material? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog early
              try {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(behavior: SnackBarBehavior.floating, content: Text("Deleting...")));
                await _apiService.deleteMaterial(id);
                _fetchData();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(behavior: SnackBarBehavior.floating, content: Text("Material deleted", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(e.toString().replaceAll('Exception: Server Error: ', '')), backgroundColor: Colors.red));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
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
    String? selectedCourseId = widget.initialCourseId ?? (_courses.isNotEmpty ? _courses.first['id'] : null);
    String? selectedDeptId = _targets.isNotEmpty ? _targets.first['id'].toString() : null;
    String? selectedChapterId;
    List<dynamic> chapters = [];
    bool isLoadingChapters = false;
    
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
      List<String> sorted = cleaned.toList()..sort();
      sorted.insert(0, "All Sections");
      return sorted;
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
            // Function to fetch chapters for a course
            Future<void> fetchChapters(String courseId) async {
              setSheetState(() => isLoadingChapters = true);
              try {
                final fetchedChapters = await _apiService.getCourseChapters(courseId);
                setSheetState(() {
                  chapters = fetchedChapters;
                  isLoadingChapters = false;
                });
              } catch (e) {
                setSheetState(() => isLoadingChapters = false);
                print("Error fetching chapters: $e");
              }
            }

            // Fetch chapters if a course is already selected
            if (selectedCourseId != null && chapters.isEmpty && !isLoadingChapters) {
              fetchChapters(selectedCourseId!);
            }

            return Container(
              padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 30),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              ),
              child: SingleChildScrollView(
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
                    
                    const Text("Select Course", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(10)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedCourseId,
                          items: _courses.map((c) => DropdownMenuItem<String>(
                            value: c['id'],
                            child: Text(c['title'] ?? c['course_code']),
                          )).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setSheetState(() {
                                selectedCourseId = val;
                                chapters = [];
                                selectedChapterId = null;
                              });
                              fetchChapters(val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text("Select Chapter (Optional)", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 5),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(10)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedChapterId,
                          hint: Text(isLoadingChapters ? "Loading chapters..." : "No Chapter (Main screen)"),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text("None (Show on Main Screen)"),
                            ),
                            ...chapters.map((ch) => DropdownMenuItem<String>(
                              value: ch['id'].toString(),
                              child: Text("Chapter ${ch['order_index'] + 1}: ${ch['title']}"),
                            )).toList(),
                          ],
                          onChanged: (val) {
                            setSheetState(() => selectedChapterId = val);
                          },
                        ),
                      ),
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
                         onPressed: () async {
                            if (selectedDeptId == null || selectedCourseId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(behavior: SnackBarBehavior.floating, content: Text("Please select both course and department.")));
                              return;
                            }
                            
                            Navigator.pop(context); // Close the sheet early
                            try {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(behavior: SnackBarBehavior.floating, content: Text("Sharing...")));
                              
                              String? finalSection = selectedSection == "All Sections" ? null : selectedSection;

                              await _apiService.shareMaterials(
                                _selectedMaterials.toList(), 
                                selectedCourseId,
                                selectedDeptId!, 
                                finalSection,
                                chapterId: selectedChapterId
                              );
                              
                              _clearSelection();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(behavior: SnackBarBehavior.floating, content: Text("Materials Successfully Shared!"), backgroundColor: Colors.green)
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(e.toString().replaceAll('Exception: Server Error: ', '')), backgroundColor: Colors.red));
                            }
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
              ),
            );
          },
        );
      },
    );
  }

  List<Widget> _buildMaterialsList() {
    List<Widget> widgets = [];
    String? lastDateStr;
    const months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

    List<dynamic> filteredMaterials = _materials;
    if (_searchQuery.isNotEmpty) {
      filteredMaterials = _materials.where((mat) {
        String title = (mat['title'] ?? '').toString().toLowerCase();
        return title.contains(_searchQuery);
      }).toList();
    }

    for (var mat in filteredMaterials) {
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
          _openMaterial(material);
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
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.black38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {
                  if (value == 'share') {
                    _clearSelection();
                    _toggleSelection(mId);
                    _showShareBottomSheet();
                  } else if (value == 'rename') {
                    _showRenameDialog(mId, material["title"] ?? "Untitled");
                  } else if (value == 'remove') {
                    _showRemoveDialog(mId);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'share',
                    child: Row(children: [Icon(Icons.share_rounded, size: 20, color: Colors.blue), SizedBox(width: 10), Text("Share")])
                  ),
                  const PopupMenuItem(
                    value: 'rename',
                    child: Row(children: [Icon(Icons.edit_rounded, size: 20, color: Colors.orange), SizedBox(width: 10), Text("Rename")])
                  ),
                  const PopupMenuItem(
                    value: 'remove',
                    child: Row(children: [Icon(Icons.delete_rounded, size: 20, color: Colors.red), SizedBox(width: 10), Text("Remove", style: TextStyle(color: Colors.red))])
                  ),
                ],
              ),
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
        title: _isSearching && !isSelectionMode
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: "Search materials...",
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.black38),
                ),
                style: const TextStyle(color: Color(0xFF05398F), fontSize: 18),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.toLowerCase();
                  });
                },
              )
            : Text(
                isSelectionMode ? "${_selectedMaterials.length} Selected" : "My Materials", 
                style: const TextStyle(color: Color(0xFF05398F), fontSize: 22, fontWeight: FontWeight.bold)
              ),
        actions: [
          if (!isSelectionMode)
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
              },
            ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : _error != null 
          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
          : Stack(
              children: [
                SingleChildScrollView(
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
                  else if (_searchQuery.isNotEmpty && _materials.where((m) => (m['title'] ?? '').toString().toLowerCase().contains(_searchQuery)).isEmpty)
                    const Center(child: Padding(padding: EdgeInsets.all(30), child: Text("No matching materials found.")))
                  else
                    ..._buildMaterialsList(),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: !isSelectionMode
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  heroTag: "upload_btn",
                  onPressed: _handleDirectUpload,
                  backgroundColor: const Color(0xFF09AEF5),
                  elevation: 4,
                  icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white),
                  label: const Text("Upload", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                const SizedBox(width: 15),
                FloatingActionButton.extended(
                  heroTag: "share_btn",
                  onPressed: () {
                    setState(() {
                      _isSelecting = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tap on the materials you wish to share.")));
                  },
                  backgroundColor: const Color(0xFF09AEF5),
                  elevation: 4,
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                  label: const Text("Share", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ],
            )
          : null,
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
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(behavior: SnackBarBehavior.floating, content: Text("Please select at least one material.")));
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
