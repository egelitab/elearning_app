import 'package:flutter/material.dart';

class AboutElmsScreen extends StatelessWidget {
  const AboutElmsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF05398F), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "About ELMS",
          style: TextStyle(color: Color(0xFF05398F), fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Branding Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 50),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF09AEF5).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/logo.png',
                      height: 100,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.school_rounded, size: 80, color: Color(0xFF09AEF5)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "ELMS",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF05398F), letterSpacing: 2),
                  ),
                  const Text(
                    "E-Learning Management System",
                    style: TextStyle(fontSize: 14, color: Colors.black45, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF05398F).withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Version 2.4.0",
                      style: TextStyle(fontSize: 12, color: Color(0xFF05398F), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Info Cards
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildAboutCard(
                    "Our Mission",
                    "To provide a seamless, modern, and accessible learning environment for students and educators worldwide. ELMS is designed to bridge the gap between traditional education and digital innovation.",
                    Icons.lightbulb_outline_rounded,
                    const Color(0xFF09AEF5),
                  ),
                  const SizedBox(height: 16),
                  _buildAboutCard(
                    "Platform Features",
                    "Integrated course management, real-time messaging, digital assessments, and advanced academic analytics all in one unified experience.",
                    Icons.auto_awesome_mosaic_rounded,
                    const Color(0xFF05398F),
                  ),
                  const SizedBox(height: 16),
                  _buildAboutCard(
                    "Institutional Support",
                    "ELMS is the official learning portal for our university, maintained by the Digital Learning & Innovation Department.",
                    Icons.account_balance_rounded,
                    Colors.indigo,
                  ),
                ],
              ),
            ),

            // 3. Footer
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Column(
                children: [
                  Text(
                    "© 2026 ELMS Learning Solutions",
                    style: TextStyle(color: Colors.black38, fontSize: 12),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "All Rights Reserved",
                    style: TextStyle(color: Colors.black26, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard(String title, String content, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
                ),
                const SizedBox(height: 8),
                Text(
                  content,
                  style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
