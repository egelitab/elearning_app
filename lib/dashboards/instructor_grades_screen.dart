import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'instructor_grading_submissions_screen.dart';

class InstructorGradesScreen extends StatefulWidget {
  const InstructorGradesScreen({super.key});

  @override
  State<InstructorGradesScreen> createState() => _InstructorGradesScreenState();
}

class _InstructorGradesScreenState extends State<InstructorGradesScreen> {
  final ApiService _apiService = ApiService();
  String _selectedTab = 'Pending';
  final List<String> _tabs = ['Pending', 'Graded'];
  
  List<dynamic> _gradingTasks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchGradingOverview();
  }

  Future<void> _fetchGradingOverview() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _apiService.getGradingOverview();
      if (mounted) {
        setState(() {
          _gradingTasks = data;
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

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _gradingTasks.where((task) {
      final submitted = task['submitted_count'] ?? 0;
      final graded = task['graded_count'] ?? 0;
      bool isFinished = (submitted > 0 && submitted == graded);
      
      if (_selectedTab == 'Pending') return !isFinished;
      return isFinished;
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
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                : filteredTasks.isEmpty
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

  Widget _buildGradingCard(dynamic item) {
    String title = item['title'] ?? 'No Title';
    String course = "${item['course_title'] ?? ''} (${item['course_code'] ?? ''})";
    int submitted = item['submitted_count'] ?? 0;
    int graded = item['graded_count'] ?? 0;
    int total = item['total_count'] ?? 0;
    bool isGroup = item['is_group_assignment'] ?? false;
    
    String dueDate = 'N/A';
    if (item['due_date'] != null) {
      try {
        DateTime dt = DateTime.parse(item['due_date']).toLocal();
        dueDate = "${_getMonth(dt.month)} ${dt.day}";
      } catch (_) {}
    }

    double progress = submitted > 0 ? (graded / submitted) : 0.0;
    bool isFinished = _selectedTab == 'Graded';

    Color typeColor = isGroup ? Colors.purple : Colors.blue;

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
                      isGroup ? "Group" : "Individual",
                      style: TextStyle(color: typeColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              Text(
                "Due $dueDate",
                style: const TextStyle(color: Colors.black45, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            course,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 15),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStat("Submitted", "$submitted/$total", Icons.file_upload_outlined, Colors.blue),
              _buildStat("Graded", "$graded/$submitted", Icons.check_circle_outline, Colors.green),
              _buildStat("Pending", "${submitted - graded}", Icons.pending_actions_outlined, Colors.orange),
            ],
          ),
          
          const SizedBox(height: 15),
          if (!isFinished) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 15),
          ],
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => InstructorGradingSubmissionsScreen(gradingTask: item)),
                );
                if (result == true) {
                   _fetchGradingOverview();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: !isFinished ? const Color(0xFF09AEF5) : const Color(0xFFF4F7FC),
                elevation: !isFinished ? 2 : 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                !isFinished ? "Grade Submissions" : "Review Grades", 
                style: TextStyle(
                  color: !isFinished ? Colors.white : const Color(0xFF05398F), 
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

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
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
