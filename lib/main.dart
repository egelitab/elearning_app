import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui';
import 'auth/welcome_screen.dart';
import 'dashboards/instructor_dashboard.dart';
import 'dashboards/student_dashboard.dart';

void main() {
  runApp(const ELearningApp());
}

class ELearningApp extends StatelessWidget {
  const ELearningApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ELMS Project',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch, PointerDeviceKind.stylus, PointerDeviceKind.unknown},
      ),
      // Set the AuthWrapper as the home to handle persistent login
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  String? _token;
  String? _role;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // Logic to read from device storage
  Future<void> _checkLoginStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Slight delay to ensure smooth transition or to show a splash logo
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      _token = prefs.getString('auth_token');
      _role = prefs.getString('user_role');
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (_isLoading) {
      child = Scaffold(
        key: const ValueKey('loading'),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF09AEF5), Color(0xFF05398F)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                children: [
                  const Spacer(flex: 3),
                  
                  // Central Logo lowered only on the loading screen
                  Image.asset(
                    'assets/logo.png',
                    height: 180,
                  ),
                  
                  const Spacer(flex: 1),
                  
                  // This invisible layout mimics the element heights of the Welcome screen
                  // locking the logo in the exact same pixel position during transition
                  Opacity(
                    opacity: 0.0,
                    child: Column(
                      children: [
                        const Text(
                          "Welcome to BDU E-Learning App",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Learn Anytime, Anywhere",
                          style: TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 40),
                        Container(height: 55), // Button height
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      );
    } else if (_token == null) {
      child = const WelcomeScreen(key: ValueKey('welcome'));
    } else if (_role == 'instructor') {
      child = const InstructorDashboard(key: ValueKey('instructor'));
    } else if (_role == 'student') {
      child = const StudentDashboard(key: ValueKey('student'));
    } else {
      child = const WelcomeScreen(key: ValueKey('welcome_fallback'));
    }

    // Add AnimatedSwitcher for a smooth cross-fade transition
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 800),
      child: child,
    );
  }
}