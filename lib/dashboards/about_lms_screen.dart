import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../main.dart';

class AboutLmsScreen extends StatelessWidget {
  const AboutLmsScreen({super.key});

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
            "About ELMS",
            style: TextStyle(
              color: AppColors.appBarForeground,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ]
                ),
                child: Icon(Icons.school_rounded, size: 80, color: AppColors.primary),
              ),
              const SizedBox(height: 30),
              Text(
                "E-Learning Management System",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              const SizedBox(height: 10),
              Text(
                "Version 1.0.0",
                style: TextStyle(fontSize: 16, color: AppColors.secondaryText),
              ),
              const SizedBox(height: 40),
              Text(
                "Our E-Learning Management System (ELMS) is designed to provide a seamless and interactive educational experience for students and instructors. "
                "We aim to bridge the gap between traditional learning and modern technology by offering tools for real-time collaboration, course management, and comprehensive assessment.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.primaryText, height: 1.5),
              ),
              const SizedBox(height: 40),
              _buildInfoCard("Developed By", "ELMS Development Team"),
              const SizedBox(height: 16),
              _buildInfoCard("Contact Support", "support@elms.edu"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.secondaryText)),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primaryText)),
        ],
      ),
    );
  }
}
