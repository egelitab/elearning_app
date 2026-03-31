import 'package:flutter/material.dart';

class InstructorGradingSubmissionsScreen extends StatefulWidget {
  final Map<String, dynamic> gradingTask;

  const InstructorGradingSubmissionsScreen({super.key, required this.gradingTask});

  @override
  State<InstructorGradingSubmissionsScreen> createState() => _InstructorGradingSubmissionsScreenState();
}

class _InstructorGradingSubmissionsScreenState extends State<InstructorGradingSubmissionsScreen> {
  late List<Map<String, dynamic>> _submissions;
  String _filter = 'All'; // All, Needs Grading, Graded
  String _selectedSection = 'All Sections';
  final List<String> _sections = ['All Sections', '3rd Year Section A', '3rd Year Section B', '4th Year Section A'];

  String _selectedDepartment = 'All Departments';
  final List<String> _departments = ['All Departments', 'Computer Science', 'Software Engineering', 'Information Systems'];

  @override
  void initState() {
    super.initState();
    // Generate dummy submissions based on task stats
    bool isGroup = widget.gradingTask['format'] == 'Group';
    int submittedCount = widget.gradingTask['submitted'] ?? 0;
    int gradedCount = widget.gradingTask['graded'] ?? 0;
    
    _submissions = List.generate(submittedCount, (index) {
      String section = _sections[(index % (_sections.length - 1)) + 1];
      String department = _departments[(index % (_departments.length - 1)) + 1];

      bool isGraded = index < gradedCount;
      return {
        "id": "s$index",
        "name": isGroup ? "Group ${index + 1}" : "Student ${index + 1} Name",
        "initials": isGroup ? "G${index + 1}" : "S${index + 1}",
        "status": isGraded ? "Graded" : "Needs Grading",
        "score": isGraded ? (80 + index % 20).toString() : "",
        "maxScore": "100",
        "submittedAt": "Oct ${20 + index % 10}, 11:59 PM",
        "file": "${isGroup ? 'Group_${index+1}' : 'Student_${index+1}'}_submission.pdf",
        "feedback": isGraded ? "Good job, but watch out for..." : "",
        "section": section,
        "department": department,
      };
    });
  }

  void _showGradingSheet(Map<String, dynamic> submission, int index) {
    final TextEditingController scoreController = TextEditingController(text: submission['score']);
    final TextEditingController feedbackController = TextEditingController(text: submission['feedback']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        submission['status'] == 'Graded' ? "Edit Grade" : "Grade Submission",
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF05398F)),
                      ),
                      Text(
                        submission['name'],
                        style: const TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                  const SizedBox(height: 25),
                  
                  // Grade Input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: scoreController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            labelText: "Score",
                            labelStyle: const TextStyle(fontSize: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.star_rounded, color: Color(0xFFFFCA28)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      const Text(
                        "/ 100", 
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black54)
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Feedback Input
                  TextField(
                    controller: feedbackController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: "Feedback (Optional)",
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: () {
                        if (scoreController.text.isNotEmpty) {
                          setState(() {
                            if (_submissions[index]['status'] == "Needs Grading") {
                              // Update global task graded count if needed (this is a simplified logic)
                              // widget.gradingTask['graded'] += 1; // Cannot mutate final directly without state mgr
                            }
                            _submissions[index]['score'] = scoreController.text;
                            _submissions[index]['feedback'] = feedbackController.text;
                            _submissions[index]['status'] = "Graded";
                          });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Grade Saved successfully!"), backgroundColor: Colors.green)
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please enter a score."))
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF09AEF5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      child: const Text("Save Grade", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    Color typeColor = widget.gradingTask['color'] ?? Colors.blue;
    
    final filteredSubmissions = _submissions.where((sub) {
      bool statusMatches = _filter == 'All' || sub['status'] == _filter;
      bool sectionMatches = _selectedSection == 'All Sections' || sub['section'] == _selectedSection;
      bool departmentMatches = _selectedDepartment == 'All Departments' || sub['department'] == _selectedDepartment;
      return statusMatches && sectionMatches && departmentMatches;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F7FC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF05398F), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.gradingTask['title'], 
              style: const TextStyle(color: Color(0xFF05398F), fontSize: 18, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.gradingTask['course'],
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            )
          ],
        ),
      ),
      body: Column(
        children: [
          // Dropdowns
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedDepartment,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF05398F)),
                        items: _departments.map((String dept) {
                          return DropdownMenuItem<String>(
                            value: dept,
                            child: Text(
                              dept,
                              style: TextStyle(
                                color: _selectedDepartment == dept ? const Color(0xFF05398F) : Colors.black87,
                                fontWeight: _selectedDepartment == dept ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedDepartment = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedSection,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF05398F)),
                        items: _sections.map((String section) {
                          return DropdownMenuItem<String>(
                            value: section,
                            child: Text(
                              section,
                              style: TextStyle(
                                color: _selectedSection == section ? const Color(0xFF05398F) : Colors.black87,
                                fontWeight: _selectedSection == section ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedSection = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            child: Row(
              children: ['All', 'Needs Grading', 'Graded'].map((filter) {
                final isSelected = _filter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _filter = filter;
                      });
                    },
                    selectedColor: typeColor.withOpacity(0.15),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? typeColor : Colors.black12,
                    ),
                    labelStyle: TextStyle(
                      color: isSelected ? typeColor : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          Expanded(
            child: filteredSubmissions.isEmpty
              ? const Center(child: Text("No submissions found", style: TextStyle(color: Colors.black54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filteredSubmissions.length,
                  itemBuilder: (context, index) {
                    final item = filteredSubmissions[index];
                    int originalIndex = _submissions.indexOf(item);
                    return _buildSubmissionCard(item, originalIndex);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionCard(Map<String, dynamic> item, int index) {
    bool isGraded = item['status'] == 'Graded';

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
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF09AEF5).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        item['initials'], 
                        style: const TextStyle(color: Color(0xFF09AEF5), fontWeight: FontWeight.bold, fontSize: 14)
                      )
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                      const SizedBox(height: 2),
                      Text("${item['department']} - ${item['section']}", style: const TextStyle(fontSize: 12, color: Colors.black54)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 12, color: Colors.black45),
                          const SizedBox(width: 4),
                          Text(item['submittedAt'], style: const TextStyle(color: Colors.black45, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              if (isGraded)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Colors.green, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        "${item['score']} / ${item['maxScore']}",
                        style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "Needs Grading",
                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                )
            ],
          ),
          const SizedBox(height: 16),
          // Submitted File File Preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              children: [
                const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['file'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87), overflow: TextOverflow.ellipsis),
                      const Text("1.2 MB", style: TextStyle(color: Colors.black54, fontSize: 11)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.download_rounded, color: Color(0xFF05398F)),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Action Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showGradingSheet(item, index),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: isGraded ? Colors.black26 : const Color(0xFF09AEF5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                isGraded ? "Edit Grade" : "Grade Submission", 
                style: TextStyle(
                  color: isGraded ? Colors.black54 : const Color(0xFF09AEF5), 
                  fontWeight: FontWeight.bold
                )
              ),
            ),
          ),
        ],
      ),
    );
  }
}
