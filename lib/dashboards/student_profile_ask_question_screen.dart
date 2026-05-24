import 'package:flutter/material.dart';
import '../services/api_service.dart';

class StudentProfileAskQuestionScreen extends StatefulWidget {
  const StudentProfileAskQuestionScreen({super.key});

  @override
  State<StudentProfileAskQuestionScreen> createState() => _StudentProfileAskQuestionScreenState();
}

class _StudentProfileAskQuestionScreenState extends State<StudentProfileAskQuestionScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isSending = false;
  final List<Map<String, dynamic>> _messages = [
    {
      "isMe": false,
      "text": "Please leave your question below. An admin will review and respond to your inquiry as soon as possible.",
      "time": "System Notice"
    }
  ];

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"isMe": true, "text": text, "time": "Sending..."});
      _msgController.clear();
      _isSending = true;
    });

    try {
      await _apiService.createSupportTicket(
        "App Question",
        text,
        priority: "Medium",
      );
      if (mounted) {
        setState(() {
          // Update the last message time
          _messages.last["time"] = "Sent ✓";
          // Add confirmation
          _messages.add({
            "isMe": false,
            "text": "Your question has been submitted as a support ticket. You'll receive a response from the admin soon.",
            "time": "System"
          });
          _isSending = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.last["time"] = "Failed to send";
          _isSending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString().replaceAll('Exception: ', '')}"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text('Ask a Question', style: TextStyle(color: Color(0xFF05398F), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF4F7FC),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF05398F)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                bool isMe = msg['isMe'];
                return _buildMessageBubble(msg['text'], msg['time'], isMe);
              },
            ),
          ),
          _buildChatInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, String time, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFF09AEF5) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 6),
            Text(
              time,
              style: TextStyle(color: isMe ? Colors.white70 : Colors.black45, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7FC),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _msgController,
                  decoration: const InputDecoration(
                    hintText: "Type your question...",
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                  enabled: !_isSending,
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _isSending ? null : _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isSending ? Colors.grey : const Color(0xFF09AEF5),
                  shape: BoxShape.circle,
                ),
                child: _isSending
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            )
          ],
        ),
      ),
    );
  }
}
