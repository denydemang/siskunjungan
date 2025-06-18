import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sisflutterproject/screens/history_visit_screen.dart';
import 'package:sisflutterproject/screens/login_screen.dart';
import 'package:sisflutterproject/services/session_service.dart';
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
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session Habis')),
        );
        await SessionService.clearSession();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        await SessionService.clearSession();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Gagal memuat data leaderboard: $e';
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
      await SessionService.clearSession();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()),
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
        Uri.parse(
            'https://fakelocation.warungkode.com/api/kunjungan/group/${idUser}'),
        headers: {
          'Authorization': widget.authToken,
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          dailyweeklyData = jsonResponse;
          isLoading = false;
        });
      } else {
        await SessionService.clearSession();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Gagal memuat data leaderboard: $e';
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
      await SessionService.clearSession();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()),
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
      body: Container(
        padding: const EdgeInsets.all(20),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
                ? Center(child: Text(errorMessage))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SELAMAT DATANG ! ',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _accentColor,
                        ),
                      ),
                      Text(
                        '${widget.name} (${widget.divisi})',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Divider(
                          color: _primaryColor.withOpacity(0.3), thickness: 1),
                      const SizedBox(height: 20),

                      // Leaderboard Section
                      Row(
                        children: [
                          Icon(Icons.leaderboard,
                              color: _accentColor, size: 28),
                          const SizedBox(width: 10),
                          Text(
                            'Leaderboard $currentMonthYear',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: leaderboardData.length,
                          itemBuilder: (context, index) {
                            final data = leaderboardData[index];
                            final rank = index + 1;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildLeaderItem(data, rank),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 30),
                      Divider(
                          color: _primaryColor.withOpacity(0.3), thickness: 1),
                      const SizedBox(height: 20),

                      // My Visits Section
                      Row(
                        children: [
                          Icon(Icons.place, color: _accentColor, size: 28),
                          const SizedBox(width: 10),
                          const Text(
                            'KUNJUNGAN SAYA',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildDailyMonthlyItem(
                        name: widget.name,
                        department: widget.divisi,
                        visits: dailyweeklyData.isNotEmpty
                            ? dailyweeklyData[0]
                            : {
                                "daily_visits": '0',
                                "weekly_visits": '0',
                                "monthly_visits": '0'
                              },
                        isHighlighted: true,
                      ),
                    ],
                  ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildLeaderItem(data, int rank) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            spreadRadius: 0.5,
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _getRankColor(rank),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Nama + Mahkota (untuk rank 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      data['name'] ?? 'No Name',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (rank == 1)
                    Icon(
                      FontAwesomeIcons.crown,
                      color: _accentColor,
                      size: 25,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                data['divisi'] ?? 'No Division',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.place, color: _primaryColor, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${data['jmlh']} Kunjungan',
                    style: TextStyle(color: _primaryColor),
                  ),
                ],
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyMonthlyItem({
    required String name,
    required String department,
    required Map<String, dynamic> visits,
    bool isHighlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted ? _primaryColor.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted ? _primaryColor : Colors.grey.shade300,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: _secondaryColor,
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isHighlighted ? _primaryColor : Colors.black,
                      ),
                    ),
                    Text(
                      department,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildVisitStat("Harian", visits['daily_visits'].toString(),
                  Icons.calendar_today),
              _buildVisitStat("Mingguan", visits['weekly_visits'].toString(),
                  Icons.calendar_month),
              _buildVisitStat("Bulan Ini", visits['monthly_visits'].toString(),
                  Icons.calendar_view_month),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisitStat(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: _primaryColor, size: 18),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: _primaryColor,
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
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History Visit'),
        BottomNavigationBarItem(
            icon: Icon(Icons.place_outlined),
            activeIcon: Icon(Icons.place),
            label: 'Visit'),
        BottomNavigationBarItem(
            icon: Icon(Icons.logout_outlined),
            activeIcon: Icon(Icons.logout),
            label: 'Log Out'),
      ],
      currentIndex: _currentIndex,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: _primaryColor,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      elevation: 8,
      backgroundColor: Colors.white,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
      onTap: (index) => _handleBottomNavTap(context, index),
    );
  }

  void _handleBottomNavTap(BuildContext context, int index) {
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const HistoryVisitScreen()),
        ).then((value) {
          setState(() {
            _currentIndex = 0;
          });
          _fetchLeaderboardData();
          _fetchWeeklyMonthlyData();
        });
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VisitScreen()),
        ).then((value) {
          setState(() {
            _currentIndex = 0;
          });
          _fetchLeaderboardData();
          _fetchWeeklyMonthlyData();
        });
        break;
      case 3:
        widget._dashboardController.showLogoutConfirmation(context);
        break;
    }
  }
}
