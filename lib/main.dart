import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/session_service.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // Untuk initializeDateFormatting
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi lokal format tanggal ke Indonesia
  await initializeDateFormatting('id_ID', null);
  Intl.defaultLocale = 'id_ID';

  // Ambil sesi
  final tokenSession = await SessionService.getToken();
  final nameSession = await SessionService.getName();
  final divisiSession = await SessionService.getDivisi();
  final jabatanSession = await SessionService.getJabatan();
  final emailSession = await SessionService.getEmail();

  runApp(SalesInformationSystemApp(
    initialRoute: tokenSession != null ? '/welcome' : '/login',
    name: nameSession,
    divisi: divisiSession,
    jabatan: jabatanSession,
    email: emailSession,
    authToken: tokenSession,
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
    this.authToken,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sales Information System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF1F3F6),
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF004D40),
          foregroundColor: Colors.white,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/welcome': (context) => WelcomeScreen(
              name: name ?? 'User',
              divisi: divisi ?? '',
              jabatan: jabatan ?? '',
              email: email ?? '',
              authToken: authToken ?? '',
            ),
      },
    );
  }
}
