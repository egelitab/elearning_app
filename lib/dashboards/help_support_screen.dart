import 'package:flutter/material.dart';
import 'student_profile_ask_question_screen.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  bool _showMoreFaqs = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F7FC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF05398F)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Help & Support", style: TextStyle(color: Color(0xFF05398F), fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Frequently Asked Questions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 20),
            _buildFaqItem("How to download files?", "Go to the Courses screen, select your course materials, and tap the download icon next to the file to save it for offline use."),
            _buildFaqItem("How to see my grades?", "Navigate to the Courses section and tap on 'Grades' within a specific course to view your assignment and assessment scores."),
            _buildFaqItem("How to chat in groups?", "Open the Inbox or Messages tab from your dashboard, select your designated group, and you can start chatting with your peers immediately."),
            _buildFaqItem("How to contact my instructor?", "You can message your instructor directly through the 'Ask a Question' page or by finding their profile in the Inbox section."),
            _buildFaqItem("How to reset my password?", "Please contact the university admin or use the 'Forgot Password' link directly on the login screen."),
            
            if (_showMoreFaqs) ...[
              _buildFaqItem("Can I use ELMS offline?", "Yes, once you download materials, you can view them without an internet connection in the 'Downloads' section."),
              _buildFaqItem("How to join a live session?", "If your instructor schedules a live lecture, a link will appear in your 'Schedule' or 'Notifications' tab. Tap the link to join via the integrated meeting tool."),
              _buildFaqItem("Where can I find the academic calendar?", "The academic calendar is available in the 'Menu' tab under the 'Calendar' section, showing important semester dates."),
              _buildFaqItem("How to report a technical bug?", "Use the 'Ask a Question' or 'Send Feedback' options below to reach our technical support team directly."),
            ],

            const SizedBox(height: 10),
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _showMoreFaqs = !_showMoreFaqs;
                  });
                },
                child: Text(
                  _showMoreFaqs ? "Show Less" : "See More", 
                  style: const TextStyle(color: Color(0xFF09AEF5), fontWeight: FontWeight.bold, fontSize: 16)
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            const Text("Need Help?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 15),
            _buildContactTile(Icons.email_outlined, "Email Admin", "admin@bdu.edu.et", () {}),
            _buildContactTile(Icons.phone_in_talk_rounded, "Call Admin", "+251 911 234 567", () {}),
            _buildContactTile(Icons.question_answer_rounded, "Ask a Question", "Any questions or concerns? Ask us!", () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const StudentProfileAskQuestionScreen()));
            }),
            
            const SizedBox(height: 30),
            const Center(
              child: Text("App Version 1.2.0 (Stable)", style: TextStyle(color: Colors.grey, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Theme(
        data: ThemeData().copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87)),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Text(answer, style: const TextStyle(color: Colors.black54, fontSize: 14, height: 1.5)),
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
        color: Colors.white,
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
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 13, color: Colors.black54)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
      ),
    );
  }
}
