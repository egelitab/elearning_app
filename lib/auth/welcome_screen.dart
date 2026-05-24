import 'package:flutter/material.dart';
import 'register_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  // Controls which screen state to show (0: Splash, 1: Get Started, 2: Auth Buttons)
  int _step = 0;

  @override
  void initState() {
    super.initState();
    // Defaulting directly to 'Get Started' screen (Step 1)
    _step = 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // 2. Blue Gradient Overlay (to match the screenshot's tint)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.withOpacity(0.5),
                  Colors.blue.shade900.withOpacity(0.8),
                ],
              ),
            ),
          ),

          // 3. Content UI
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  
                  // Central Logo
                  Image.asset(
                    'assets/logo.png', 
                    height: 180,
                  ),
                  
                  const Spacer(flex: 2),

                  // Step 1 Content: Welcome Text & Get Started
                  if (_step == 1) ...[
                    const Text(
                      "Welcome to BDU E-Learning App",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Learn Anytime, Anywhere",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 40),
                    _buildButton(
                      text: "Get Started",
                      isPrimary: false,
                      showArrow: true,
                      onTap: () => setState(() => _step = 2),
                    ),
                  ],

                  // Step 2 Content: Register & Login Buttons
                  if (_step == 2) ...[
                    _buildButton(
                      text: "Register",
                      isPrimary: true,
                      showArrow: false,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildButton(
                      text: "Log In",
                      isPrimary: false,
                      showArrow: true,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Custom Button Builder to match your screenshot design
  Widget _buildButton({
    required String text,
    required bool isPrimary,
    required bool showArrow,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 55,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: isPrimary ? null : Colors.white,
          gradient: isPrimary 
              ? const LinearGradient(colors: [Color(0xFF64B5F6), Color(0xFF1976D2)]) 
              : null,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  text,
                  style: TextStyle(
                    color: isPrimary ? Colors.white : const Color(0xFF1976D2),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            if (showArrow)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF1976D2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              ),
          ],
        ),
      ),
    );
  }
}