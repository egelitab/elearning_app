import 'package:flutter/material.dart';

class InstructorScheduleScreen extends StatelessWidget {
  const InstructorScheduleScreen({super.key});

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
        title: const Text("Schedule & Office Hours", style: TextStyle(color: Color(0xFF05398F), fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Weekly Class Schedule"),
            const SizedBox(height: 15),
            _buildScheduleItem("Monday", "Computer Science 101", "08:30 AM - 10:30 AM", "Block 4, Room 202", Colors.blue),
            _buildScheduleItem("Wednesday", "Database Systems", "10:45 AM - 12:45 PM", "Lab 2", Colors.green),
            _buildScheduleItem("Thursday", "Software Engineering", "02:00 PM - 04:00 PM", "Block 1, Seminar Room", Colors.orange),
            
            const SizedBox(height: 35),
            _buildSectionHeader("Office Hours"),
            const SizedBox(height: 15),
            _buildOfficeHourItem("Tuesdays & Thursdays", "10:00 AM - 12:00 PM", "Block 4, Office 412"),
            
            const SizedBox(height: 40),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Editing schedule will be available in the next update.")));
                },
                icon: const Icon(Icons.edit_calendar_rounded),
                label: const Text("Request Schedule Change"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF05398F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87));
  }

  Widget _buildScheduleItem(String day, String course, String time, String location, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 50,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(course, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text("$day | $time", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                Text(location, style: const TextStyle(color: Color(0xFF09AEF5), fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfficeHourItem(String days, String time, String location) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade50, Colors.white], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_filled_rounded, color: Color(0xFF05398F), size: 40),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(days, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(time, style: const TextStyle(color: Colors.black54, fontSize: 14)),
              Text(location, style: const TextStyle(color: Color(0xFF05398F), fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}
