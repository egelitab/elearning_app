import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';

class StudentQuizScreen extends StatefulWidget {
  const StudentQuizScreen({super.key});

  @override
  State<StudentQuizScreen> createState() => _StudentQuizScreenState();
}

class _StudentQuizScreenState extends State<StudentQuizScreen> {
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
      final courses = await _apiService.getStudentCourses();
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
        title: const Text("Quizzes", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFC2185B)]),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _courses.isEmpty
              ? const Center(child: Text("No courses found", style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _courses.length,
                  itemBuilder: (context, index) {
                    final course = _courses[index];
                    return _buildCourseCard(course);
                  },
                ),
    );
  }

  Widget _buildCourseCard(dynamic course) {
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
        subtitle: Text(course['course_code'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 13)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => _CourseQuizListScreen(
              courseId: course['id'].toString(),
              courseTitle: course['title'] ?? '',
            ),
          ));
        },
      ),
    );
  }
}

class _CourseQuizListScreen extends StatefulWidget {
  final String courseId, courseTitle;
  const _CourseQuizListScreen({required this.courseId, required this.courseTitle});

  @override
  State<_CourseQuizListScreen> createState() => _CourseQuizListScreenState();
}

class _CourseQuizListScreenState extends State<_CourseQuizListScreen> {
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _quizzes.isEmpty
              ? const Center(child: Text("No quizzes available", style: TextStyle(color: Colors.grey, fontSize: 16)))
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
            builder: (context) => _QuizTakingScreen(quizId: quiz['id'].toString(), quizTitle: quiz['title'] ?? 'Quiz'),
          ));
          _fetch();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(quiz['title'] ?? 'Untitled Quiz', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
              if (quiz['description'] != null && quiz['description'].toString().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(quiz['description'], style: const TextStyle(color: Colors.grey, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  _infoBadge(Icons.help_outline, "${quiz['question_count'] ?? 0} Q's", Colors.blue),
                  const SizedBox(width: 8),
                  _infoBadge(Icons.timer_outlined, "${quiz['duration_minutes'] ?? 30} min", Colors.orange),
                  const SizedBox(width: 8),
                  _infoBadge(Icons.replay, "Max ${quiz['max_attempts'] ?? 1}", Colors.purple),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _QuizTakingScreen extends StatefulWidget {
  final String quizId, quizTitle;
  const _QuizTakingScreen({required this.quizId, required this.quizTitle});

  @override
  State<_QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<_QuizTakingScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _quiz;
  Map<String, dynamic>? _attempt;
  List<dynamic> _questions = [];
  Map<String, String?> _answers = {}; // question_id -> selected_option_id
  int _currentIndex = 0;
  Timer? _timer;
  int _timeLeft = 0;

  @override
  void initState() {
    super.initState();
    _loadQuizAndStart();
  }

  Future<void> _loadQuizAndStart() async {
    try {
      final quiz = await _apiService.getQuizDetail(widget.quizId);
      final attempt = await _apiService.startQuizAttempt(widget.quizId);
      if (mounted) {
        setState(() {
          _quiz = quiz;
          _attempt = attempt;
          _questions = (quiz['questions'] as List?) ?? [];
          _timeLeft = (quiz['duration_minutes'] ?? 30) * 60;
          _isLoading = false;
        });
        _startTimer();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
        Navigator.pop(context);
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft <= 0) {
        timer.cancel();
        _submit();
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return "${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
  }

  void _submit() async {
    _timer?.cancel();
    setState(() => _isSubmitting = true);

    try {
      final answerList = _answers.entries
          .where((e) => e.value != null)
          .map((e) => {"question_id": e.key, "selected_option_id": e.value})
          .toList();

      final result = await _apiService.submitQuizAttempt(_attempt!['id'].toString(), answerList);

      if (mounted) {
        final score = result['score'] ?? 0;
        final total = result['total_points'] ?? 0;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Quiz Submitted!", textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  score >= total * 0.5 ? Icons.emoji_events_rounded : Icons.sentiment_neutral_rounded,
                  size: 64,
                  color: score >= total * 0.5 ? Colors.amber : Colors.grey,
                ),
                const SizedBox(height: 16),
                Text("$score / $total", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  score >= total * 0.7 ? "Excellent!" : score >= total * 0.5 ? "Good job!" : "Keep practicing!",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () { Navigator.pop(ctx); Navigator.pop(context); },
                child: const Text("Done"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.quizTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.quizTitle)),
        body: const Center(child: Text("This quiz has no questions")),
      );
    }

    final q = _questions[_currentIndex];
    final options = (q['options'] as List?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: Text("${_currentIndex + 1} / ${_questions.length}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFE91E63), Color(0xFFC2185B)])),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: _timeLeft < 60 ? Colors.red.withOpacity(0.3) : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(_formatTime(_timeLeft), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _questions.length,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation(Color(0xFFE91E63)),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Question ${_currentIndex + 1}", style: const TextStyle(color: Colors.pink, fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 8),
                        Text(q['question_text'] ?? '', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, height: 1.4)),
                        const SizedBox(height: 4),
                        Text("${q['points'] ?? 1} point(s)", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Options
                  ...options.map((opt) {
                    final isSelected = _answers[q['id'].toString()] == opt['id'].toString();
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _answers[q['id'].toString()] = opt['id'].toString();
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFE91E63).withOpacity(0.1) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFE91E63) : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                              color: isSelected ? const Color(0xFFE91E63) : Colors.grey,
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(opt['option_text'] ?? '', style: TextStyle(fontSize: 15, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal))),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  if (_currentIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _currentIndex--),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Previous"),
                      ),
                    ),
                  if (_currentIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : _currentIndex < _questions.length - 1
                              ? () => setState(() => _currentIndex++)
                              : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _currentIndex < _questions.length - 1 ? const Color(0xFFE91E63) : Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              _currentIndex < _questions.length - 1 ? "Next" : "Submit Quiz",
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
