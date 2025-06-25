import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sisflutterproject/screens/history_visit_screen.dart';
import 'package:sisflutterproject/screens/login_screen.dart';
import 'package:sisflutterproject/screens/visit_screen.dart';
import 'package:sisflutterproject/services/session_service.dart';
import '../controllers/dashboard_controller.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';

class WelcomeScreen extends StatefulWidget {
  final String name;
  final String divisi;
  final String authToken;
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
  final Color _primaryColor = const Color(0xFF004D40);
  final Color _secondaryColor = const Color(0xFF01462B);
  final Color _accentColor = const Color(0xFFFFC107);
  final Color _cardColor = Colors.white;
  final Color _bgColor = const Color(0xFFF1F3F6);

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
          'Accept': 'application/json'
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
      } else {
        await SessionService.clearSession();
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => LoginScreen()));
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Gagal memuat data leaderboard: $e';
      });
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
            'https://fakelocation.warungkode.com/api/kunjungan/group/$idUser'),
        headers: {
          'Authorization': widget.authToken,
          'Accept': 'application/json'
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
            MaterialPageRoute(builder: (context) => LoginScreen()));
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Gagal memuat data: $e';
      });
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: _currentIndex == 0
          ? AppBar(
              elevation: 0,
              backgroundColor: _primaryColor,
              foregroundColor: Colors.white,
              title: Text('Dashboard',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
              centerTitle: true,
            )
          : null, // AppBar hanya muncul saat Home (index 0)
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _homeContent(),
          const HistoryVisitScreen(),
          const VisitScreen(),
          Container(), // Logout dummy
        ],
      ),
      bottomNavigationBar: ConvexAppBar(
        style: TabStyle.reactCircle,
        backgroundColor: _primaryColor,
        activeColor: Colors.white,
        color: Colors.grey[300],
        initialActiveIndex: _currentIndex,
        onTap: _handleBottomTap,
        items: const [
          TabItem(icon: Icons.home, title: 'Home'),
          TabItem(icon: Icons.history, title: 'History'),
          TabItem(icon: Icons.place, title: 'Visit'),
          TabItem(icon: Icons.logout, title: 'Logout'),
        ],
      ),
    );
  }

  void _handleBottomTap(int index) {
    if (index == 3) {
      widget._dashboardController.showLogoutConfirmation(context);
    } else {
      setState(() => _currentIndex = index);
    }
  }

  Widget _homeContent() {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () async {
              await _fetchLeaderboardData();
              await _fetchWeeklyMonthlyData();
            },
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _sectionHeader(
                    Icons.leaderboard, 'Leaderboard $currentMonthYear'),
                const SizedBox(height: 12),
                ...leaderboardData.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final data = entry.value;
                  return _card(
                    title: data['name'],
                    subtitle: data['divisi'],
                    trailing: idx == 0
                        ? Icon(FontAwesomeIcons.crown, color: _accentColor)
                        : null,
                    leading: CircleAvatar(
                      backgroundColor: _getRankColor(idx + 1),
                      child: Text('${idx + 1}',
                          style: const TextStyle(color: Colors.white)),
                    ),
                    extra: '${data['jmlh']} Kunjungan',
                    position: idx + 1,
                  );
                }),
                const SizedBox(height: 20),
                _sectionHeader(Icons.place, 'Kunjungan Saya'),
                const SizedBox(height: 12),
                _visitCard(
                  name: widget.name,
                  divisi: widget.divisi,
                  data: dailyweeklyData.isNotEmpty
                      ? dailyweeklyData[0]
                      : {
                          "daily_visits": '0',
                          "weekly_visits": '0',
                          "monthly_visits": '0'
                        },
                ),
              ],
            ),
          );
  }

  Widget _sectionHeader(IconData icon, String title) => Row(
        children: [
          Icon(icon, color: _secondaryColor),
          const SizedBox(width: 8),
          Text(title,
              style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor)),
        ],
      );

  Color _getRankColor(int rank) => rank == 1
      ? _accentColor
      : rank == 2
          ? Colors.blueGrey
          : rank == 3
              ? Colors.brown
              : _secondaryColor;

  Widget _card({
    required String title,
    required String subtitle,
    required Widget leading,
    Widget? trailing,
    String? extra,
    int position = 0,
    VoidCallback? onTap,
  }) {
    final isTopThree = position >= 1 && position <= 3;

    final gradientColors = position == 1
        ? [Color(0xFFFFD700), Color(0xFFFFC107)] // Gold
        : position == 2
            ? [Colors.grey.shade400, Colors.grey.shade200] // Silver
            : position == 3
                ? [Colors.brown.shade300, Colors.brown.shade100] // Bronze
                : [const Color(0xFF1C1C2E), const Color(0xFF1C1C2E)];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (isTopThree)
            const BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          // Ranking avatar + mahkota
          Stack(
            alignment: Alignment.topCenter,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white,
                child: Text(
                  '$position',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (position == 1)
                const Positioned(
                  top: -10,
                  child: Icon(
                    FontAwesomeIcons.crown,
                    color: Colors.amber,
                    size: 20,
                  ),
                ),
            ],
          ),

          const SizedBox(width: 16),

          // Nama dan divisi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),

          // Jumlah kunjungan & trailing
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (extra != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.redAccent, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        extra!,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              if (trailing != null) ...[
                const SizedBox(height: 6),
                trailing!,
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _visitCard({
    required String name,
    required String divisi,
    required Map<String, dynamic> data,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statItem(
              "Harian", data['daily_visits'].toString(), Icons.calendar_today),
          _statItem("Mingguan", data['weekly_visits'].toString(),
              Icons.calendar_month),
          _statItem("Bulan Ini", data['monthly_visits'].toString(),
              Icons.calendar_view_month),
        ],
      ),
    );
  }

  Widget _statItem(String label, String count, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 22, color: _primaryColor),
        const SizedBox(height: 4),
        Text(count,
            style:
                GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
