// main.dart
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/session_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
   
  WidgetsFlutterBinding.ensureInitialized();
  
  final tokenSession = await SessionService.getToken();
  final nameSession = await SessionService.getName();
  await dotenv.load(fileName: ".env");
  runApp(SalesInformationSystemApp(
    initialRoute: tokenSession != null? '/welcome' : '/login',
    name: nameSession,
  ));
}

class SalesInformationSystemApp extends StatelessWidget {
  final String initialRoute;
  final String? name;
  const SalesInformationSystemApp({
    super.key,
    required this.initialRoute,
    this.name,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sales Information System',
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/welcome': (context) => WelcomeScreen(name: name ?? 'User'),
      },
    );
  }
}