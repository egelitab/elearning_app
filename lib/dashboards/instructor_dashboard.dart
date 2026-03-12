import 'package:flutter/material.dart';

class InstructorDashboard extends StatefulWidget {
  const InstructorDashboard({super.key});
  @override
  State<InstructorDashboard> createState() => _InstructorDashboardState();
}

class _InstructorDashboardState extends State<InstructorDashboard> {
  int _index = 0;
  final _tabs = [const Text("HOME"), const Text("COURSES"), const Text("CHAT"), const Text("MY FILES"), const Text("PROFILE")];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Instructor Portal")),
      body: Center(child: _tabs[_index]),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'HOME'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'COURSES'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'CHAT'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'MY FILES'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'PROFILE'),
        ],
      ),
    );
  }
}