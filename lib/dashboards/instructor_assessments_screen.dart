import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'instructor_storage_explorer_screen.dart';
import 'instructor_assessment_details_screen.dart';
import 'package:intl/intl.dart';

class InstructorAssessmentsScreen extends StatefulWidget {
  final String? initialCourseId;
  const InstructorAssessmentsScreen({super.key, this.initialCourseId});

  @override
  State<InstructorAssessmentsScreen> createState() => _InstructorAssessmentsScreenState();
}

class _InstructorAssessmentsScreenState extends State<InstructorAssessmentsScreen> {
  final ApiService _apiService = ApiService();
  String _selectedFilter = 'All';
  String? _selectedCourseIdFilter; // Add this to filter by course
  final List<String> _filters = ['All', 'Assignment', 'Project', 'Presentation'];

  List<dynamic> _classes = [];
  List<dynamic> _courseSections = []; // To store sections for group creation
  List<dynamic> _availableGroups = []; // To store existing groups for selection
  List<dynamic> _assessments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedCourseIdFilter = widget.initialCourseId; // Initialize with initialCourseId if provided
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      print("Fetching courses...");
      final courses = await _apiService.getInstructorCourses().timeout(const Duration(seconds: 15));
      print("Fetched ${courses.length} courses.");
      
      List<Map<String, dynamic>> processedClasses = [];
      for (var course in courses) {
        print("Fetching stats for course ${course['id']}...");
        final stats = await _apiService.getCourseEnrollmentStats(course['id'].toString()).timeout(const Duration(seconds: 15));
        
        processedClasses.add({
          "id": course['id'].toString(),
          "name": "${course['title']} (${course['course_code']})",
          "initials": course['title'].toString().split(' ').map((e) => e.isNotEmpty ? e[0].toUpperCase() : '').take(2).join(),
          "color": _getCourseColor(course['course_code']),
          "sections": stats.map((s) => {
            "id": "${course['id']}_${s['section']}",
            "name": "${s['department_name']} - Section ${s['section']}",
            "students": s['student_count']
          }).toList()
        });
      }

      // Fetch all assessments for all courses
      print("Fetching assessments for all courses...");
      List<dynamic> allAssessments = [];
      for (var course in courses) {
        final assessments = await _apiService.getAssessments(course['id'].toString()).timeout(const Duration(seconds: 15));
        allAssessments.addAll(assessments);
      }
      print("Fetched ${allAssessments.length} assessments total.");

      if (mounted) {
        setState(() {
          _classes = processedClasses;
          _assessments = allAssessments;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error in _fetchData: $e");
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Color _getCourseColor(String? code) {
    if (code == null) return Colors.blue;
    final int hash = code.hashCode;
    final List<Color> colors = [Colors.blue, Colors.purple, Colors.orange, Colors.green, Colors.red, Colors.teal];
    return colors[hash % colors.length];
  }

  void _showCreateAssessmentSheet() {
    String selectedType = 'Assignment';
    String selectedFormat = 'Individual';
    String? selectedGroup;
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    DateTime? selectedDate;
    List<dynamic> attachedFiles = []; // To store selected files from explorer
    Set<String> selectedSections = {};
    Set<String> expandedCourses = {};
    // Default to the current filter, or the first available course if nothing is filtered
    String? selectedCourseId = _selectedCourseIdFilter ?? (_classes.isNotEmpty ? _classes[0]["id"].toString() : null);
    
    // If a course is pre-selected, expand it by default
    if (selectedCourseId != null) {
      expandedCourses.add(selectedCourseId);
    }
    
    // Function to fetch groups when course selection changes
    Future<void> updateGroupsForCourse(String courseId, StateSetter setSheetState) async {
      try {
        final groups = await _apiService.getExistingGroups(courseId);
        setSheetState(() {
          _availableGroups = groups;
        });
      } catch (e) {
        print("Error fetching groups: $e");
      }
    }

    // Initial fetch if course is pre-selected and format is group
    if (selectedCourseId != null && selectedFormat == 'Group') {
      _apiService.getExistingGroups(selectedCourseId!).then((groups) {
        _availableGroups = groups;
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
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
                          decoration: BoxDecoration(
                            color: Colors.black12,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Create Assessment",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF05398F)),
                      ),
                       const SizedBox(height: 20),

                      // Title Field
                      TextField(
                        controller: titleController,
                        onChanged: (val) => setSheetState(() {}), // Trigger rebuild to update button state
                        decoration: InputDecoration(
                          labelText: "Assessment Title",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.title),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Course Selection Dropdown
                      const Text("Course", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F7FC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            hint: const Text("Select Course"),
                            value: selectedCourseId,
                            items: _classes.map((cls) {
                              return DropdownMenuItem<String>(
                                value: cls["id"].toString(),
                                child: Text(cls["name"]),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setSheetState(() {
                                  selectedCourseId = val;
                                  selectedSections.clear();
                                  selectedGroup = null;
                                  expandedCourses.clear();
                                  expandedCourses.add(val);
                                  if (selectedFormat == 'Group') {
                                    updateGroupsForCourse(val, setSheetState);
                                  }
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text("Assign To Sections", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      // List of classes and their expandable sections
                      if (selectedCourseId == null)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(child: Text("Please select a course first", style: TextStyle(color: Colors.black38))),
                        )
                      else ..._classes.where((c) => c['id'] == selectedCourseId).map((cls) {
                        bool isExpanded = expandedCourses.contains(cls["id"]);
                        List<dynamic> sections = cls["sections"];
                        
                        bool allSectionsSelected = sections.every((sec) => selectedSections.contains(sec["id"]));
                        bool someSectionsSelected = sections.any((sec) => selectedSections.contains(sec["id"])) && !allSectionsSelected;

                        return Column(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setSheetState(() {
                                  if (isExpanded) {
                                    expandedCourses.remove(cls["id"]);
                                  } else {
                                    expandedCourses.add(cls["id"]);
                                  }
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: allSectionsSelected ? const Color(0xFF09AEF5).withOpacity(0.1) : Colors.white,
                                  border: Border.all(
                                    color: allSectionsSelected ? const Color(0xFF09AEF5) : Colors.black12,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: (cls["color"] as Color).withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(cls["initials"], style: TextStyle(color: cls["color"], fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                    Expanded(
                                      child: Text(
                                        cls["name"],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold, 
                                          color: allSectionsSelected ? const Color(0xFF05398F) : Colors.black87
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        setSheetState(() {
                                          if (allSectionsSelected) {
                                            for (var sec in sections) {
                                              selectedSections.remove(sec["id"]);
                                            }
                                            if (selectedSections.isEmpty) selectedCourseId = null;
                                          } else {
                                            if (selectedCourseId != cls["id"]) {
                                              selectedSections.clear();
                                              selectedCourseId = cls["id"];
                                              selectedGroup = null;
                                              if (selectedFormat == 'Group') {
                                                updateGroupsForCourse(selectedCourseId!, setSheetState);
                                              }
                                            }
                                            for (var sec in sections) {
                                              selectedSections.add(sec["id"]);
                                            }
                                          }
                                        });
                                      },
                                      child: Icon(
                                        allSectionsSelected ? Icons.check_box_rounded : (someSectionsSelected ? Icons.indeterminate_check_box_rounded : Icons.check_box_outline_blank_rounded),
                                        color: (allSectionsSelected || someSectionsSelected) ? const Color(0xFF09AEF5) : Colors.black26,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Icon(isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded, color: Colors.black45),
                                  ],
                                ),
                              ),
                            ),
                            // Expandable sections list
                            if (isExpanded)
                              Padding(
                                padding: const EdgeInsets.only(left: 20, right: 10, bottom: 10),
                                child: Column(
                                  children: sections.map((sec) {
                                    bool isSecSelected = selectedSections.contains(sec["id"]);
                                    return GestureDetector(
                                      onTap: () {
                                        setSheetState(() {
                                          if (isSecSelected) {
                                            selectedSections.remove(sec["id"]);
                                            if (selectedSections.isEmpty) selectedCourseId = null;
                                          } else {
                                            if (selectedCourseId != cls["id"]) {
                                              selectedSections.clear();
                                              selectedCourseId = cls["id"];
                                              selectedGroup = null;
                                              if (selectedFormat == 'Group') {
                                                updateGroupsForCourse(selectedCourseId!, setSheetState);
                                              }
                                            }
                                            selectedSections.add(sec["id"]);
                                          }
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                        margin: const EdgeInsets.only(bottom: 6),
                                        decoration: BoxDecoration(
                                          color: isSecSelected ? const Color(0xFF09AEF5).withOpacity(0.05) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              isSecSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                              color: isSecSelected ? const Color(0xFF09AEF5) : Colors.black26,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              sec["name"],
                                              style: TextStyle(
                                                color: isSecSelected ? const Color(0xFF05398F) : Colors.black87,
                                                fontWeight: isSecSelected ? FontWeight.w600 : FontWeight.normal
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                          ],
                        );
                      }),
                      const SizedBox(height: 16),

                      // Type Selection
                      const Text("Assessment Type", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        children: ['Assignment', 'Project', 'Presentation'].map((type) {
                          final isSelected = selectedType == type;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8, bottom: 8),
                            child: InkWell(
                              onTap: () => setSheetState(() => selectedType = type),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF09AEF5) : const Color(0xFFF4F7FC),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: isSelected ? Colors.transparent : Colors.black12),
                                ),
                                child: Text(
                                  type,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black54,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Format Selection
                      const Text("Assessment Format", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        children: ['Individual', 'Group'].map((format) {
                          final isSelected = selectedFormat == format;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8, bottom: 8),
                            child: InkWell(
                              onTap: () async {
                                setSheetState(() {
                                  selectedFormat = format;
                                  if (format == 'Individual') {
                                    selectedGroup = null;
                                  }
                                });
                                
                                if (format == 'Group' && selectedCourseId != null) {
                                  await updateGroupsForCourse(selectedCourseId!, setSheetState);
                                }
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF09AEF5) : const Color(0xFFF4F7FC),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: isSelected ? Colors.transparent : Colors.black12),
                                ),
                                child: Text(
                                  format,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black54,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      if (selectedFormat == 'Group') ...[
                        const Text("Select Group Batch", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F7FC),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: selectedGroup,
                                      hint: Text(_availableGroups.isEmpty ? "No groups found" : "Select Batch"),
                                      disabledHint: const Text("No groups found for this course"),
                                      onChanged: (val) {
                                        setSheetState(() => selectedGroup = val);
                                      },
                                      items: _availableGroups.isEmpty 
                                        ? null 
                                        : _availableGroups.map((g) => g['batch_name']).toSet().where((b) => b != null).map((batch) {
                                            return DropdownMenuItem<String>(
                                              value: batch.toString(),
                                              child: Text(batch.toString()),
                                            );
                                          }).toList(),
                                    ),
                                  ),
                                ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                if (selectedCourseId != null) {
                                  _showCreateGroupBottomSheet(setSheetState, selectedCourseId!);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Please select a course first"))
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF09AEF5).withOpacity(0.1),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              ),
                              child: const Text("Create New", style: TextStyle(color: Color(0xFF09AEF5), fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Description Field
                      TextField(
                        controller: descController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: "Description (Optional)",
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // File Upload & Deadline
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final List<dynamic>? result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const InstructorStorageExplorerScreen(isPicker: true),
                                  ),
                                );
                                
                                if (result != null && result.isNotEmpty) {
                                  setSheetState(() {
                                    attachedFiles = result;
                                  });
                                }
                              },
                              icon: const Icon(Icons.attach_file, color: Color(0xFF05398F)),
                              label: Text(
                                attachedFiles.isEmpty ? "Attach File" : attachedFiles[0]['name'].toString(), 
                                style: const TextStyle(color: Color(0xFF05398F)),
                                overflow: TextOverflow.ellipsis,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF4F7FC),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.now(),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime(2101),
                                );
                                if (picked != null) {
                                  if (!context.mounted) return;
                                  final TimeOfDay? time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );
                                  if (time != null) {
                                    setSheetState(() {
                                      selectedDate = DateTime(
                                        picked.year, picked.month, picked.day,
                                        time.hour, time.minute,
                                      );
                                    });
                                  }
                                }
                              },
                              icon: const Icon(Icons.calendar_today, color: Color(0xFF05398F)),
                              label: Text(
                                selectedDate == null ? "Set Deadline" : "${selectedDate!.month}/${selectedDate!.day} ${selectedDate!.hour}:${selectedDate!.minute.toString().padLeft(2, '0')}",
                                style: const TextStyle(color: Color(0xFF05398F)),
                                overflow: TextOverflow.ellipsis,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF4F7FC),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Create Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: (titleController.text.isNotEmpty && 
                                      selectedDate != null && 
                                      selectedSections.isNotEmpty &&
                                      selectedCourseId != null &&
                                      (selectedFormat != 'Group' || selectedGroup != null)) 
                          ? () async {
                              try {
                                final assessmentData = {
                                  'course_id': selectedCourseId,
                                  'title': titleController.text,
                                  'description': descController.text,
                                  'due_date': selectedDate!.toIso8601String(),
                                  'is_group_assignment': selectedFormat == 'Group',
                                  'file_path': attachedFiles.isNotEmpty ? attachedFiles[0]['file_path'] : null,
                                };
                                
                                await _apiService.createAssessment(assessmentData);
                                
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  _fetchData(); // Refresh list
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Assessment Created Successfully!"), backgroundColor: Colors.green)
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
                                  );
                                }
                              }
                          } : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF09AEF5),
                            disabledBackgroundColor: Colors.black12,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: (titleController.text.isNotEmpty && selectedDate != null && selectedSections.isNotEmpty) ? 4 : 0,
                          ),
                          child: const Text("Create Assessment", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            );
          }
        );
      }
    );
  }



  void _showCreateGroupBottomSheet(StateSetter setAssessmentSheetState, String courseId) {
    String? selectedSectionId;
    String? groupName;
    int groupSize = 5;
    String groupingMethod = 'Random';
    
    final List<String> methods = ['Random', 'Alphabetic', 'GPA Top Distributed'];
    final TextEditingController nameController = TextEditingController();
    final TextEditingController sizeController = TextEditingController(text: '5');
    
    // Get sections for the specific course from the state
    final course = _classes.firstWhere((c) => c['id'] == courseId, orElse: () => {});
    final sections = (course['sections'] as List? ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20, 
                left: 20, 
                right: 20, 
                bottom: MediaQuery.of(context).viewInsets.bottom + 30
              ),
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
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Form New Groups",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF05398F)),
                    ),
                    const SizedBox(height: 20),
                    
                    // 1. Group Name
                    const Text("Group Title", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        hintText: "e.g., Final Project Teams",
                        filled: true,
                        fillColor: const Color(0xFFF4F7FC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      onChanged: (val) => groupName = val,
                    ),
                    const SizedBox(height: 20),

                    // 2. Select Section
                    const Text("Select Class/Section", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F7FC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: const Text("Choose Section"),
                          value: selectedSectionId,
                          items: sections.map((sec) {
                            return DropdownMenuItem<String>(
                              value: sec["id"],
                              child: Text(sec['name']),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setSheetState(() {
                              selectedSectionId = val;
                            });
                          },
                        ),
                      ),
                    ),
                    if (selectedSectionId != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.people_alt_rounded, color: Color(0xFF09AEF5), size: 20),
                            const SizedBox(width: 10),
                            const Text(
                              "Total Students:", 
                              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)
                            ),
                            const Spacer(),
                            Text(
                              "${sections.firstWhere((s) => s["id"] == selectedSectionId)["students"]}",
                              style: const TextStyle(color: Color(0xFF05398F), fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        // 3. Group Size
                        Expanded(
                          flex: 1,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Students Per Group", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: sizeController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(0xFFF4F7FC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  contentPadding: EdgeInsets.zero,
                                  prefixIcon: IconButton(
                                    icon: const Icon(Icons.remove_rounded, color: Color(0xFF05398F), size: 20),
                                    onPressed: () {
                                      if (groupSize > 1) {
                                        setSheetState(() {
                                          groupSize--;
                                          sizeController.text = groupSize.toString();
                                        });
                                      }
                                    },
                                    splashRadius: 20,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.add_rounded, color: Color(0xFF05398F), size: 20),
                                    onPressed: () {
                                      setSheetState(() {
                                        groupSize++;
                                        sizeController.text = groupSize.toString();
                                      });
                                    },
                                    splashRadius: 20,
                                  ),
                                ),
                                onChanged: (val) {
                                  if (int.tryParse(val) != null) {
                                    setSheetState(() {
                                      groupSize = int.parse(val);
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 15),
                        // 4. Method
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Grouping Method", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F7FC),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    isExpanded: true,
                                    value: groupingMethod,
                                    items: methods.map((m) {
                                      return DropdownMenuItem<String>(value: m, child: Text(m, style: const TextStyle(fontSize: 14)));
                                    }).toList(),
                                    onChanged: (val) {
                                      if (val != null) {
                                        setSheetState(() => groupingMethod = val);
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 35),
                    
                    // Generate Button
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: (selectedSectionId != null && groupName != null && groupName!.isNotEmpty && groupSize > 0) 
                          ? () {
                              final sec = sections.firstWhere((s) => s["id"] == selectedSectionId);
                              int totalStudents = sec["students"];
                              
                              int remainder = totalStudents % groupSize;
                              if (remainder != 0) {
                                // Show warning alert
                                showDialog(
                                  context: context,
                                  builder: (ctx) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      title: const Text("Uneven Group Distribution"),
                                      content: Text("The group size ($groupSize) does not evenly divide the total number of students ($totalStudents). One group will only have $remainder students. Do you wish to continue?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(ctx); // Close dialog
                                          },
                                          child: const Text("Change Options", style: TextStyle(color: Colors.black54)),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(ctx); // Close dialog
                                            Navigator.pop(context); // Close sheet
                                            _finalizeGroupCreation(groupName!, sec, totalStudents, groupSize, groupingMethod, setAssessmentSheetState, courseId);
                                          },
                                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF09AEF5)),
                                          child: const Text("Continue", style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    );
                                  }
                                );
                              } else {
                                Navigator.pop(context); // Close sheet
                                _finalizeGroupCreation(groupName!, sec, totalStudents, groupSize, groupingMethod, setAssessmentSheetState, courseId);
                              }
                          } : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF09AEF5),
                          disabledBackgroundColor: Colors.black12,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: (selectedSectionId != null && groupName != null && groupName!.isNotEmpty && groupSize > 0) ? 4 : 0,
                        ),
                        child: const Text("Generate Groups", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  Future<void> _finalizeGroupCreation(String title, dynamic section, int totalStudents, int size, String method, StateSetter setAssessmentSheetState, String courseId) async {
    try {
      // Split section ID to get original section name/id if needed, 
      // but generateGroups takes section name as string usually in this backend.
      String sectionName = section['name'].toString().split(' - Section ')[1];
      
      await _apiService.generateGroups(
        courseId, 
        size, 
        method: method, 
        title: title,
        section: sectionName
      );
      
      // Re-fetch groups for the assessment sheet
      final groups = await _apiService.getExistingGroups(courseId);
      setAssessmentSheetState(() {
        _availableGroups = groups;
      });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Successfully formed groups using '$method' method!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error generating groups: $e"), backgroundColor: Colors.red)
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var filteredAssessments = _selectedFilter == 'All' 
        ? _assessments 
        : _assessments.where((a) => (a['type'] ?? (a['title'].toString().toLowerCase().contains('project') ? 'Project' : 'Assignment')) == _selectedFilter).toList();

    if (_selectedCourseIdFilter != null) {
      filteredAssessments = filteredAssessments.where((a) => a['course_id'].toString() == _selectedCourseIdFilter).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F7FC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF05398F), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Assessments", 
          style: TextStyle(color: Color(0xFF05398F), fontSize: 22, fontWeight: FontWeight.bold)
        ),
      ),
      body: Column(
        children: [
          // Course Selection Header
          if (_classes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Select Course", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54, fontSize: 13)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        // "All Courses" chip
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ChoiceChip(
                            label: const Text("All"),
                            selected: _selectedCourseIdFilter == null,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCourseIdFilter = null;
                              });
                            },
                            selectedColor: const Color(0xFF09AEF5),
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(
                              color: _selectedCourseIdFilter == null ? Colors.white : Colors.black87,
                              fontWeight: _selectedCourseIdFilter == null ? FontWeight.bold : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        // Course specific chips
                        ..._classes.map((cls) {
                          final isSelected = _selectedCourseIdFilter == cls["id"];
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ChoiceChip(
                              avatar: CircleAvatar(
                                backgroundColor: (cls["color"] as Color).withOpacity(0.2),
                                child: Text(cls["initials"], style: TextStyle(color: cls["color"], fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              label: Text(cls["name"].toString().split(' (')[0]), // Show title without code for brevity
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCourseIdFilter = isSelected ? null : cls["id"];
                                });
                              },
                              selectedColor: cls["color"],
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Filter Tabs (Type)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () => setState(() => _selectedFilter = filter),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF09AEF5) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ],
                        border: Border.all(
                          color: isSelected ? Colors.transparent : Colors.black12,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        filter,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black54,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 10),
                        ElevatedButton(onPressed: _fetchData, child: const Text("Retry"))
                      ],
                    ),
                  )
                : filteredAssessments.isEmpty
                  ? const Center(child: Text("No assessments found", style: TextStyle(color: Colors.black54)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: filteredAssessments.length,
                      itemBuilder: (context, index) {
                        final item = filteredAssessments[index];
                        return _buildAssessmentCard(item);
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateAssessmentSheet,
        backgroundColor: const Color(0xFF09AEF5),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("Create", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildAssessmentCard(dynamic item) {
    String title = item['title'] ?? 'Untitled';
    String type = (title.toLowerCase().contains('project')) ? 'Project' : 
                  (title.toLowerCase().contains('presentation')) ? 'Presentation' : 'Assignment';
    
    Color typeColor = type == 'Project' ? Colors.purple : (type == 'Presentation' ? Colors.orange : Colors.blue);
    bool isGroup = item['is_group_assignment'] == true;
    
    String deadline = 'No due date';
    if (item['due_date'] != null) {
      DateTime dt = DateTime.parse(item['due_date']);
      deadline = DateFormat('MMM d, h:mm a').format(dt);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        type,
                        style: TextStyle(color: typeColor, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isGroup ? 'Group' : 'Individual',
                        style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: Colors.redAccent),
                  const SizedBox(width: 4),
                  Text(
                    deadline,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          if (item['description'] != null && item['description'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              item['description'],
              style: const TextStyle(fontSize: 14, color: Colors.black54),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.people_alt_rounded, size: 16, color: Colors.black45),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item['course_title'] ?? "Course Info Unavailable",
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(),
              
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => InstructorAssessmentDetailsScreen(assessment: item),
                    ),
                  ).then((_) => _fetchData());
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: const Color(0xFF05398F).withOpacity(0.08),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  "View Details", 
                  style: TextStyle(color: Color(0xFF05398F), fontSize: 13, fontWeight: FontWeight.bold)
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
