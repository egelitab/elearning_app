import 'package:flutter/material.dart';

class InstructorAssessmentsScreen extends StatefulWidget {
  const InstructorAssessmentsScreen({super.key});

  @override
  State<InstructorAssessmentsScreen> createState() => _InstructorAssessmentsScreenState();
}

class _InstructorAssessmentsScreenState extends State<InstructorAssessmentsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Assignment', 'Project', 'Presentation'];

  // Dummy data for courses/classes
  final List<Map<String, dynamic>> _classes = [
    {
      "id": "c1", "name": "Computer Security (CoSc4051)", "initials": "CS", "color": Colors.blue,
      "sections": [
        {"id": "c1_s1", "name": "3rd Year Section A"},
        {"id": "c1_s2", "name": "3rd Year Section B"}
      ]
    },
    {
      "id": "c2", "name": "Compiler Design (CoSc4022)", "initials": "CD", "color": Colors.purple,
      "sections": [
        {"id": "c2_s1", "name": "3rd Year Section A"}
      ]
    },
    {
      "id": "c3", "name": "Complexity Theory (CoSc4021)", "initials": "CT", "color": Colors.orange,
      "sections": [
        {"id": "c3_s1", "name": "4th Year Section A"},
        {"id": "c3_s2", "name": "4th Year Section B"}
      ]
    },
    {
      "id": "c4", "name": "Research Methods (CoSc4111)", "initials": "RM", "color": Colors.green,
      "sections": [
        {"id": "c4_s1", "name": "4th Year Section C"}
      ]
    },
  ];

  final List<Map<String, dynamic>> _sectionsList = [
    {"id": "s1", "course": "Computer Security (CoSc4051)", "name": "3rd Year Section A", "students": 45},
    {"id": "s2", "course": "Computer Security (CoSc4051)", "name": "3rd Year Section B", "students": 42},
    {"id": "s3", "course": "Compiler Design (CoSc4022)", "name": "3rd Year Section A", "students": 50},
    {"id": "s4", "course": "Complexity Theory (CoSc4021)", "name": "4th Year Section A", "students": 38},
  ];

  final List<Map<String, dynamic>> _existingGroups = [
    {"id": "g1", "title": "Project Phase 1", "course": "Computer Security", "section": "3rd Year Section A", "groupsCount": 9, "date": "Oct 10"},
    {"id": "g2", "title": "Assignment 2 DB Design", "course": "Compiler Design", "section": "3rd Year Section A", "groupsCount": 10, "date": "Oct 15"},
  ];

  // Dummy data
  final List<Map<String, dynamic>> _assessments = [
    {
      "id": "a1",
      "title": "Database Design Project",
      "type": "Project",
      "format": "Group",
      "deadline": "Oct 30, 11:59 PM",
      "description": "Design a relational database schema for a university management system.",
      "hasFile": true,
      "color": Colors.purple
    },
    {
      "id": "a2",
      "title": "Midterm Presentation",
      "type": "Presentation",
      "format": "Individual",
      "deadline": "Nov 5, 2:00 PM",
      "description": "Present your project proposal to the class.",
      "hasFile": false,
      "color": Colors.orange
    },
    {
      "id": "a3",
      "title": "Homework 1: SQL Queries",
      "type": "Assignment",
      "format": "Individual",
      "deadline": "Oct 25, 11:59 PM",
      "description": "Write SQL queries to solve the problems listed in the attached document.",
      "hasFile": true,
      "color": Colors.blue
    },
  ];

  void _showCreateAssessmentSheet() {
    String selectedType = 'Assignment';
    String selectedFormat = 'Individual';
    String? selectedGroup;
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descController = TextEditingController();
    DateTime? selectedDate;
    Set<String> selectedSections = {};
    Set<String> expandedCourses = {};
    String? selectedCourseId;

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
                        decoration: InputDecoration(
                          labelText: "Assessment Title",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.title),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Type Selection
                      const Text("Assessment Type", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        children: ['Assignment', 'Project', 'Presentation'].map((type) {
                          return ChoiceChip(
                            label: Text(type),
                            selected: selectedType == type,
                            onSelected: (selected) {
                              setSheetState(() => selectedType = type);
                            },
                            selectedColor: const Color(0xFF09AEF5).withValues(alpha: 0.2),
                            labelStyle: TextStyle(
                              color: selectedType == type ? const Color(0xFF05398F) : Colors.black87,
                              fontWeight: selectedType == type ? FontWeight.bold : FontWeight.normal,
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
                          return ChoiceChip(
                            label: Text(format),
                            selected: selectedFormat == format,
                            onSelected: (selected) {
                              setSheetState(() {
                                selectedFormat = format;
                                if (format == 'Individual') {
                                  selectedGroup = null;
                                }
                              });
                            },
                            selectedColor: const Color(0xFF09AEF5).withValues(alpha: 0.2),
                            labelStyle: TextStyle(
                              color: selectedFormat == format ? const Color(0xFF05398F) : Colors.black87,
                              fontWeight: selectedFormat == format ? FontWeight.bold : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      if (selectedFormat == 'Group') ...[
                        const Text("Select Group", style: TextStyle(fontWeight: FontWeight.bold)),
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
                                    hint: const Text("Choose from created groups"),
                                    value: selectedGroup,
                                    items: _existingGroups.map((g) {
                                      return DropdownMenuItem<String>(
                                        value: g["id"],
                                        child: Text(g["title"] ?? "Unnamed Group"),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setSheetState(() => selectedGroup = val);
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                _showCreateGroupBottomSheet(setSheetState);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF09AEF5).withValues(alpha: 0.1),
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
                              onPressed: () {
                                // Simulate file upload
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("File upload simluated"))
                                );
                              },
                              icon: const Icon(Icons.attach_file, color: Color(0xFF05398F)),
                              label: const Text("Attach File", style: TextStyle(color: Color(0xFF05398F))),
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
                      const SizedBox(height: 20),

                      const Text("Assign To", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      // List of classes and their expandable sections
                      ..._classes.map((cls) {
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
                                  color: allSectionsSelected ? const Color(0xFF09AEF5).withValues(alpha: 0.1) : Colors.white,
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
                                        color: (cls["color"] as Color).withValues(alpha: 0.15),
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
                                            }
                                            selectedSections.add(sec["id"]);
                                          }
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                        margin: const EdgeInsets.only(bottom: 6),
                                        decoration: BoxDecoration(
                                          color: isSecSelected ? const Color(0xFF09AEF5).withValues(alpha: 0.05) : Colors.transparent,
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

                      const SizedBox(height: 30),

                      // Create Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                            if (titleController.text.isEmpty || selectedDate == null || selectedSections.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Title, Deadline and at least one Section are required"))
                              );
                              return;
                            }
                            if (selectedFormat == 'Group' && selectedGroup == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Please select a group for Group format"))
                              );
                              return;
                            }
                            
                            setState(() {
                              const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                              _assessments.add({
                                "id": "a${_assessments.length + 1}",
                                "title": titleController.text,
                                "type": selectedType,
                                "format": selectedFormat,
                                "deadline": "${months[selectedDate!.month - 1]} ${selectedDate!.day}, ${selectedDate!.hour > 12 ? selectedDate!.hour - 12 : selectedDate!.hour == 0 ? 12 : selectedDate!.hour}:${selectedDate!.minute.toString().padLeft(2, '0')} ${selectedDate!.hour >= 12 ? 'PM' : 'AM'}",
                                "description": descController.text,
                                "hasFile": false,
                                "sections": "\${selectedSections.length} Sections Assigned",
                                "color": selectedType == 'Project' ? Colors.purple : (selectedType == 'Presentation' ? Colors.orange : Colors.blue),
                              });
                            });
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Assessment Created Successfully!"), backgroundColor: Colors.green)
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF09AEF5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 4,
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



  void _showCreateGroupBottomSheet(StateSetter setAssessmentSheetState) {
    String? selectedSectionId;
    String? groupName;
    int groupSize = 5;
    String groupingMethod = 'Random';
    
    final List<String> methods = ['Random', 'Alphabetic', 'GPA Top Distributed'];
    final TextEditingController nameController = TextEditingController();
    final TextEditingController sizeController = TextEditingController(text: '5');

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
                          items: _sectionsList.map((sec) {
                            return DropdownMenuItem<String>(
                              value: sec["id"],
                              child: Text("${sec['course'].toString().split(' (')[0]} - ${sec['name']}"),
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
                              "${_sectionsList.firstWhere((s) => s["id"] == selectedSectionId)["students"]}",
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
                              final sec = _sectionsList.firstWhere((s) => s["id"] == selectedSectionId);
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
                                            _finalizeGroupCreation(groupName!, sec, totalStudents, groupSize, groupingMethod, setAssessmentSheetState);
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
                                _finalizeGroupCreation(groupName!, sec, totalStudents, groupSize, groupingMethod, setAssessmentSheetState);
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

  void _finalizeGroupCreation(String title, Map<String, dynamic> section, int totalStudents, int size, String method, StateSetter setAssessmentSheetState) {
    int groupCount = (totalStudents / size).ceil();
    setState(() {
      _existingGroups.insert(0, {
        "id": "g${DateTime.now().millisecondsSinceEpoch}",
        "title": title,
        "course": section["course"].toString().split(" (")[0], // Keep purely course name
        "section": section["name"],
        "groupsCount": groupCount,
        "date": "Today",
      });
    });
    
    // Trigger rebuilt of the assessment sheet to show the new list of groups
    setAssessmentSheetState(() {});
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Successfully formed $groupCount groups using '$method' method!"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredAssessments = _selectedFilter == 'All' 
        ? _assessments 
        : _assessments.where((a) => a['type'] == _selectedFilter).toList();

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
          // Filter Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = filter;
                      });
                    },
                    selectedColor: const Color(0xFF05398F),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? Colors.transparent : Colors.black12,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          Expanded(
            child: filteredAssessments.isEmpty
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
        backgroundColor: const Color(0xFF05398F),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("Create", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildAssessmentCard(Map<String, dynamic> item) {
    Color typeColor = item['color'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item['type'],
                      style: TextStyle(color: typeColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item['format'] ?? 'Individual',
                      style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: Colors.redAccent),
                  const SizedBox(width: 4),
                  Text(
                    item['deadline'],
                    style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item['title'],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          if ((item['description'] as String).isNotEmpty) ...[
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
                  item['sections'] ?? "All Sections",
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (item['hasFile'])
                Row(
                  children: [
                    Icon(Icons.attach_file_rounded, size: 16, color: Colors.black45),
                    const SizedBox(width: 4),
                    const Text("1 Attachment", style: TextStyle(color: Colors.black45, fontSize: 13)),
                  ],
                )
              else
                const SizedBox(),
              
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: const Color(0xFFF4F7FC),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("View Details", style: TextStyle(color: Color(0xFF05398F), fontSize: 13, fontWeight: FontWeight.bold)),
              )
            ],
          )
        ],
      ),
    );
  }
}
