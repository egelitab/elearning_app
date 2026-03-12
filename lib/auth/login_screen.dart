import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../dashboards/instructor_dashboard.dart';
import '../dashboards/student_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void _handleLogin() async {
    setState(() => _isLoading = true);
    try {
      final result = await ApiService().login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      final role = result['user']['role'].toString().toLowerCase();

      if (role == 'instructor') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const InstructorDashboard()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const StudentDashboard()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Email")),
            const SizedBox(height: 15),
            TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Password")),
            const SizedBox(height: 30),
            _isLoading 
              ? const CircularProgressIndicator() 
              : ElevatedButton(onPressed: _handleLogin, child: const Text("LOGIN")),
          ],
        ),
      ),
    );
  }
}