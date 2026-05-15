import 'package:flutter/material.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F7FC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF05398F), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Privacy & Security", 
          style: TextStyle(color: Color(0xFF05398F), fontSize: 22, fontWeight: FontWeight.bold)
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Policies & Agreement"),
            _buildLegalCard(),
            
            const SizedBox(height: 40),
            const Center(
              child: Text(
                "ELMS Version 1.0.2\nLast Updated: May 2024",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black38, fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18, 
          fontWeight: FontWeight.bold, 
          color: Color(0xFF05398F)
        ),
      ),
    );
  }


  Widget _buildLegalCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          _buildListTile(
            icon: Icons.policy_outlined,
            title: "Privacy Policy",
            onTap: () => _showTextDialog("Privacy Policy", _dummyPrivacyPolicy),
          ),
          const Divider(height: 1, indent: 60, endIndent: 20),
          _buildListTile(
            icon: Icons.gavel_rounded,
            title: "Terms of Service",
            onTap: () => _showTextDialog("Terms of Service", _dummyTermsOfService),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile({required IconData icon, required String title, String? subtitle, required VoidCallback onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF09AEF5).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF09AEF5), size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.black54)) : null,
      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.black26),
      onTap: onTap,
    );
  }



  void _showTextDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(color: Color(0xFF05398F), fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(content, style: const TextStyle(fontSize: 14, height: 1.5)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("I Understand")),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  final String _dummyPrivacyPolicy = """
At ELMS, we take your privacy seriously. This policy describes how we collect, use, and protect your personal information.

1. Information Collection: We collect your name, email, and academic record to provide our services.
2. Data Usage: Your data is used strictly for educational purposes and to personalize your learning experience.
3. Data Protection: We use industry-standard encryption to protect your data from unauthorized access.
4. Third Parties: We do not sell your personal data to third parties.

By using ELMS, you agree to the collection and use of information in accordance with this policy.
""";

  final String _dummyTermsOfService = """
Welcome to ELMS. By accessing our platform, you agree to the following terms:

1. User Conduct: You agree to use the platform for lawful educational purposes only.
2. Account Responsibility: You are responsible for maintaining the confidentiality of your account credentials.
3. Content Ownership: Instructors retain ownership of their course materials, while students retain ownership of their submissions.
4. Service Availability: We strive for 99.9% uptime but do not guarantee uninterrupted access.

Failure to comply with these terms may result in account suspension.
""";
}
