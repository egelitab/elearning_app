import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'create_quiz_screen.dart';

class InstructorQuizScreen extends StatefulWidget {
  const InstructorQuizScreen({super.key});

  @override
  State<InstructorQuizScreen> createState() => _InstructorQuizScreenState();
}

class _InstructorQuizScreenState extends State<InstructorQuizScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _courses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCourses();
  }

  Future<void> _fetchCourses() async {
    try {
      final courses = await _apiService.getInstructorCourses();
      if (mounted) setState(() { _courses = courses; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text("Quiz Manager", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFC2185B)])),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _courses.length,
              itemBuilder: (context, index) {
                final course = _courses[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.pink.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.quiz_rounded, color: Colors.pink),
                    ),
                    title: Text(course['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(course['course_code'] ?? '', style: const TextStyle(color: Colors.grey)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (context) => _CourseQuizManageScreen(courseId: course['id'].toString(), courseTitle: course['title'] ?? ''),
                    )),
                  ),
                );
              },
            ),
    );
  }
}

class _CourseQuizManageScreen extends StatefulWidget {
  final String courseId, courseTitle;
  const _CourseQuizManageScreen({required this.courseId, required this.courseTitle});

  @override
  State<_CourseQuizManageScreen> createState() => _CourseQuizManageScreenState();
}

class _CourseQuizManageScreenState extends State<_CourseQuizManageScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _quizzes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final quizzes = await _apiService.getQuizzesByCourse(widget.courseId);
      if (mounted) setState(() { _quizzes = quizzes; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _createQuiz() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateQuizScreen(
          currentCourseId: widget.courseId,
        ),
      ),
    );
    if (result == true) {
      _fetch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: Text(widget.courseTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFC2185B)])),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createQuiz,
        backgroundColor: const Color(0xFFE91E63),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Quiz", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quizzes.isEmpty
              ? const Center(child: Text("No quizzes yet. Tap + to create one.", style: TextStyle(color: Colors.grey)))
              : RefreshIndicator(
                  onRefresh: _fetch,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _quizzes.length,
                    itemBuilder: (context, index) => _buildQuizCard(_quizzes[index]),
                  ),
                ),
    );
  }

  Widget _buildQuizCard(dynamic quiz) {
    final isPublished = quiz['is_published'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(
            builder: (context) => _QuizEditorScreen(quizId: quiz['id'].toString(), quizTitle: quiz['title'] ?? ''),
          ));
          _fetch();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(quiz['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isPublished ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isPublished ? "Published" : "Draft",
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isPublished ? Colors.green : Colors.orange),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text("${quiz['question_count'] ?? 0} questions · ${quiz['attempt_count'] ?? 0} attempts",
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.edit_rounded, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizEditorScreen extends StatefulWidget {
  final String quizId, quizTitle;
  const _QuizEditorScreen({required this.quizId, required this.quizTitle});

  @override
  State<_QuizEditorScreen> createState() => _QuizEditorScreenState();
}

class _QuizEditorScreenState extends State<_QuizEditorScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _quiz;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final quiz = await _apiService.getQuizDetail(widget.quizId);
      if (mounted) setState(() { _quiz = quiz; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addQuestion() async {
    final textCtrl = TextEditingController();
    final pointsCtrl = TextEditingController(text: "1");
    List<Map<String, dynamic>> options = [
      {"text": "", "correct": false},
      {"text": "", "correct": false},
      {"text": "", "correct": false},
      {"text": "", "correct": false},
    ];

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text("Add Question"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: textCtrl, decoration: const InputDecoration(labelText: "Question*", border: OutlineInputBorder()), maxLines: 3),
                const SizedBox(height: 12),
                TextField(controller: pointsCtrl, decoration: const InputDecoration(labelText: "Points", border: OutlineInputBorder()), keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                const Text("Options (tap radio to mark correct):", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...List.generate(options.length, (i) {
                  final ctrl = TextEditingController(text: options[i]["text"]);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Radio<int>(
                          value: i,
                          groupValue: options.indexWhere((o) => o["correct"] == true),
                          onChanged: (v) {
                            setDialogState(() {
                              for (var o in options) { o["correct"] = false; }
                              options[i]["correct"] = true;
                            });
                          },
                        ),
                        Expanded(
                          child: TextField(
                            controller: ctrl,
                            decoration: InputDecoration(hintText: "Option ${i + 1}", isDense: true, border: const OutlineInputBorder()),
                            onChanged: (val) => options[i]["text"] = val,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Add")),
          ],
        ),
      ),
    );

    if (confirmed != true || textCtrl.text.trim().isEmpty) return;

    final validOptions = options.where((o) => (o["text"] as String).trim().isNotEmpty).toList();
    if (validOptions.isEmpty) return;

    try {
      await _apiService.addQuizQuestion(widget.quizId, {
        "question_text": textCtrl.text.trim(),
        "question_type": "multiple_choice",
        "points": int.tryParse(pointsCtrl.text) ?? 1,
        "order_index": (_quiz?['questions'] as List?)?.length ?? 0,
        "options": validOptions.map((o) => {"option_text": o["text"], "is_correct": o["correct"]}).toList(),
      });
      _fetch();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  void _publish() async {
    final questions = (_quiz?['questions'] as List?) ?? [];
    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Add at least one question first"), backgroundColor: Colors.red));
      return;
    }
    try {
      await _apiService.publishQuiz(widget.quizId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Quiz published!"), backgroundColor: Colors.green));
        _fetch();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions = (_quiz?['questions'] as List?) ?? [];
    final isPublished = _quiz?['is_published'] == true;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: Text(widget.quizTitle, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFC2185B)])),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!_isLoading && !isPublished)
            TextButton.icon(
              onPressed: _publish,
              icon: const Icon(Icons.publish, color: Colors.white, size: 18),
              label: const Text("Publish", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      floatingActionButton: isPublished
          ? null
          : FloatingActionButton(
              onPressed: _addQuestion,
              backgroundColor: const Color(0xFFE91E63),
              child: const Icon(Icons.add, color: Colors.white),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : questions.isEmpty
              ? const Center(child: Text("No questions yet. Tap + to add.", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final q = questions[index];
                    final opts = (q['options'] as List?) ?? [];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: const Color(0xFFE91E63),
                                child: Text("${index + 1}", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(child: Text(q['question_text'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15))),
                              Text("${q['points'] ?? 1} pt", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ...opts.map((opt) => Padding(
                            padding: const EdgeInsets.only(left: 38, bottom: 4),
                            child: Row(
                              children: [
                                Icon(
                                  opt['is_correct'] == true ? Icons.check_circle : Icons.circle_outlined,
                                  size: 16,
                                  color: opt['is_correct'] == true ? Colors.green : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(opt['option_text'] ?? '', style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: opt['is_correct'] == true ? FontWeight.bold : FontWeight.normal,
                                  color: opt['is_correct'] == true ? Colors.green.shade700 : Colors.black87,
                                ))),
                              ],
                            ),
                          )),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
