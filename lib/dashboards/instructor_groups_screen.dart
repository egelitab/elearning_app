import 'package:flutter/material.dart';

class InstructorGroupsScreen extends StatefulWidget {
  const InstructorGroupsScreen({super.key});

  @override
  State<InstructorGroupsScreen> createState() => _InstructorGroupsScreenState();
}

class _InstructorGroupsScreenState extends State<InstructorGroupsScreen> {
  // Dummy data
  final List<Map<String, dynamic>> _sections = [
    {"id": "s1", "course": "Computer Security (CoSc4051)", "name": "3rd Year Section A", "students": 45},
    {"id": "s2", "course": "Computer Security (CoSc4051)", "name": "3rd Year Section B", "students": 42},
    {"id": "s3", "course": "Compiler Design (CoSc4022)", "name": "3rd Year Section A", "students": 50},
    {"id": "s4", "course": "Complexity Theory (CoSc4021)", "name": "4th Year Section A", "students": 38},
  ];

  final List<Map<String, dynamic>> _existingGroups = [
    {"id": "g1", "title": "Project Phase 1", "course": "Computer Security", "section": "3rd Year Section A", "groupsCount": 9, "date": "Oct 10"},
    {"id": "g2", "title": "Assignment 2 DB Design", "course": "Compiler Design", "section": "3rd Year Section A", "groupsCount": 10, "date": "Oct 15"},
  ];

  void _showCreateGroupBottomSheet() {
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
                          items: _sections.map((sec) {
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
                              "${_sections.firstWhere((s) => s["id"] == selectedSectionId)["students"]}",
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
                              final sec = _sections.firstWhere((s) => s["id"] == selectedSectionId);
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
                                            _finalizeGroupCreation(groupName!, sec, totalStudents, groupSize, groupingMethod);
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
                                _finalizeGroupCreation(groupName!, sec, totalStudents, groupSize, groupingMethod);
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

  void _finalizeGroupCreation(String title, Map<String, dynamic> section, int totalStudents, int size, String method) {
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
          "Manage Groups", 
          style: TextStyle(color: Color(0xFF05398F), fontSize: 22, fontWeight: FontWeight.bold)
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded, color: Color(0xFF05398F)), onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Recent Groupings",
              style: TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 15),

            ..._existingGroups.map((grp) => _buildGroupTile(grp)).toList(),
            
            if (_existingGroups.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 40.0),
                  child: Text("No groups formed yet.", style: TextStyle(color: Colors.black38)),
                )
              ),

            const SizedBox(height: 100), // padding for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateGroupBottomSheet,
        backgroundColor: const Color(0xFF05398F),
        icon: const Icon(Icons.groups_rounded, color: Colors.white),
        label: const Text("Form Groups", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        elevation: 4,
      ),
    );
  }

  Widget _buildGroupTile(Map<String, dynamic> group) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFAB47BC).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.groups_rounded, color: Color(0xFFAB47BC), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        group["title"], 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      )
                    ),
                    Text(group["date"], style: const TextStyle(color: Colors.black45, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  "${group['course']} • ${group['section']}", 
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7FC),
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Text(
                    "${group['groupsCount']} Groups Generated",
                    style: const TextStyle(color: Color(0xFF05398F), fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
