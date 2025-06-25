import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sisflutterproject/screens/login_screen.dart';
import 'package:sisflutterproject/services/session_service.dart';

class ProfileScreen extends StatelessWidget {
  final String name;
  final String divisi;
  final String jabatan;
  final String email;

  const ProfileScreen({
    super.key,
    required this.name,
    required this.divisi,
    required this.jabatan,
    required this.email,
  });


  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF004D40);
    final accentColor = const Color(0xFFFFC107);

    return Scaffold(
      appBar: AppBar(
        title: Text('Profil',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundColor: accentColor.withOpacity(0.3),
              child: Icon(Icons.person, size: 60, color: primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            Text(
              divisi,
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
            ),
            const SizedBox(height: 30),
            ListTile(
              leading: const Icon(Icons.badge),
              title: const Text('Nama Lengkap'),
              subtitle: Text(name),
            ),
            ListTile(
              leading: const Icon(Icons.work),
              title: const Text('Divisi'),
              subtitle: Text(divisi),
            ),
            ListTile(
              leading: const Icon(Icons.accessibility_rounded),
              title: const Text('Jabatan'),
              subtitle: Text(jabatan),
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email'),
              subtitle: Text(email),
            ),
            FutureBuilder(
              future: SessionService.getID(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                return ListTile(
                  leading: const Icon(Icons.person_pin),
                  title: const Text('ID Pengguna'),
                  subtitle: Text(snapshot.data.toString()),
                );
              },
            ),
            const Spacer()
          ],
        ),
      ),
    );
  }
}
