import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CreateQuizScreen extends StatefulWidget {
  final String currentCourseId;
  final List<dynamic>? allCourses;

  const CreateQuizScreen({
    super.key,
    required this.currentCourseId,
    this.allCourses,
  });

  @override
  State<CreateQuizScreen> createState() => _CreateQuizScreenState();
}

class QuestionModel {
  String text;
  int points;
  List<Map<String, dynamic>> options;

  QuestionModel({
    required this.text,
    required this.points,
    required this.options,
  });
}

class _CreateQuizScreenState extends State<CreateQuizScreen> {
  final ApiService _apiService = ApiService();

  late String _selectedCourseId;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _durationCtrl = TextEditingController(text: "30");
  final _attemptsCtrl = TextEditingController(text: "1");

  List<QuestionModel> _questions = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedCourseId = widget.currentCourseId;
  }

  void _showQuestionDialog({int? index}) async {
    final textCtrl = TextEditingController();
    final pointsCtrl = TextEditingController(text: "1");
    List<Map<String, dynamic>> options = [
      {"text": "", "correct": false},
      {"text": "", "correct": false},
      {"text": "", "correct": false},
      {"text": "", "correct": false},
    ];

    if (index != null) {
      textCtrl.text = _questions[index].text;
      pointsCtrl.text = _questions[index].points.toString();
      options = _questions[index].options.map((o) => Map<String, dynamic>.from(o)).toList();
    }

    bool isFormValid() {
      return textCtrl.text.trim().isNotEmpty &&
          options.any((o) => o["correct"] == true);
    }

    final result = await showDialog<QuestionModel>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(index == null ? "Add Question" : "Edit Question"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: textCtrl,
                    onChanged: (val) => setDialogState(() {}),
                    decoration: const InputDecoration(
                        labelText: "Question*", border: OutlineInputBorder()),
                    maxLines: 3),
                const SizedBox(height: 12),
                TextField(
                    controller: pointsCtrl,
                    decoration: const InputDecoration(
                        labelText: "Points", border: OutlineInputBorder()),
                    keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                const Text("Options (tap radio to mark correct):",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...List.generate(options.length, (i) {
                  final ctrl = TextEditingController(text: options[i]["text"]);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Radio<int>(
                          value: i,
                          groupValue:
                              options.indexWhere((o) => o["correct"] == true),
                          onChanged: (v) {
                            setDialogState(() {
                              for (var o in options) {
                                o["correct"] = false;
                              }
                              options[i]["correct"] = true;
                            });
                          },
                        ),
                        Expanded(
                          child: TextField(
                            controller: ctrl,
                            decoration: InputDecoration(
                                hintText: "Option ${i + 1}",
                                isDense: true,
                                border: const OutlineInputBorder()),
                            onChanged: (val) {
                              options[i]["text"] = val;
                              setDialogState(() {});
                            },
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
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancel")),
            ElevatedButton(
                onPressed: isFormValid()
                    ? () {
                        final validOptions = options
                            .where((o) => (o["text"] as String).trim().isNotEmpty)
                            .toList();
                        if (validOptions.isEmpty) return;

                        Navigator.pop(
                          ctx,
                          QuestionModel(
                            text: textCtrl.text.trim(),
                            points: int.tryParse(pointsCtrl.text) ?? 1,
                            options: options,
                          ),
                        );
                      }
                    : null,
                child: Text(index == null ? "Add" : "Save")),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (index == null) {
          _questions.add(result);
        } else {
          _questions[index] = result;
        }
      });
    }
  }

  Future<void> _saveQuiz() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Title is required"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final quiz = await _apiService.createQuiz({
        "course_id": _selectedCourseId,
        "title": _titleCtrl.text.trim(),
        "description": _descCtrl.text.trim(),
        "duration_minutes": int.tryParse(_durationCtrl.text) ?? 30,
        "max_attempts": int.tryParse(_attemptsCtrl.text) ?? 1,
      });

      final quizId = quiz['id'].toString();

      for (int i = 0; i < _questions.length; i++) {
        final q = _questions[i];
        final validOptions = q.options
            .where((o) => (o["text"] as String).trim().isNotEmpty)
            .toList();

        await _apiService.addQuizQuestion(quizId, {
          "question_text": q.text,
          "question_type": "multiple_choice",
          "points": q.points,
          "order_index": i,
          "options": validOptions
              .map((o) => {"option_text": o["text"], "is_correct": o["correct"]})
              .toList(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Quiz created successfully!"), backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text("Create Quiz"),
        backgroundColor: const Color(0xFFF4F7FC),
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (widget.allCourses != null && widget.allCourses!.isNotEmpty)
                  DropdownButtonFormField<String>(
                    value: _selectedCourseId,
                    decoration: const InputDecoration(
                      labelText: "Course",
                      border: OutlineInputBorder(),
                    ),
                    items: widget.allCourses!.map((course) {
                      return DropdownMenuItem<String>(
                        value: course['id'].toString(),
                        child: Text(
                          course['title'] ?? course['course_code'] ?? 'Unknown Course',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCourseId = val;
                        });
                      }
                    },
                  ),
                const SizedBox(height: 16),
                TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                        labelText: "Quiz Title*", border: OutlineInputBorder())),
                const SizedBox(height: 16),
                TextField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(
                        labelText: "Description", border: OutlineInputBorder()),
                    maxLines: 3),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _durationCtrl,
                        decoration: const InputDecoration(
                            labelText: "Duration (min)",
                            border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _attemptsCtrl,
                        decoration: const InputDecoration(
                            labelText: "Max Attempts",
                            border: OutlineInputBorder()),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Questions",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      onPressed: () => _showQuestionDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text("Add Question"),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_questions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(
                        child: Text("No questions added yet.",
                            style: TextStyle(color: Colors.grey))),
                  )
                else
                  ...List.generate(_questions.length, (index) {
                    final q = _questions[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () => _showQuestionDialog(index: index),
                        title: Text(q.text),
                        subtitle: Text("${q.points} Points • ${q.options.where((o) => (o['text'] as String).trim().isNotEmpty).length} Options"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _questions.removeAt(index);
                            });
                          },
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveQuiz,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("Save Quiz",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }
}
