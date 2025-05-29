// screens/welcome_screen.dart
import 'package:flutter/material.dart';
import '../controllers/dashboard_controller.dart';
import '../screens/visit_screen.dart';



class WelcomeScreen extends StatefulWidget {
  final String name;
  final DashboardController _dashboardController = DashboardController();

  WelcomeScreen({super.key, required this.name});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Text(
              'Halo, ${widget.name}!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Apa yang mau kamu cari hari ini?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 30),

            // Leaderboard Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Leaderboard 2025',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildLeaderboardCard(
                    rank: 1,
                    title: 'Buana Cicalengka Raya',
                    description: 'Business Panel Information',
                    department: 'Marketing',
                    amount: 'Rp 30.000.000.000',
                    growth: '▲ 1,100',
                  ),
                  const SizedBox(height: 16),
                  _buildLeaderboardCard(
                    rank: 2,
                    title: 'Buana Cicalengka Raya',
                    description: 'Business Panel Information',
                    department: 'Marketing',
                    amount: 'Rp 20.000.000.000',
                    growth: '▲ 1,100',
                  ),
                  const SizedBox(height: 16),
                  _buildLeaderboardCard(
                    rank: 3,
                    title: 'Buana Cicalengka Raya',
                    description: 'Business Panel Information',
                    department: 'Marketing',
                    amount: 'Rp 10.000.000.000',
                    growth: '▲ 1,100',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildLeaderboardCard({
    required int rank,
    required String title,
    required String description,
    required String department,
    required String amount,
    required String growth,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _getRankColor(rank),
              shape: BoxShape.circle,
            ),
            child: Text(
              rank.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(description),
                const SizedBox(height: 4),
                Text(
                  department,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      amount,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      growth,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber[700]!;
      case 2:
        return Colors.blueGrey[400]!;
      case 3:
        return Colors.brown[400]!;
      default:
        return Colors.teal;
    }
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.place_outlined),
          activeIcon: Icon(Icons.place),
          label: 'Visit',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.logout_outlined),
          activeIcon: Icon(Icons.logout),
          label: 'Log Out',
        ),
      ],
      currentIndex: _currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.teal,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      elevation: 5,
      onTap: (index) => _handleBottomNavTap(context, index),
    );
  }

  void _handleBottomNavTap(BuildContext context, int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0: // Home
        // Tidak perlu navigasi jika sudah di home
        break;
      
      case 1: // Visit
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VisitScreen()),
        );
        break;
        
      case 2: // Log Out
        widget._dashboardController.showLogoutConfirmation(context);
  // Pindahkan logika setelah konfirmasi ke dalam controller
        break;
    }
  }
}