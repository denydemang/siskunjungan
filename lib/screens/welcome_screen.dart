import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sisflutterproject/screens/history_visit_screen.dart';
import 'package:sisflutterproject/screens/login_screen.dart';
import 'package:sisflutterproject/screens/profiles_screen.dart';
import 'package:sisflutterproject/screens/visit_screen.dart';
import 'package:sisflutterproject/services/session_service.dart';
import '../controllers/dashboard_controller.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';

class WelcomeScreen extends StatefulWidget {
  final String name;
  final String divisi;
  final String jabatan;
  final String email;
  final String authToken;
  final DashboardController _dashboardController = DashboardController();

  WelcomeScreen({
    super.key,
    required this.name,
    required this.divisi,
    required this.jabatan,
    required this.email,
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
  String? jabatan;

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
      await SessionService.clearSession();
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()));
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
      jabatan = await SessionService.getJabatan();
      String? userId = await SessionService.getID();
      
      var user_pmr = null;
      var user_mgm = null;
      var idUser = null;

      switch (jabatan) {
        case 'PMR':
          user_pmr = userId;
          break;
        case 'MGM':
          user_mgm = userId;
          break;
        default:
          idUser = userId;
      }
      final response = await http.get(
        Uri.https(
        'fakelocation.warungkode.com',
        '/api/kunjungan/group',
        {
          if (user_pmr != null) 'user_pmr': user_pmr,
          if (user_mgm != null) 'user_mgm': user_mgm,
          if (idUser != null) 'user_id': idUser,
        }
        ),
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
      await SessionService.clearSession();
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()));
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
          if (widget.jabatan != 'PMR') const VisitScreen(),
          ProfileScreen(
            name: widget.name,
            email: widget.email,
            jabatan: widget.jabatan,
            divisi: widget.divisi,
          ),
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
        items: [
          TabItem(icon: Icons.home, title: 'Home'),
          TabItem(icon: Icons.history, title: 'History'),
          if (widget.jabatan != 'PMR')
            TabItem(icon: Icons.place, title: 'Visit'),
          TabItem(icon: Icons.person, title: 'Profile'),
          TabItem(icon: Icons.logout, title: 'Logout'),
        ],
      ),
    );
  }

  void _handleBottomTap(int index) {
    int decrease = 0;
    if (!(widget.jabatan != 'PMR')) {
      decrease = 1;
    }
    if (index == (4 - decrease)) {
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
                jabatan == 'MGM' || jabatan == 'PMR'  ? _sectionHeader(Icons.place, 'Kunjungan Proyek Saya') : _sectionHeader(Icons.place, 'Kunjungan Saya'),
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
                const SizedBox(height: 24),
                _sectionHeader(Icons.newspaper, 'Berita Terbaru'),
                const SizedBox(height: 12),
                _newsSlider(),
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
          ? Colors.grey.shade400
          : rank == 3
              ? Colors.brown.shade400
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
    final isTop1 = position == 1;
    final isTop3 = position <= 3;

    final gradientColors = isTop1
        ? [Color.fromARGB(255, 235, 234, 229), Color(0xFFFFC107)]
        : isTop3
            ? [const Color.fromARGB(255, 255, 243, 243), Colors.grey.shade100]
            : [Color(0xFF1C1C2E), Color(0xFF1C1C2E)];

    final textColor = isTop3 ? Colors.black87 : Colors.white;
    final subTextColor = isTop3 ? Colors.black54 : Colors.grey[300];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (isTop3)
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white,
              ),
              if (position == 1 || position == 2 || position == 3)
                Icon(
                  FontAwesomeIcons.crown,
                  color: position == 1
                      ? Colors.amber
                      : position == 2
                          ? Colors.grey.shade400
                          : Colors.brown.shade400,
                  size: position == 1 ? 30 : 24,
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: subTextColor,
                  ),
                ),
              ],
            ),
          ),
          if (extra != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: position == 1
                    ? const Color.fromARGB(255, 255, 237, 179)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.directions_walk,
                    size: 16,
                    color: position == 1
                        ? const Color.fromARGB(255, 245, 7, 7)
                        : Colors.grey[700],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    extra!,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: position == 1
                          ? const Color.fromARGB(255, 255, 3, 3)
                          : Colors.black87,
                    ),
                  ),
                ],
              ),
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _statItem(
            "Harian",
            data['daily_visits'].toString(),
            Icons.calendar_today,
            color: Colors.blue.shade700,
          ),
          _statItem(
            "Mingguan",
            data['weekly_visits'].toString(),
            Icons.calendar_view_week,
            color: Colors.green.shade700,
          ),
          _statItem(
            "Bulan Ini",
            data['monthly_visits'].toString(),
            Icons.calendar_month,
            color: Colors.orange.shade700,
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String count, IconData icon,
      {required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      width: 90,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 6),
          Text(
            count,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _newsSlider() {
    final List<Map<String, String>> news = [
      {
        'image':
            'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=800&q=80',
        'title': 'Promo Diskon 50% Hari Ini!'
      },
      {
        'image':
            'https://images.unsplash.com/photo-1515377905703-c4788e51af15?auto=format&fit=crop&w=800&q=80',
        'title': 'Event Gathering Karyawan 2024'
      },
      {
        'image':
            'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?auto=format&fit=crop&w=800&q=80',
        'title': 'Update Sistem Terbaru Sudah Rilis'
      },
      {
        'image':
            'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?auto=format&fit=crop&w=800&q=80',
        'title': 'Tips & Trik Kerja Efektif'
      },
    ];

    return SizedBox(
      height: 180,
      child: PageView.builder(
        itemCount: news.length,
        controller: PageController(viewportFraction: 0.85),
        itemBuilder: (context, index) {
          final item = news[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: NetworkImage(item['image']!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.4),
                  BlendMode.darken,
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  item['title']!,
                  style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.7),
                          offset: const Offset(0, 1),
                          blurRadius: 3,
                        ),
                      ]),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
