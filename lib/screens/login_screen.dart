import 'package:flutter/material.dart';
import '../controllers/login_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final controller = LoginController();
  bool _isLoading = false;
  Future<void> _handleLogin() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    final response = await controller.handleLogin(context);

    if(!response || response){

    setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                const Text('Sales Information',
                    style: TextStyle(fontSize: 20, color: Colors.teal)),
                const Text('System',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal)),
                const SizedBox(height: 48),
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Welcome Back!',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16))),
                const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                        'Enter the email and password that has been\nYou register it in advance.',
                        style: TextStyle(color: Colors.grey))),
                const SizedBox(height: 24),
                TextField(
                  controller: controller.emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller.passwordController,
                  obscureText: controller.obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(controller.obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          controller.togglePasswordVisibility();
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text('Forgot Password?',
                            style: TextStyle(color: Colors.grey)))),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isLoading ? null : _handleLogin,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Login',
                              style: TextStyle(
                                  fontSize: 18, color: Colors.white))),
                ),
                const Spacer(),
                const Padding(
                  padding: EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    'By logging in or registering, you agree to our Terms of Service and Privacy Policy',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
