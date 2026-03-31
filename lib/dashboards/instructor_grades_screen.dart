import 'package:flutter/material.dart';
import 'instructor_grading_submissions_screen.dart';

class InstructorGradesScreen extends StatefulWidget {
  const InstructorGradesScreen({super.key});

  @override
  State<InstructorGradesScreen> createState() => _InstructorGradesScreenState();
}

class _InstructorGradesScreenState extends State<InstructorGradesScreen> {
  String _selectedTab = 'Pending';
  final List<String> _tabs = ['Pending', 'Graded'];

  // Dummy data for grading tasks
  final List<Map<String, dynamic>> _gradingTasks = [
    {
      "id": "g1",
      "course": "Computer Security (CoSc4051)",
      "title": "Database Design Project",
      "type": "Project",
      "format": "Group",
      "submitted": 8,
      "total": 9,
      "graded": 2,
      "dueDate": "Oct 30",
      "status": "Pending",
      "color": Colors.purple
    },
    {
      "id": "g2",
      "course": "Compiler Design (CoSc4022)",
      "title": "Homework 1: SQL Queries",
      "type": "Assignment",
      "format": "Individual",
      "submitted": 48,
      "total": 50,
      "graded": 20,
      "dueDate": "Oct 25",
      "status": "Pending",
      "color": Colors.blue
    },
    {
      "id": "g3",
      "course": "Complexity Theory (CoSc4021)",
      "title": "Midterm Presentation",
      "type": "Presentation",
      "format": "Individual",
      "submitted": 38,
      "total": 38,
      "graded": 38,
      "dueDate": "Oct 15",
      "status": "Graded",
      "color": Colors.orange
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _gradingTasks.where((task) {
      if (_selectedTab == 'Pending') return task['status'] == 'Pending';
      return task['status'] == 'Graded';
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
        title: const Text(
          "Grades", 
          style: TextStyle(color: Color(0xFF05398F), fontSize: 22, fontWeight: FontWeight.bold)
        ),
      ),
      body: Column(
        children: [
          // Custom Tab Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              padding: const EdgeInsets.all(4),
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
              child: Row(
                children: _tabs.map((tab) {
                  final isSelected = _selectedTab == tab;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedTab = tab;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF09AEF5).withOpacity(0.1) : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            tab,
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF05398F) : Colors.black54,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          Expanded(
            child: filteredTasks.isEmpty
              ? Center(child: Text("No $_selectedTab grading tasks", style: const TextStyle(color: Colors.black54)))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final item = filteredTasks[index];
                    return _buildGradingCard(item);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradingCard(Map<String, dynamic> item) {
    Color typeColor = item['color'];
    double progress = item['total'] > 0 ? (item['graded'] / item['submitted']) : 0.0;
    if (item['submitted'] == 0) progress = 0.0;
    if (progress.isNaN || progress.isInfinite) progress = 0.0;
    progress = progress.clamp(0.0, 1.0);

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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.1),
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
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item['format'],
                      style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              Text(
                "Due ${item['dueDate']}",
                style: const TextStyle(color: Colors.black45, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item['title'],
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            item['course'],
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 15),
          
          // Grading Stats and Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStat("Submitted", "${item['submitted']}/${item['total']}", Icons.file_upload_outlined, Colors.blue),
              _buildStat("Graded", "${item['graded']}/${item['submitted']}", Icons.check_circle_outline, Colors.green),
              _buildStat("Pending", "${item['submitted'] - item['graded']}", Icons.pending_actions_outlined, Colors.orange),
            ],
          ),
          
          const SizedBox(height: 15),
          if (item['status'] == 'Pending') ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 15),
          ],
          
          // Action Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => InstructorGradingSubmissionsScreen(gradingTask: item)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: item['status'] == 'Pending' ? const Color(0xFF09AEF5) : const Color(0xFFF4F7FC),
                elevation: item['status'] == 'Pending' ? 2 : 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                item['status'] == 'Pending' ? "Grade Submissions" : "Review Grades", 
                style: TextStyle(
                  color: item['status'] == 'Pending' ? Colors.white : const Color(0xFF05398F), 
                  fontWeight: FontWeight.bold,
                  fontSize: 15
                )
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.black54)),
      ],
    );
  }
}
