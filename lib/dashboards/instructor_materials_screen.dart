import 'package:flutter/material.dart';

class InstructorMaterialsScreen extends StatefulWidget {
  const InstructorMaterialsScreen({super.key});

  @override
  State<InstructorMaterialsScreen> createState() => _InstructorMaterialsScreenState();
}

class _InstructorMaterialsScreenState extends State<InstructorMaterialsScreen> {
  // Dummy data for materials
  final List<Map<String, dynamic>> _materials = [
    {"id": "m1", "name": "Week 1 Lecture Slides.pdf", "size": "2.4 MB", "date": "Oct 12", "icon": Icons.picture_as_pdf_rounded, "color": Colors.red},
    {"id": "m2", "name": "Project Guidelines.docx", "size": "1.1 MB", "date": "Oct 15", "icon": Icons.description_rounded, "color": Colors.blue},
    {"id": "m3", "name": "Intro Setup Video.mp4", "size": "15.0 MB", "date": "Oct 18", "icon": Icons.play_circle_fill_rounded, "color": Colors.purple},
    {"id": "m4", "name": "Data Dataset.zip", "size": "4.5 MB", "date": "Oct 20", "icon": Icons.folder_zip_rounded, "color": Colors.orange},
    {"id": "m5", "name": "Reference Book.pdf", "size": "8.8 MB", "date": "Oct 22", "icon": Icons.picture_as_pdf_rounded, "color": Colors.red},
  ];

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

  final Set<String> _selectedMaterials = {};

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
    });
  }

  void _showShareBottomSheet() {
    Set<String> selectedSections = {};
    Set<String> expandedCourses = {};

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
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Share Materials",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF05398F)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Select the classes/sections you want to share \${_selectedMaterials.length} material(s) with.",
                    style: const TextStyle(color: Colors.black54, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  
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
                                      } else {
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
                                      } else {
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
                  }).toList(),

                  const SizedBox(height: 30),
                  
                  // Share Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: selectedSections.isNotEmpty ? () {
                         Navigator.pop(context); // close bottom sheet
                         _clearSelection(); // clear selection after sharing
                         
                         ScaffoldMessenger.of(context).showSnackBar(
                           const SnackBar(
                             content: Text("Materials Successfully Shared!"),
                             backgroundColor: Colors.green,
                             behavior: SnackBarBehavior.floating,
                           )
                         );
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF09AEF5),
                        disabledBackgroundColor: Colors.black12,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: selectedSections.isNotEmpty ? 4 : 0,
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

  @override
  Widget build(BuildContext context) {
    bool isSelectionMode = _selectedMaterials.isNotEmpty;

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
          isSelectionMode ? "\${_selectedMaterials.length} Selected" : "My Materials", 
          style: const TextStyle(color: Color(0xFF05398F), fontSize: 22, fontWeight: FontWeight.bold)
        ),
        actions: [
          if (isSelectionMode)
            IconButton(
              icon: const Icon(Icons.share_rounded, color: Color(0xFF09AEF5)),
              onPressed: _showShareBottomSheet,
            )
          else
            IconButton(
              icon: const Icon(Icons.search_rounded, color: Color(0xFF05398F)),
              onPressed: () {},
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
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

            ..._materials.map((mat) => _buildMaterialTile(mat)).toList(),

            const SizedBox(height: 100), // padding for FAB
          ],
        ),
      ),
      floatingActionButton: !isSelectionMode 
        ? FloatingActionButton.extended(
            onPressed: () {
              // Simulate an upload action
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Upload Dialog..."),
                  behavior: SnackBarBehavior.floating,
                )
              );
            },
            backgroundColor: const Color(0xFF05398F),
            icon: const Icon(Icons.cloud_upload_rounded, color: Colors.white),
            label: const Text("Upload", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            elevation: 4,
          )
        : null,
    );
  }

  Widget _buildMaterialTile(Map<String, dynamic> material) {
    bool isSelected = _selectedMaterials.contains(material["id"]);

    return GestureDetector(
      onTap: () {
        if (_selectedMaterials.isNotEmpty) {
          _toggleSelection(material["id"]);
        } else {
          // Open material...
        }
      },
      onLongPress: () {
        _toggleSelection(material["id"]);
      },
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
                color: (material["color"] as Color).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(material["icon"], color: material["color"], size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    material["name"], 
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 15, 
                      color: isSelected ? const Color(0xFF05398F) : Colors.black87
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(material["size"], style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 8),
                      const Text("•", style: TextStyle(color: Colors.black38, fontSize: 13)),
                      const SizedBox(width: 8),
                      Text(material["date"], style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500)),
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
}
