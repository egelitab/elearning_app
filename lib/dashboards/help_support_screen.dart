import 'package:flutter/material.dart';
import 'student_profile_ask_question_screen.dart';
import '../utils/app_colors.dart';
import '../main.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  bool _showAllFaqs = false;

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
          title: Text("Help & Support", style: TextStyle(color: AppColors.appBarForeground, fontWeight: FontWeight.bold)),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Frequently Asked Questions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
              const SizedBox(height: 20),
              _buildFaqItem("How to download files?", "Go to the Courses screen, select your course materials, and tap the download icon next to the file to save it for offline use."),
              _buildFaqItem("How to see my grades?", "Navigate to the Courses section and tap on 'Grades' within a specific course to view your assignment and assessment scores."),
              _buildFaqItem("How to chat in groups?", "Open the Inbox or Messages tab from your dashboard, select your designated group, and you can start chatting with your peers immediately."),
              _buildFaqItem("How to contact my instructor?", "You can message your instructor directly through the 'Ask a Question' page or by finding their profile in the Inbox section."),
              _buildFaqItem("How to reset my password?", "Please contact the university admin or use the 'Forgot Password' link directly on the login screen."),
              
              if (_showAllFaqs) ...[
                _buildFaqItem("How to submit assignments?", "Go to your course, tap on Assignments, select the specific assignment, and tap 'Submit Assignment' to upload your work."),
                _buildFaqItem("How do I take a quiz?", "Navigate to the Quizzes section inside your course and tap 'Start Quiz'. Make sure you have a stable internet connection."),
                _buildFaqItem("Can I access courses offline?", "Yes, if you download the course materials using the download icon, you can view them without an internet connection."),
                _buildFaqItem("How to update my profile?", "Go to the Profile tab, tap on the edit icon next to your picture to update your profile details."),
              ],
  
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _showAllFaqs = !_showAllFaqs;
                    });
                  },
                  child: Text(_showAllFaqs ? "See Less" : "See More", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              
              const SizedBox(height: 40),
              Text("Need Help?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryText)),
              const SizedBox(height: 15),
              _buildContactTile(Icons.email_outlined, "Email Admin", "admin@bdu.edu.et", () {}),
              _buildContactTile(Icons.phone_in_talk_rounded, "Call Admin", "+251 911 234 567", () {}),
              _buildContactTile(Icons.question_answer_rounded, "Ask a Question", "Any questions or concerns? Ask us!", () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentProfileAskQuestionScreen()));
              }),
              
              const SizedBox(height: 30),
              Center(
                child: Text("App Version 1.2.0 (Stable)", style: TextStyle(color: AppColors.secondaryText.withOpacity(0.5), fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: AppColors.primary,
          collapsedIconColor: AppColors.secondaryText,
          title: Text(question, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.primaryText)),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Text(answer, style: TextStyle(color: AppColors.secondaryText, fontSize: 14, height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile(IconData icon, String title, String sub, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFF09AEF5).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: const Color(0xFF09AEF5)),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primaryText)),
        subtitle: Text(sub, style: TextStyle(fontSize: 13, color: AppColors.secondaryText)),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.secondaryText.withOpacity(0.3)),
      ),
    );
  }
}
