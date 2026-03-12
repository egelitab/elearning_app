import 'package:flutter/material.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _index = 0;
  final _tabs = [const Text("HOME"), const Text("COURSES"), const Text("INBOX"), const Text("DOWNLOAD"), const Text("PROFILE")];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Student Portal")),
      body: Center(child: _tabs[_index]),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'HOME'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'COURSES'),
          BottomNavigationBarItem(icon: Icon(Icons.mail), label: 'INBOX'),
          BottomNavigationBarItem(icon: Icon(Icons.download), label: 'DOWNLOAD'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'PROFILE'),
        ],
      ),
    );
  }
}