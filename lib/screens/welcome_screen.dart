// screens/welcome_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:sisflutterproject/screens/login_screen.dart';
import 'package:sisflutterproject/services/session_service.dart';
import 'dart:convert';

import '../controllers/dashboard_controller.dart';
import '../screens/visit_screen.dart';

class WelcomeScreen extends StatefulWidget {
  final String name;
  final String divisi;
  final String authToken; // Add auth token parameter
  final DashboardController _dashboardController = DashboardController();

  WelcomeScreen({
    super.key, 
    required this.name, 
    required this.divisi,
    required this.authToken,
  });

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int _currentIndex = 0;
  final Color _primaryColor = const Color(0xFF00897B);
  final Color _secondaryColor = const Color(0xFF4DB6AC);
  final Color _accentColor = const Color(0xFFFFA000);
  
  List<dynamic> leaderboardData = [];
  List<dynamic> dailyweeklyData = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchLeaderboardData();
    _fetchWeeklyMonthlyData();
  }

  Future<void> _fetchLeaderboardData() async {

    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final response = await http.get(
        Uri.parse('https://fakelocation.warungkode.com/api/kunjungan/top'),
        headers: {
        'Authorization': widget.authToken,
        'Accept': 'application/json',
        },
      );
      // print(widget.authToken);
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == 'Successfully Get Data Top Kunjungan') {
          setState(() {
            leaderboardData = jsonResponse['data'];
            isLoading = false;
          });
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        await SessionService.clearSession();
         Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LoginScreen(),
        ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Gagal memuat data leaderboard: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      await SessionService.clearSession();
         Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LoginScreen(),
        ),
        );
    }
  }

    Future<void> _fetchWeeklyMonthlyData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });
      String? idUser = await SessionService.getID();
      final response = await http.get(
        Uri.parse('https://fakelocation.warungkode.com/api/kunjungan/group/${idUser}'),
        headers: {
        'Authorization': widget.authToken,
        'Accept': 'application/json',
        },
      );
      // print(widget.authToken);
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          dailyweeklyData = jsonResponse;
          isLoading = false;
        });
      
      } else {
        await SessionService.clearSession();
         Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LoginScreen(),
        ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Gagal memuat data leaderboard: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      await SessionService.clearSession();
         Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LoginScreen(),
        ),
        );
    }
  }


  String get currentMonthYear {
    final now = DateTime.now();
    final monthName = DateFormat('MMMM').format(now);
    final year = DateFormat('yyyy').format(now);
    
    final idMonths = {
      'January': 'Januari',
      'February': 'Februari',
      'March': 'Maret',
      'April': 'April',
      'May': 'Mei',
      'June': 'Juni',
      'July': 'Juli',
      'August': 'Agustus',
      'September': 'September',
      'October': 'Oktober',
      'November': 'November',
      'December': 'Desember'
    };
    
    return '${idMonths[monthName] ?? monthName} $year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SELAMAT DATANG ! ',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _accentColor,
                          shadows: [
                            Shadow(
                              blurRadius: 2,
                              color: Colors.black.withOpacity(0.1),
                              offset: const Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${widget.name} (${widget.divisi})',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                          shadows: [
                            Shadow(
                              blurRadius: 2,
                              color: Colors.black.withOpacity(0.1),
                              offset: const Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Divider(color: _primaryColor.withOpacity(0.2), thickness: 1),
                      const SizedBox(height: 20),

                      // Leaderboard Section
                      Row(
                        children: [
                          Icon(Icons.leaderboard, color: _accentColor, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'Leaderboard $currentMonthYear',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ...leaderboardData.asMap().entries.map((entry) {
                        final index = entry.key;
                        final data = entry.value;
                        return Column(
                          children: [
                            _buildLeaderItem(
                              name: data['name'] ?? 'No Name',
                              department: data['divisi'] ?? 'No Division',
                              visits: '${data['jmlh'] ?? 0} Kunjungan',
                              rank: index + 1,
                            ),
                            if (index < leaderboardData.length - 1)
                              const SizedBox(height: 12),
                          ],
                        );
                      }),
                      const SizedBox(height: 30),
                      Divider(color: _primaryColor.withOpacity(0.2), thickness: 1),
                      const SizedBox(height: 20),

                      // My Visits Section
                      Row(
                        children: [
                          Icon(Icons.place, color: _accentColor, size: 24),
                          const SizedBox(width: 8),
                          Text(
                            'KUNJUNGAN SAYA',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDailyMonthlyItem(
                        name: widget.name,
                        department: widget.divisi,
                        visits:  dailyweeklyData.length > 0 ? dailyweeklyData[0] : {"daily_visits" : '0' ,"weekly_visits" : '0' ,"monthly_visits" : '0' }, // You can add API for my visits later
                        isHighlighted: true,
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildLeaderItem({
    required String name,
    required String department,
    required String visits,
    int? rank,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted ? _primaryColor.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? _primaryColor : Colors.grey[200]!,
          width: isHighlighted ? 1.5 : 1,
        ),
        boxShadow: [
          if (!isHighlighted)
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (rank != null)
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
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
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isHighlighted ? _primaryColor : Colors.black,
                    ),
                  ),
                ),
              ],
            )
          else
            Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isHighlighted ? _primaryColor : Colors.black,
              ),
            ),
          const SizedBox(height: 6),
          const SizedBox(height: 8),
          Text(
            department,
            style: TextStyle(
              color: isHighlighted ? _primaryColor : Colors.grey[800],
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                visits,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isHighlighted ? _primaryColor : Colors.black,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

    Widget _buildDailyMonthlyItem({
     required String name,
    required String department,
    required Map<String, dynamic> visits, // e.g., {'daily': '10', 'weekly': '50', 'monthly': '200'}
    int? rank,
    bool isHighlighted = false,
  }) {
    final nameText = Text(
    name,
    style: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16,
      color: isHighlighted ? _primaryColor : Colors.black,
    ),
  );

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: isHighlighted ? _primaryColor.withOpacity(0.1) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isHighlighted ? _primaryColor : Colors.grey[200]!,
        width: isHighlighted ? 1.5 : 1,
      ),
      boxShadow: [
        if (!isHighlighted)
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rank != null)
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
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
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: nameText),
            ],
          )
        else
          nameText,
        const SizedBox(height: 12),
        Text(
          department,
          style: TextStyle(
            color: isHighlighted ? _primaryColor : Colors.grey[800],
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildVisitStat("Daily", visits['daily_visits'].toString(), isHighlighted),
            _buildVisitStat("Weekly", visits['weekly_visits'].toString(), isHighlighted),
            _buildVisitStat("Monthly", visits['monthly_visits'].toString(), isHighlighted),
          ],
        ),
      ],
    ),
  );
  }

  Widget _buildVisitStat(String label, String value, bool isHighlighted) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        '(${label})',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isHighlighted ? _primaryColor : Colors.black,
          fontSize: 14,
        ),
      ),
    ],
  );
}

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return _accentColor;
      case 2:
        return Colors.blueGrey;
      case 3:
        return Colors.brown;
      default:
        return _secondaryColor;
    }
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home, color: _primaryColor),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.place_outlined),
          activeIcon: Icon(Icons.place, color: _primaryColor),
          label: 'Visit',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.logout_outlined),
          activeIcon: Icon(Icons.logout, color: _primaryColor),
          label: 'Log Out',
        ),
      ],
      currentIndex: _currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: _primaryColor,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      elevation: 8,
      backgroundColor: Colors.white,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
      onTap: (index) => _handleBottomNavTap(context, index),
    );
  }

  void _handleBottomNavTap(BuildContext context, int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0: // Home
        break;
      
      case 1: // Visit
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VisitScreen()),
        );
        break;
        
      case 2: // Log Out
        widget._dashboardController.showLogoutConfirmation(context);
        break;
    }
  }
}