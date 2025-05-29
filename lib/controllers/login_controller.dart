// controllers/login_controller.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../screens/welcome_screen.dart';

class LoginController {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool obscurePassword = true;
  bool isButtonDisabled = false;

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
  }

 Future<bool> handleLogin(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email and password cannot be empty')),
      );
      return false;
    }

    try {
      final result = await AuthService.login(email: email, password: password);
  
      // Save user data and token
      await SessionService.saveSession(
        token: result['data']['token'],
        email: result['data']['email'],
        divisi: result['data']['divisi'],
        id : result['data']['id'].toString(),
        jenisUser :  result['data']['jenis_user'],
        name :  result['data']['name']
      );
      // // Navigate to welcome screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => WelcomeScreen(name: result['data']['name']),
        ),
      );
      return true;
    } catch (e) {
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      return false;
    }
  }
}

