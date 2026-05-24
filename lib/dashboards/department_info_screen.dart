import 'package:flutter/material.dart';

class DepartmentInfoScreen extends StatelessWidget {
  const DepartmentInfoScreen({super.key});

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
        title: const Text("Department Information", style: TextStyle(color: Color(0xFF05398F), fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
              ),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFFE3F2FD),
                    child: Icon(Icons.business_rounded, size: 45, color: Color(0xFF09AEF5)),
                  ),
                  const SizedBox(height: 16),
                  const Text("Faculty of Computing", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF05398F))),
                  const Text("Department of Computer Science", style: TextStyle(fontSize: 16, color: Colors.black54)),
                  const Divider(height: 40),
                  _buildDetailRow(Icons.location_on_rounded, "Office Location", "Block 4, 3rd Floor"),
                  _buildDetailRow(Icons.email_rounded, "Contact Email", "cs.dept@bdu.edu.et"),
                  _buildDetailRow(Icons.phone_rounded, "Extension", "+251 (058) 226-XXXX"),
                ],
              ),
            ),
            const SizedBox(height: 30),
            _buildInfoCard(
              "Head of Department",
              "Dr. Samuel Getachew",
              Icons.person_rounded,
              "Available: Mon-Fri, 9:00 AM - 5:00 PM"
            ),
            const SizedBox(height: 15),
            _buildInfoCard(
              "Department Portal",
              "Access internal resources and announcements",
              Icons.language_rounded,
              "https://itsc.bdu.edu.et"
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF09AEF5)),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String subtitle, IconData icon, String foot) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFF09AEF5).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: const Color(0xFF09AEF5)),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 14)),
                const SizedBox(height: 8),
                Text(foot, style: const TextStyle(color: Color(0xFF05398F), fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          )
        ],
      ),
    );
  }
}
