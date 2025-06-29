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
        Uri.parse('https://apivn.internalbkg.com/api/kunjungan/top'),
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
        Uri.https('apivn.internalbkg.com', '/api/kunjungan/group', {
          if (user_pmr != null) 'user_pmr': user_pmr,
          if (user_mgm != null) 'user_mgm': user_mgm,
          if (idUser != null) 'user_id': idUser,
        }),
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

  // (kode yang sama seperti sebelumnya sampai _homeContent)

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
                _buildPodium(leaderboardData),
                const SizedBox(height: 20),
                jabatan == 'MGM' || jabatan == 'PMR'
                    ? _sectionHeader(Icons.place, 'Kunjungan Proyek Saya')
                    : _sectionHeader(Icons.place, 'Kunjungan Saya'),
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
                // _sectionHeader(Icons.newspaper, 'Berita Terbaru'),
                // const SizedBox(height: 12),
                // _newsSlider(),
              ],
            ),
          );
  }

  Widget _buildPodium(List data) {
    if (data.isEmpty) return const Text('Belum ada data leaderboard.');

    Widget _userBox(int index, double height, Color color,
        {bool isCenter = false}) {
      final user = data.length > index ? data[index] : null;
      final rank = index + 1;

      return Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (rank == 1)
              Icon(
                FontAwesomeIcons.crown,
                color: Colors.amber.shade700,
                size: 36,
                shadows: [
                  Shadow(color: Colors.amber.withOpacity(0.5), blurRadius: 10),
                ],
              ),
            Padding(
              padding: EdgeInsets.only(top: rank == 1 ? 8 : 12),
              child: CircleAvatar(
                radius: isCenter ? 28 : 24,
                backgroundColor: Colors.grey.shade200,
                child: Icon(
                  Icons.person,
                  size: isCenter ? 26 : 22,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              user != null ? user['name'] : '-',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            Text(
              user != null ? user['divisi'] : '',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              height: height,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: rank == 1
                      ? [Color(0xFFFFD740), Color(0xFFFFD740)]
                      : rank == 2
                          ? [Colors.grey.shade400, Colors.grey.shade400]
                          : [Colors.brown.shade400, Colors.brown.shade400],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                boxShadow: [
                  if (rank == 1)
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.5),
                      blurRadius: 16,
                      spreadRadius: 3,
                      offset: Offset(0, 0),
                    ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_walk,
                      color: Colors.white, size: isCenter ? 20 : 16),
                  const SizedBox(height: 2),
                  Text(
                    user != null ? '${user['jmlh']}' : '0',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.only(top: 32, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Label Top 3
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Align(
              alignment: Alignment.topRight,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.4),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(FontAwesomeIcons.crown,
                        color: Colors.amber.shade800, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Top 3 Rank',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.amber.shade900,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 4,
                            offset: Offset(1, 1),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _userBox(1, 76, Colors.grey.shade400),
              _userBox(0, 100, Colors.amber.shade600, isCenter: true),
              _userBox(2, 50, Colors.brown.shade400),
            ],
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.teal.shade100, thickness: 1),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '🔥 Ayo kejar posisi! Jadilah bagian dari 3 besar leaderboard bulan ini dan buktikan performa terbaikmu!',
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: Colors.teal.shade800,
              ),
              textAlign: TextAlign.center,
            ),
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
    final bool isTop1 = position == 1;
    final bool isTop2 = position == 2;
    final bool isTop3 = position == 3;

    final List<Color> gradientColors = isTop1
        ? [Colors.white, const Color(0xFFFFF59D)]
        : isTop2
            ? [Colors.white, Colors.grey.shade300]
            : isTop3
                ? [Colors.white, Colors.brown.shade100]
                : [Colors.white, Colors.white];

    final Color textColor = Colors.black87;
    final Color subTextColor = Colors.grey.shade600;

    final Color crownBgColor = isTop1
        ? Colors.amber
        : isTop2
            ? Colors.grey
            : isTop3
                ? Colors.brown
                : Colors.transparent;

    final Color extraColor = isTop1
        ? Colors.amber.shade800
        : isTop2
            ? Colors.grey.shade700
            : isTop3
                ? Colors.brown.shade700
                : Colors.grey.shade600;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            // Avatar + Crown
            Stack(
              alignment: Alignment.topRight,
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey[100],
                  child: leading,
                ),
                if (position <= 3)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: crownBgColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: crownBgColor.withOpacity(0.5),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: const Icon(
                        FontAwesomeIcons.crown,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Title + Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: subTextColor,
                    ),
                  ),
                ],
              ),
            ),
            // Jumlah kunjungan
            if (extra != null) ...[
              const SizedBox(width: 12),
              Row(
                children: [
                  Icon(Icons.directions_walk_rounded,
                      size: 18, color: extraColor),
                  const SizedBox(width: 4),
                  Text(
                    extra!,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: extraColor,
                    ),
                  ),
                ],
              )
            ],
          ],
        ),
      ),
    );
  }

  Widget _visitCard({
    required String name,
    required String divisi,
    required Map<String, dynamic> data,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE0F2F1), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.zero,
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text(
          //   'Halo, $name 👋',
          //   style: GoogleFonts.poppins(
          //     fontSize: 16,
          //     fontWeight: FontWeight.bold,
          //     color: const Color(0xFF004D40),
          //   ),
          // ),
          // Text(
          //   'Divisi: $divisi',
          //   style: GoogleFonts.poppins(
          //     fontSize: 13,
          //     color: Colors.grey[700],
          //   ),
          // ),
          const SizedBox(height: 12),
          Text(
            "📊 Berikut ringkasan kunjungan kamu:",
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.teal.shade800,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _statItem(
                "Harian",
                data['daily_visits'].toString(),
                Icons.calendar_today_rounded,
                color: Colors.blueAccent,
                badgeText: "👍 Bagus!",
              ),
              _statItem(
                "Mingguan",
                data['weekly_visits'].toString(),
                Icons.calendar_view_week_rounded,
                color: Colors.teal,
                badgeText: "⬆️ Naik!",
              ),
              _statItem(
                "Bulan Ini",
                data['monthly_visits'].toString(),
                Icons.calendar_month_rounded,
                color: Colors.deepOrangeAccent,
                badgeText: "🔥 Produktif",
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String count, IconData icon,
      {required Color color, String? badgeText}) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [color.withOpacity(0.2), color.withOpacity(0.05)],
                  center: Alignment.center,
                  radius: 0.9,
                ),
              ),
              child: Center(
                child: Icon(icon, size: 26, color: color),
              ),
            ),
            if (badgeText != null)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badgeText,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          count,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
      ],
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
              borderRadius: BorderRadius.circular(0),
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
