import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../main.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

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
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.appBarForeground),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            "Terms and Conditions",
            style: TextStyle(
              color: AppColors.appBarForeground,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("1. Introduction"),
              _buildSectionText(
                "Welcome to ELMS (E-Learning Management System). By accessing or using our platform, you agree to be bound by these terms and conditions. Please read them carefully before using our services.",
              ),
              const SizedBox(height: 20),
              _buildSectionTitle("2. User Eligibility"),
              _buildSectionText(
                "Our services are available to students and instructors who are affiliated with authorized educational institutions. You must provide accurate and complete information during registration.",
              ),
              const SizedBox(height: 20),
              _buildSectionTitle("3. Privacy Policy"),
              _buildSectionText(
                "Your privacy is important to us. Our Privacy Policy explains how we collect, use, and protect your personal information. By using ELMS, you consent to our collection and use of data as described in the Privacy Policy.",
              ),
              const SizedBox(height: 20),
              _buildSectionTitle("4. Prohibited Conduct"),
              _buildSectionText(
                "Users are prohibited from using the platform for any unlawful purpose, including but not limited to: uploading malicious software, infringing on intellectual property rights, or harassing other users.",
              ),
              const SizedBox(height: 20),
              _buildSectionTitle("5. Content Ownership"),
              _buildSectionText(
                "Educational materials uploaded by instructors remain the property of the instructor or the institution. Users may only use these materials for educational purposes within the scope of their courses.",
              ),
              const SizedBox(height: 20),
              _buildSectionTitle("6. Termination"),
              _buildSectionText(
                "We reserve the right to terminate or suspend access to our platform at any time, without prior notice, for conduct that we believe violates these terms or is harmful to other users or the platform itself.",
              ),
              const SizedBox(height: 20),
              _buildSectionTitle("7. Contact Us"),
              _buildSectionText(
                "If you have any questions about these Terms and Conditions, please contact our support team through the Help Center.",
              ),
              const SizedBox(height: 40),
              Center(
                child: Text(
                  "Last updated: May 2026",
                  style: TextStyle(
                    color: AppColors.secondaryText.withValues(alpha: 0.5),
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryText,
        ),
      ),
    );
  }

  Widget _buildSectionText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        color: AppColors.secondaryText,
        height: 1.5,
      ),
    );
  }
}
