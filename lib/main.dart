// main.dart
import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/session_service.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Untuk initializeDateFormatting

void main() async {
   
  WidgetsFlutterBinding.ensureInitialized();
    
  // Inisialisasi Intl
  await initializeDateFormatting('id_ID', null); 
  Intl.defaultLocale = 'id_ID';
  final tokenSession = await SessionService.getToken();
  final nameSession = await SessionService.getName();
  final divisiSession = await SessionService.getDivisi();
  runApp(SalesInformationSystemApp(
    initialRoute: tokenSession != null? '/welcome' : '/login',
    name: nameSession,
    divisi: divisiSession,
  ));
}

class SalesInformationSystemApp extends StatelessWidget {
  final String initialRoute;
  final String? name;
  final String? divisi;
  final String? jabatan;
  final String? email;
  final String? authToken;
  const SalesInformationSystemApp({
    super.key,
    required this.initialRoute,
    this.name,
    this.divisi,
    this.jabatan,
    this.email,
    this.authToken
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sales Information System',
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/welcome': (context) => WelcomeScreen(name: name ?? 'User' , divisi : divisi ?? '' ,authToken:  authToken ?? '',jabatan: jabatan ?? '', email: email ?? ''),
      },
    );
  }
}