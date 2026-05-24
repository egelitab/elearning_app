import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/downloadable_behavior.dart';

class InstructorGradingSubmissionsScreen extends StatefulWidget {
  final dynamic gradingTask;

  const InstructorGradingSubmissionsScreen({super.key, required this.gradingTask});

  @override
  State<InstructorGradingSubmissionsScreen> createState() => _InstructorGradingSubmissionsScreenState();
}

class _InstructorGradingSubmissionsScreenState extends State<InstructorGradingSubmissionsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _submissions = [];
  bool _isLoading = true;
  String? _error;
  
  String _filter = 'All'; // All, Needs Grading, Graded
  String _selectedSection = 'All Sections';
  List<String> _sections = ['All Sections'];

  String _selectedDepartment = 'All Departments';
  List<String> _departments = ['All Departments'];

  @override
  void initState() {
    super.initState();
    _fetchSubmissions();
  }

  Future<void> _fetchSubmissions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _apiService.getSubmissions(widget.gradingTask['id'].toString());
      if (mounted) {
        setState(() {
          _submissions = data;
          
          // Extract unique departments and sections for filters
          for (var sub in data) {
            String? dept = sub['department_name'];
            String? sect = sub['section'];
            if (dept != null && !_departments.contains(dept)) _departments.add(dept);
            if (sect != null && !_sections.contains(sect)) _sections.add(sect);
          }
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
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
                      Expanded(
                        child: Text(
                          submission['status'] == 'Graded' ? "Edit Grade" : "Grade Submission",
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF05398F)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          submission['name'],
                          style: const TextStyle(fontSize: 16, color: Colors.black54, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
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
                      onPressed: () async {
                        if (scoreController.text.isNotEmpty) {
                          try {
                            double gradeVal = double.parse(scoreController.text);
                            await _apiService.gradeSubmission(
                              submission['id'].toString(), 
                              gradeVal, 
                              feedbackController.text
                            );

                            if (mounted) {
                              Navigator.pop(context);
                              _fetchSubmissions(); // Refresh the list
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Grade Saved successfully!"), backgroundColor: Colors.green)
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error saving grade: $e"), backgroundColor: Colors.red)
                            );
                          }
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
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(child: Text(_error!, style: const TextStyle(color: Colors.red))),
      );
    }

    final filteredSubmissions = _submissions.where((sub) {
      final isGraded = sub['grade'] != null;
      bool statusMatches = _filter == 'All' || 
          (_filter == 'Graded' && isGraded) || 
          (_filter == 'Needs Grading' && !isGraded);
      
      bool sectionMatches = _selectedSection == 'All Sections' || sub['section'] == _selectedSection;
      bool departmentMatches = _selectedDepartment == 'All Departments' || sub['department_name'] == _selectedDepartment;
      
      return statusMatches && sectionMatches && departmentMatches;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F7FC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF05398F), size: 20),
          onPressed: () => Navigator.pop(context, true), // Return true to trigger refresh
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.gradingTask['title'] ?? 'Grading', 
              style: const TextStyle(color: Color(0xFF05398F), fontSize: 18, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              "${widget.gradingTask['course_title'] ?? ''} (${widget.gradingTask['course_code'] ?? ''})",
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
                    return _buildSubmissionCard(item, index);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionCard(dynamic item, int index) {
    bool isGraded = item['grade'] != null;
    bool isGroup = item['group_id'] != null;
    
    String displayName = isGroup 
        ? (item['group_name'] ?? 'Unknown Group')
        : "${item['first_name'] ?? ''} ${item['last_name'] ?? ''}";
    
    String initials = isGroup 
        ? (item['group_name']?.toString().split('-').last.trim() ?? 'G')
        : (item['first_name']?[0] ?? 'S');

    String submittedAt = 'N/A';
    if (item['submission_date'] != null) {
      try {
        DateTime dt = DateTime.parse(item['submission_date']).toLocal();
        submittedAt = "${_getMonth(dt.month)} ${dt.day}, ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
      } catch (_) {}
    }

    String fileName = item['file_path']?.toString().split('/').last ?? 'submission.file';
    String displayFileName = isGroup ? "Group Submission" : "$displayName's Submission";

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
              Expanded(
                child: Row(
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
                          initials, 
                          style: const TextStyle(color: Color(0xFF09AEF5), fontWeight: FontWeight.bold, fontSize: 14)
                        )
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87), overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text("${item['department_name'] ?? ''} - ${item['section'] ?? ''}", style: const TextStyle(fontSize: 12, color: Colors.black54), overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 12, color: Colors.black45),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text("Submitted: $submittedAt", style: const TextStyle(color: Colors.black45, fontSize: 12), overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
                        "${item['grade']} / 100",
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
          DownloadableBehavior(
            filePath: item['file_path']?.toString() ?? '',
            fileName: fileName,
            builder: (context, isDownloaded, isDownloading, isPaused, progress, onTap) {
              IconData mainIcon = fileName.toLowerCase().endsWith('.pdf') ? Icons.picture_as_pdf_rounded : Icons.description_rounded;
              Color mainColor = fileName.toLowerCase().endsWith('.pdf') ? Colors.redAccent : Colors.blueAccent;
              
              if (!isDownloaded && !isDownloading) {
                mainIcon = Icons.download_rounded;
                mainColor = Colors.grey;
              } else if (isDownloading) {
                mainIcon = isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded;
                mainColor = Colors.orange;
              }

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7FC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
                child: InkWell(
                  onTap: onTap,
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          if (isDownloading)
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                              ),
                            ),
                          Icon(mainIcon, color: mainColor, size: 24),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(displayFileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87), overflow: TextOverflow.ellipsis),
                            Text(
                              isDownloading 
                                ? (isPaused ? "Paused" : "Downloading... ${(progress != null ? (progress * 100).toStringAsFixed(0) : "0")}%") 
                                : (!isDownloaded ? "Tap to download" : "Click to view submission"), 
                            style: const TextStyle(color: Colors.black54, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
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

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
