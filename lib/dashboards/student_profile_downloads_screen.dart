import 'package:flutter/material.dart';

class StudentProfileDownloadsScreen extends StatefulWidget {
  const StudentProfileDownloadsScreen({super.key});

  @override
  State<StudentProfileDownloadsScreen> createState() => _StudentProfileDownloadsScreenState();
}

class _StudentProfileDownloadsScreenState extends State<StudentProfileDownloadsScreen> {
  // Mock data
  double _currentUsageGB = 2.4;
  double _limitGB = 5.0;

  @override
  Widget build(BuildContext context) {
    double usagePercentage = _currentUsageGB / _limitGB;
    if (usagePercentage > 1.0) usagePercentage = 1.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text('Downloads Storage', style: TextStyle(color: Color(0xFF05398F), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF4F7FC),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF05398F)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Memory Usage",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${_currentUsageGB.toStringAsFixed(1)} GB Used", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text("${_limitGB.toStringAsFixed(1)} GB Limit", style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: usagePercentage,
                      minHeight: 12,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>((usagePercentage > 0.8) ? Colors.red : const Color(0xFF09AEF5)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            const Text(
              "Set Download Limit",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Text(
              "Adjust the maximum amount of storage this app can use for offline materials.",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            Slider(
              value: _limitGB,
              min: 1.0,
              max: 20.0,
              divisions: 19,
              activeColor: const Color(0xFF05398F),
              label: "${_limitGB.toStringAsFixed(1)} GB",
              onChanged: (val) {
                setState(() {
                  _limitGB = val;
                });
              },
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Storage limit saved.')));
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF09AEF5),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("Save Limit", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
