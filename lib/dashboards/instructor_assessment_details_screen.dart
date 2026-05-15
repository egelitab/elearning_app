import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../widgets/downloadable_behavior.dart';

class InstructorAssessmentDetailsScreen extends StatefulWidget {
  final dynamic assessment;

  const InstructorAssessmentDetailsScreen({super.key, required this.assessment});

  @override
  State<InstructorAssessmentDetailsScreen> createState() => _InstructorAssessmentDetailsScreenState();
}

class _InstructorAssessmentDetailsScreenState extends State<InstructorAssessmentDetailsScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _submissions = [];
  bool _isLoading = true;
  String? _error;

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
      final data = await _apiService.getSubmissions(widget.assessment['id'].toString());
      if (mounted) {
        setState(() {
          _submissions = data;
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
    String title = widget.assessment['title'] ?? 'Untitled';
    String type = (title.toLowerCase().contains('project')) ? 'Project' : 
                  (title.toLowerCase().contains('presentation')) ? 'Presentation' : 'Assignment';
    Color typeColor = type == 'Project' ? Colors.purple : (type == 'Presentation' ? Colors.orange : Colors.blue);
    
    String deadline = 'No due date';
    if (widget.assessment['due_date'] != null) {
      DateTime dt = DateTime.parse(widget.assessment['due_date']);
      deadline = DateFormat('MMM d, h:mm a').format(dt);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      body: CustomScrollView(
        slivers: [
          // 1. Sleek Header
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF05398F),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                title, 
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF05398F), Color(0xFF09AEF5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    type == 'Project' ? Icons.account_tree_rounded : 
                    (type == 'Presentation' ? Icons.present_to_all_rounded : Icons.assignment_rounded),
                    size: 80,
                    color: Colors.white.withOpacity(0.2),
                  ),
                ),
              ),
            ),
          ),

          // 2. Assessment Info Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoBadge(type, typeColor),
                      _buildInfoBadge(
                        widget.assessment['is_group_assignment'] == true ? 'Group' : 'Individual',
                        Colors.blueGrey
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text("Description", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF05398F))),
                  const SizedBox(height: 8),
                  Text(
                    widget.assessment['description'] ?? "No description provided.",
                    style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 18, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      Text(
                        "Deadline: $deadline",
                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Submissions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF05398F))),
                      if (!_isLoading)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF09AEF5).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "${_submissions.length} Total",
                            style: const TextStyle(color: Color(0xFF09AEF5), fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),

          // 3. Submissions List or Empty State
          _isLoading 
            ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            : _error != null
              ? SliverFillRemaining(child: Center(child: Text(_error!, style: const TextStyle(color: Colors.red))))
              : _submissions.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_rounded, size: 80, color: Colors.grey.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          const Text("No Submissions Available", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black45)),
                          const SizedBox(height: 8),
                          const Text("Students haven't submitted anything yet.", style: TextStyle(color: Colors.black38)),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final item = _submissions[index];
                          return _buildSubmissionCard(item);
                        },
                        childCount: _submissions.length,
                      ),
                    ),
                  ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildSubmissionCard(dynamic item) {
    bool isGraded = item['grade'] != null;
    bool isGroup = item['group_id'] != null;
    String displayName = isGroup 
        ? (item['group_name'] ?? 'Unknown Group')
        : "${item['first_name'] ?? ''} ${item['last_name'] ?? ''}";
    
    String initials = isGroup 
        ? (item['group_name']?.toString().split('-').last.trim() ?? 'G')
        : (item['first_name']?[0] ?? 'S');

    String fileName = item['file_path']?.toString().split('/').last ?? 'submission.file';

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
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF09AEF5).withOpacity(0.1),
                child: Text(initials, style: const TextStyle(color: Color(0xFF09AEF5), fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      item['section'] != null ? "Section ${item['section']}" : "Individual Submission",
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              if (isGraded)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${item['grade']}/100",
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
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
                    "Pending",
                    style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          DownloadableBehavior(
            filePath: item['file_path']?.toString() ?? '',
            fileName: fileName,
            builder: (context, isDownloaded, isDownloading, isPaused, progress, onTap) {
              return InkWell(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F7FC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description_rounded, color: Color(0xFF05398F)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          fileName,
                          style: const TextStyle(fontSize: 14, color: Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        isDownloaded ? Icons.visibility_outlined : Icons.download_rounded,
                        size: 20,
                        color: Colors.black38,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showGradingSheet(item),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF09AEF5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                isGraded ? "Edit Grade" : "Grade Now",
                style: const TextStyle(color: Color(0xFF09AEF5), fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGradingSheet(dynamic submission) {
    final TextEditingController scoreController = TextEditingController(text: submission['grade']?.toString() ?? '');
    final TextEditingController feedbackController = TextEditingController(text: submission['feedback'] ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Grade Submission", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF05398F))),
              const SizedBox(height: 20),
              TextField(
                controller: scoreController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Score (0-100)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.star_rounded, color: Colors.orange),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: feedbackController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Feedback",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () async {
                    if (scoreController.text.isNotEmpty) {
                      try {
                        await _apiService.gradeSubmission(
                          submission['id'].toString(),
                          double.parse(scoreController.text),
                          feedbackController.text
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          _fetchSubmissions();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Grade saved successfully!"), backgroundColor: Colors.green)
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red)
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF09AEF5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text("Save Grade", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
