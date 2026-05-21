import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../main.dart';

class SendFeedbackScreen extends StatefulWidget {
  const SendFeedbackScreen({super.key});

  @override
  State<SendFeedbackScreen> createState() => _SendFeedbackScreenState();
}

class _SendFeedbackScreenState extends State<SendFeedbackScreen> {
  int _selectedRating = -1; // 0 to 4
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  final List<Map<String, String>> _ratings = [
    {"emoji": "😠", "label": "Bad"},
    {"emoji": "😞", "label": "Poor"},
    {"emoji": "😐", "label": "Okay"},
    {"emoji": "🙂", "label": "Good"},
    {"emoji": "🤩", "label": "Great"},
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _submitFeedback() async {
    if (_selectedRating == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your feedback!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: darkModeNotifier,
      builder: (context, isDark, _) => Scaffold(
        backgroundColor: AppColors.scaffold,
        appBar: AppBar(
          backgroundColor: AppColors.appBar,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_rounded, color: AppColors.appBarForeground),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text("Send Feedback", style: TextStyle(color: AppColors.appBarForeground, fontWeight: FontWeight.bold)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "How was your experience?",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primaryText),
              ),
              const SizedBox(height: 10),
              Text(
                "Your feedback helps us improve ELMS for everyone.",
                style: TextStyle(fontSize: 14, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_ratings.length, (index) {
                  final isSelected = _selectedRating == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedRating = index;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _ratings[index]["emoji"]!,
                            style: TextStyle(
                              fontSize: isSelected ? 36 : 30,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _ratings[index]["label"]!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.primary : AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 40),
              Text(
                "Tell us more (Optional)",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryText),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _feedbackController,
                maxLines: 5,
                style: TextStyle(color: AppColors.primaryText),
                decoration: InputDecoration(
                  hintText: "What did you like or dislike?",
                  hintStyle: TextStyle(color: AppColors.secondaryText.withOpacity(0.5)),
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          "Submit Feedback",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
