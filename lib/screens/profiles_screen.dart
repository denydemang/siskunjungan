import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final Color primaryColor = const Color(0xFF004D40);
    final Color bgColor = const Color(0xFFF9FAFB);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(context, primaryColor),
              const SizedBox(height: 16),
              _buildInfoSection(context),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color primaryColor) {
    return Container(
      height: 180,
      width: double.infinity,
      color: primaryColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white.withOpacity(0.9),
            child: const Icon(Icons.person, size: 45, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            divisi,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _infoTile(Icons.badge_outlined, 'Nama Lengkap', name),
          _infoTile(Icons.work_outline, 'Divisi', divisi),
          _infoTile(Icons.account_tree_outlined, 'Jabatan', jabatan),
          _infoTile(Icons.email_outlined, 'Email', email),
          FutureBuilder(
            future: SessionService.getID(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              return _infoTile(
                  Icons.perm_identity, 'ID Pengguna', snapshot.data.toString());
            },
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 26, color: Colors.teal),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
