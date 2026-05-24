import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import 'chat_detail_screen.dart';
import '../utils/date_helper.dart';

class StudentAssignmentsScreen extends StatefulWidget {
  const StudentAssignmentsScreen({super.key});

  @override
  State<StudentAssignmentsScreen> createState() => _StudentAssignmentsScreenState();
}

class _StudentAssignmentsScreenState extends State<StudentAssignmentsScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  late TabController _tabController;
  List<dynamic> _assignments = [];
  List<dynamic> _goals = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    DateHelper.init().then((_) {
      if (mounted) {
        _fetchAssignments();
        DateHelper.calendarFormat.addListener(_handlePreferenceChange);
      }
    });
  }

  void _handlePreferenceChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    DateHelper.calendarFormat.removeListener(_handlePreferenceChange);
    super.dispose();
  }

  Future<void> _fetchAssignments() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await _apiService.getStudentAssignments();
      final goals = await _apiService.getMyGoals();
      if (mounted) {
        setState(() {
          _assignments = tasks;
          _goals = goals;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final pending = _assignments.where((task) {
      final isSub = task['is_submitted'];
      return isSub == false || isSub == null || isSub == 0 || isSub == 'false';
    }).toList();
    
    final finished = _assignments.where((task) {
      final isSub = task['is_submitted'];
      return isSub == true || isSub == 1 || isSub == 'true';
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF05398F), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("My Assignments", style: TextStyle(color: Color(0xFF05398F), fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF09AEF5),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF09AEF5),
          indicatorWeight: 3,
          tabs: [
            Tab(text: "Tasks (${pending.length})"),
            Tab(text: "Finished (${finished.length})"),
            Tab(text: "Goals (${_goals.length})"),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildList(pending, isPending: true),
              _buildList(finished, isPending: false),
              _buildGoalList(_goals),
            ],
          ),
    );
  }

  Widget _buildList(List<dynamic> list, {required bool isPending}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isPending ? Icons.assignment_turned_in_rounded : Icons.pending_actions_rounded, size: 60, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(isPending ? "No pending assignments!" : "No finished assignments yet.", 
              style: const TextStyle(color: Colors.grey, fontSize: 16)
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      itemBuilder: (context, index) => _buildAssignmentItem(list[index]),
    );
  }

  Widget _buildGoalList(List<dynamic> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_outline_rounded, size: 60, color: Colors.grey.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text("No active goals.", style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      itemBuilder: (context, index) => _buildGoalItem(list[index]),
    );
  }

  Widget _buildProgressBarWithMilestones(double progress, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.centerLeft,
          clipBehavior: Clip.none,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: color.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 12,
              ),
            ),
            _buildMilestoneMarker(0.5, progress >= 0.5, color),
            _buildMilestoneMarker(0.75, progress >= 0.75, color),
            _buildMilestoneMarker(1.0, progress >= 1.0, color),
          ],
        ),
      ],
    );
  }

  Widget _buildMilestoneMarker(double milestone, bool completed, Color color) {
    return Positioned(
      left: 0,
      right: 0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          double position = (constraints.maxWidth * milestone) - 10;
          return Container(
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.only(left: position > 0 ? position : 0),
            child: Icon(
              Icons.star_rounded, 
              size: 20, 
              color: completed ? color : Colors.grey.withOpacity(0.4),
              shadows: completed ? [Shadow(color: color.withOpacity(0.4), blurRadius: 4)] : null,
            ),
          );
        }
      ),
    );
  }

  Widget _buildGoalItem(Map<String, dynamic> goal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(goal['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 4),
            Text(goal['course_title'] ?? 'Course', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
            if (goal['description'] != null && goal['description'].isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(goal['description'], style: const TextStyle(color: Colors.black87, fontSize: 13)),
            ],
            const SizedBox(height: 15),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                _buildBadge(Icons.star_rounded, "GOAL: ${goal['recurrence']?.toUpperCase() ?? 'WEEKLY'}", Colors.orange),
                if (goal['target_hours'] != null)
                  _buildBadge(Icons.timer_rounded, "${goal['progress_hours'] ?? '0'} / ${goal['target_hours']} HRS", Colors.blue),
                if (goal['target_score'] != null)
                  _buildBadge(Icons.score_rounded, "${goal['target_score']}% SCORE", Colors.green),
              ],
            ),
            if (goal['target_hours'] != null) ...[
              const SizedBox(height: 16),
              _buildProgressBarWithMilestones(
                (double.tryParse(goal['progress_hours']?.toString() ?? '0') ?? 0) / 
                (double.tryParse(goal['target_hours']?.toString() ?? '1') ?? 1),
                Colors.orange,
              ),
            ],
          ]
        )
      )
    );
  }

  Widget _buildAssignmentItem(Map<String, dynamic> task) {
    final bool isGroup = task['is_group_assignment'] == true;
    final bool isSubmitted = task['is_submitted'] == true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showTaskOptions(task),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(task['title'], 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)
                    ),
                  ),
                  if (isSubmitted)
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24)
                ],
              ),
              const SizedBox(height: 4),
              Text(task['course_title'] ?? 'General', 
                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)
              ),
              const SizedBox(height: 15),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _buildBadge(
                    isGroup ? Icons.groups_rounded : Icons.person_rounded, 
                    isGroup ? "GROUP" : "INDIVIDUAL", 
                    isGroup ? Colors.cyan : Colors.blue
                  ),
                  if (!isSubmitted)
                    _buildBadge(Icons.access_time_rounded, "Due ${_formatDate(task['due_date'])}", Colors.orange),
                  if (isSubmitted && task['grade'] != null)
                    _buildBadge(Icons.star_rounded, "Grade: ${task['grade']}", Colors.amber.shade700),
                ],
              ),
              if (isSubmitted && task['feedback'] != null) ...[
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.feedback_rounded, color: Colors.black38, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text("Feedback: ${task['feedback']}", style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black54))),
                    ],
                  ),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    return DateHelper.formatDateShort(dateStr);
  }

  void _showTaskOptions(Map<String, dynamic> task) {
    final bool isGroup = task['is_group_assignment'] == true;
    final bool isSubmitted = task['is_submitted'] == true;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(task['title'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF05398F))),
              const SizedBox(height: 20),
              ListTile(
                leading: Icon(isSubmitted ? Icons.update_rounded : Icons.upload_file_rounded, color: Colors.blue),
                title: Text(isSubmitted ? "Resubmit File" : "Upload Submission", style: const TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _handleFileUpload(task);
                },
              ),
              if (isGroup)
                ListTile(
                  leading: const Icon(Icons.chat_bubble_rounded, color: Colors.cyan),
                  title: const Text("Open Group Conversation", style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    if (task['group_id'] != null) {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ChatDetailScreen(groupId: task['group_id'].toString(), name: task['group_title'] ?? "Group Chat", isGroup: true)));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Group information not found.")));
                    }
                  },
                ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleFileUpload(Map<String, dynamic> task) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles();
      if (result != null) {
        String? filePath = result.files.single.path;
        if (filePath != null) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Uploading file...")));
          await _apiService.submitAssignment(task['id'].toString(), filePath, groupId: task['group_id']?.toString());
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Assignment submitted successfully!")));
            _fetchAssignments();
          }
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
    }
  }
}
