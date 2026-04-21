import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentProfileAccountScreen extends StatefulWidget {
  const StudentProfileAccountScreen({super.key});

  @override
  State<StudentProfileAccountScreen> createState() => _StudentProfileAccountScreenState();
}

class _StudentProfileAccountScreenState extends State<StudentProfileAccountScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();
  String _studentId = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _studentId = prefs.getString('institutional_id') ?? 'BDU-123456';
      _usernameController.text = prefs.getString('username') ?? 'student_user';
      _groupNameController.text = prefs.getString('group_name') ?? 'CS Group A';
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', _usernameController.text);
    await prefs.setString('group_name', _groupNameController.text);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account details updated successfully!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FC),
      appBar: AppBar(
        title: const Text('Account Details', style: TextStyle(color: Color(0xFF05398F), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF4F7FC),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF05398F)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Manage Your Info",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 30),
            _buildReadOnlyField("Student ID (Cannot be changed)", _studentId),
            const SizedBox(height: 20),
            _buildEditableField("Username", _usernameController, Icons.alternate_email_rounded),
            const SizedBox(height: 20),
            _buildEditableField("Group Name", _groupNameController, Icons.groups_rounded),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _saveData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF09AEF5),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54, fontSize: 13)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(value, style: const TextStyle(fontSize: 16, color: Colors.black45)),
        ),
      ],
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey, fontSize: 13)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF09AEF5)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
        ),
      ],
    );
  }
}
