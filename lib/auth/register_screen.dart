import 'package:flutter/material.dart';
import '../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _fname = TextEditingController();
  final _lname = TextEditingController();
  String _title = 'Mr.';
  String _role = 'student';

  void _register() async {
    try {
      await ApiService().register({
        "title": _title,
        "first_name": _fname.text,
        "last_name": _lname.text,
        "email": _email.text,
        "password": _pass.text,
        "role": _role
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Success! Please Login.")));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _title,
              items: ['Mr.', 'Ms.', 'Dr.', 'Prof.'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() => _title = v!),
            ),
            TextField(controller: _fname, decoration: const InputDecoration(labelText: "First Name")),
            TextField(controller: _lname, decoration: const InputDecoration(labelText: "Last Name")),
            TextField(controller: _email, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: _pass, obscureText: true, decoration: const InputDecoration(labelText: "Password")),
            const SizedBox(height: 15),
            const Text("Role:"),
            Row(
              children: [
                Radio(value: 'student', groupValue: _role, onChanged: (v) => setState(() => _role = v!)), const Text("Student"),
                Radio(value: 'instructor', groupValue: _role, onChanged: (v) => setState(() => _role = v!)), const Text("Instructor"),
              ],
            ),
            ElevatedButton(onPressed: _register, child: const Text("SUBMIT"))
          ],
        ),
      ),
    );
  }
}