
import 'package:flutter/material.dart';
import 'package:sisflutterproject/services/auth_service.dart';
import '../screens/login_screen.dart';
import '../services/session_service.dart';



class DashboardController {
  
  void showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Log Out'),
          content: const Text('You Will Be Logged Out!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () async {
                handleLogout(context);
              },
              child: const Text(
                'Log Out',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> handleLogout(BuildContext context) async {
  // Show loading dialog
  showDialog(
    context: context,
    barrierDismissible: false, // Prevent user from dismissing by tapping outside
    builder: (BuildContext context) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    },
  );

  String? email = await SessionService.getEmail();
  String? token = await SessionService.getToken();

  try {
    final response = await AuthService.logout(token: token, email: email);
    // Pop the loading dialog
    Navigator.of(context, rootNavigator: true).pop();
    
    if (response.containsKey("success")) {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (Route<dynamic> route) => false
        );
    }
  await SessionService.clearSession();
  } catch (e) {
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LoginScreen(),
        ),
      );
    await SessionService.clearSession();
  } 
}

}