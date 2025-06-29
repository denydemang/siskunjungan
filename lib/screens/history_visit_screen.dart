import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:sisflutterproject/screens/login_screen.dart';
import 'package:sisflutterproject/services/session_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async'; // Untuk Timer

class HistoryVisitScreen extends StatefulWidget {
  const HistoryVisitScreen({Key? key}) : super(key: key);

  @override
  State<HistoryVisitScreen> createState() => _HistoryVisitScreenState();
}

class _HistoryVisitScreenState extends State<HistoryVisitScreen> {
  final Color _primaryColor = const Color(0xFF01462B);
  final Color _secondaryColor = const Color(0xFF4DB6AC);
  final Color _accentColor = const Color(0xFFFFA000);
  String jabatan = '';
  final TextEditingController _searchController = TextEditingController();
  String _searchKeyword = '';
  Timer? _searchDebounce;
  List<Kunjungan> kunjunganList = [];
  bool isLoading = true;
  bool isFetchingMore = false;
  bool hasMoreData = true;
  int currentPage = 1;
  final int perPage = 25;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchKunjunganData();
    _setupScrollController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _shareToWhatsApp(dynamic kunjungan) async {
    final message = '''
Kunjungan:
 🏗️ Project : ${kunjungan.nama_pro}
 😎 Nama Pengunjung: ${kunjungan.userKnj}
 📅 Tanggal : ${kunjungan.tglKnj}
 🧑‍💼 Pekerjaan : ${kunjungan.pekerjaanKnj}
 🎫 Kategori: ${kunjungan.kategoriKnj}
 🪛 Sumber: ${kunjungan.sumberKnj}
 📝 Hasil: ${kunjungan.hasilKnj}
''';

    final url = Uri.encodeFull('https://wa.me/?text=$message');
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal membuka WhatsApp")),
      );
    }
  }

  void _setupScrollController() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !isFetchingMore &&
          hasMoreData) {
        fetchMoreKunjunganData();
      }
    });
  }

  Future<void> fetchKunjunganData() async {
    setState(() {
      isLoading = true;
      currentPage = 1; // Always reset to page 1 when fetching new data
      hasMoreData = true;
    });

    try {
      final newData = await _fetchData(page: currentPage);

      setState(() {
        kunjunganList = newData;
        isLoading = false;
        if (newData.length < perPage) {
          hasMoreData = false;
        }
      });
    } catch (e) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) => false,
      );
      _showErrorSnackBar('Gagal memuat data kunjungan: $e');
    }
  }

  Future<void> fetchMoreKunjunganData() async {
    if (isFetchingMore || !hasMoreData) return;

    setState(() {
      isFetchingMore = true;
    });

    try {
      final nextPage = currentPage + 1;
      final newData = await _fetchData(page: nextPage);

      setState(() {
        if (newData.isNotEmpty) {
          kunjunganList.addAll(newData);
          currentPage = nextPage;
        }

        if (newData.length < perPage) {
          hasMoreData = false;
        }

        isFetchingMore = false;
      });
    } catch (e) {
      setState(() {
        isFetchingMore = false;
      });
      _showErrorSnackBar('Gagal memuat data tambahan: $e');
    }
  }

  Future<List<Kunjungan>> _fetchData({required int page}) async {
    final userId = await SessionService.getID();
    final token = await SessionService.getToken();
    jabatan = await SessionService.getJabatan() ?? '';
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
      case 'MKT':
        idUser = userId;
        break;
      default:
    }

    final url = Uri.https(
      'apivn.internalbkg.com',
      '/api/kunjungan/history',
      {
        if (user_pmr != null) 'user_pmr': user_pmr,
        if (user_mgm != null) 'user_mgm': user_mgm,
        if (idUser != null) 'iduser': idUser,
        'page': page.toString(),
        'perPage': perPage.toString(),
        if (_searchKeyword.isNotEmpty) 'keyword': _searchKeyword,
      },
    );
    print(url);
    final response = await http.get(
      url,
      headers: {'Authorization': token ?? ''},
    );
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final dataList = jsonData['data'] as List;
      return dataList.map((item) => Kunjungan.fromJson(item)).toList();
    } else if (response.statusCode == 401) {
      await SessionService.clearSession();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) => false,
      );
      return [];
    } else {
      throw Exception(
          'Failed to load data with status: ${response.statusCode}');
    }
  }

  void _onSearchChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (_searchKeyword != _searchController.text) {
        setState(() {
          _searchKeyword = _searchController.text;
        });
        fetchKunjunganData();
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _launchGoogleMaps(String latlong) async {
    if (latlong.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Koordinat tidak tersedia')),
      );
      return;
    }

    try {
      List<String> cleaned = latlong.split(',');
      if (cleaned.length != 2) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Format LatLong Invalid !',
                style: TextStyle(color: Colors.amber)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.pop(context);
                },
                child: const Text('OK', style: TextStyle(color: Colors.blue)),
              ),
            ],
          ),
        );
        return;
      }

      final double lat = double.parse(cleaned[0].trim());
      final double lng = double.parse(cleaned[1].trim());

      final Uri gmapsWebUri = Uri.parse(
          'https://www.google.com/maps/search/?api=1&query=$lat,$lng');

      if (await canLaunchUrl(gmapsWebUri)) {
        await launchUrl(gmapsWebUri, mode: LaunchMode.externalApplication);
        return;
      }

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Tidak Bisa Membuka Lokasi !',
              style: TextStyle(color: Colors.amber)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pop(context);
              },
              child: const Text('OK', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      );
    } catch (e) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Gagal Membuka Lokasi !',
              style: TextStyle(color: Colors.amber)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pop(context);
              },
              child: const Text('OK', style: TextStyle(color: Colors.blue)),
            ),
          ],
        ),
      );
    }
  }

  String _formatLatLong(String latlong) {
    if (latlong.trim().isEmpty) return '-';

    try {
      final parts = latlong
          .split(',')
          .map((e) => e.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      if (parts.length != 2) return '-';

      double.parse(parts[0]);
      double.parse(parts[1]);

      return latlong;
    } catch (e) {
      return '-';
    }
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: _primaryColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isNotEmpty ? value : '-',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showDetailDialog(BuildContext context, Kunjungan kunjungan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Title
                    const Text(
                      'Detail Kunjungan',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    // Foto dengan Loading Indicator dan tinggi dinamis
                    if (kunjungan.fotoKnj != null &&
                        kunjungan.fotoKnj!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.network(
                              kunjungan.fotoKnj!,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const SizedBox(
                                  height: 200,
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 200,
                                  alignment: Alignment.center,
                                  color: Colors.grey[200],
                                  child:
                                      const Text("Gambar tidak dapat dimuat"),
                                );
                              },
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        height: 200,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Tidak ada foto tersedia.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),

                    const SizedBox(height: 16),

                    // Informasi Detail
                    _buildDetailItem(
                        Icons.business, 'Project', kunjungan.namaPro),
                    _buildDetailItem(Icons.verified_user, 'Nama Pengunjung',
                        kunjungan.userKnj),
                    _buildDetailItem(
                        Icons.calendar_today, 'Tanggal', kunjungan.tglKnj),
                    _buildDetailItem(
                        Icons.work, 'Pekerjaan', kunjungan.pekerjaanKnj),
                    _buildDetailItem(
                        Icons.category, 'Kategori', kunjungan.kategoriKnj),
                    _buildDetailItem(
                        Icons.source, 'Sumber', kunjungan.sumberKnj),
                    _buildDetailItem(
                        Icons.edit_note, 'Hasil', kunjungan.hasilKnj),
                    _buildDetailItem(
                        Icons.access_time, 'Jam', kunjungan.jamDariCreatedAt),
                    _buildDetailItem(Icons.verified_user, 'Divisi Pengunjung',
                        kunjungan.divisiKnj),
                    _buildDetailItem(
                        Icons.abc, 'Nama Yang Dikunjungi', kunjungan.namaKnj),
                    _buildDetailItem(
                        Icons.location_on, 'Lokasi', kunjungan.lokasiKnj),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.pin_drop, size: 20, color: _primaryColor),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'LatLong',
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.black54),
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  onTap: () =>
                                      _launchGoogleMaps(kunjungan.latlongKnj),
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Row(
                                      children: [
                                        Text(
                                          _formatLatLong(kunjungan.latlongKnj),
                                          style: const TextStyle(
                                              fontSize: 16, color: Colors.blue),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(Icons.open_in_new,
                                            size: 16, color: _primaryColor),
                                      ],
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildDetailItem(
                        Icons.person, 'Kontak', kunjungan.kontakKnj),

                    const SizedBox(height: 16),

                    // Tombol Tutup
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton.icon(
                        onPressed: Navigator.of(context).pop,
                        icon: const Icon(Icons.close),
                        label: const Text('Tutup',
                            style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          minimumSize: Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          iconColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteKunjungan(int id) async {
    final token = await SessionService.getToken();
    final url = Uri.https(
      'apivn.internalbkg.com',
      '/api/kunjungan/delete/$id',
    );

    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': token ?? ''},
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kunjungan berhasil dihapus')),
        );
        fetchKunjunganData(); // Refresh data setelah hapus
      } else if (response.statusCode == 401) {
        await SessionService.clearSession();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        _showErrorSnackBar('Gagal menghapus kunjungan');
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History Kunjungan'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: fetchKunjunganData,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_primaryColor.withOpacity(0.05), Colors.white],
            ),
          ),
          child: Column(
            children: [
              // Tambahkan Search Bar di sini (Satu-satunya perubahan)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => _onSearchChanged(),
                    decoration: InputDecoration(
                      hintText: 'Cari kata kunci...',
                      prefixIcon: Icon(Icons.search, color: _primaryColor),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: _primaryColor),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
                    ),
                  ),
                ),
              ),

              // Bagian ini tetap sama persis seperti kode asli Anda
              Expanded(
                child: kunjunganList.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.8,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Text(
                                  _searchKeyword.isEmpty
                                      ? "Data Kunjungan Tidak Ditemukan"
                                      : "Tidak ditemukan hasil untuk '$_searchKeyword'",
                                  style: const TextStyle(
                                      fontSize: 18, color: Colors.black54),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            Expanded(
                              child: NotificationListener<ScrollNotification>(
                                onNotification: (scrollNotification) {
                                  if (scrollNotification
                                          is ScrollEndNotification &&
                                      _scrollController.position.pixels ==
                                          _scrollController
                                              .position.maxScrollExtent &&
                                      !isFetchingMore &&
                                      hasMoreData) {
                                    fetchMoreKunjunganData();
                                  }
                                  return false;
                                },
                                child: ListView.builder(
                                  controller: _scrollController,
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  itemCount: kunjunganList.length +
                                      (hasMoreData ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (index == kunjunganList.length) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16.0),
                                        child: Center(
                                          child: hasMoreData
                                              ? const CircularProgressIndicator(
                                                  color: Colors.teal)
                                              : const Text(
                                                  "Tidak ada data lagi",
                                                  style: TextStyle(
                                                      color: Colors.grey),
                                                ),
                                        ),
                                      );
                                    }

                                    final kunjungan = kunjunganList[index];
                                    return Card(
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 6),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 20,
                                                      backgroundColor:
                                                          _secondaryColor,
                                                      child: const Icon(
                                                        Icons.calendar_today,
                                                        size: 16,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          kunjungan.tglKnj,
                                                          style:
                                                              const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 16,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 4),
                                                        Text(
                                                          'Jam: ${kunjungan.jamDariCreatedAt}',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 13,
                                                            color:
                                                                Colors.black54,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                if (jabatan == 'ADM')
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: Colors.red[50],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      border: Border.all(
                                                          color:
                                                              Colors.red[100]!),
                                                    ),
                                                    child: IconButton(
                                                      onPressed: () =>
                                                          _showDeleteConfirmation(
                                                              kunjungan.idKnj,
                                                              kunjungan
                                                                  .namaKnj),
                                                      icon: Icon(
                                                          Icons.delete_outline,
                                                          color:
                                                              Colors.red[400]),
                                                      tooltip:
                                                          'Hapus Kunjungan',
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8),
                                                      constraints:
                                                          const BoxConstraints(),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                const Icon(Icons.business_outlined,
                                                    size: 16,
                                                    color: Colors.grey),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Nama Proyek : ${kunjungan.namaPro}',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                        fontSize: 14),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(Icons.verified_user_sharp,
                                                    size: 16,
                                                    color: Colors.grey),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Nama Marketing: ${kunjungan.userKnj}',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                        fontSize: 14),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Row(
                                              children: [
                                                const Icon(Icons.people_alt_sharp,
                                                    size: 16,
                                                    color: Colors.grey),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    'Nama yg Dikunjungi : ${kunjungan.namaKnj}',
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: const TextStyle(
                                                        fontSize: 14),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                IconButton(
                                                  onPressed: () =>
                                                      _shareToWhatsApp(
                                                          kunjungan),
                                                  icon: const Icon(
                                                      Icons.share_outlined,
                                                      color: Colors.teal),
                                                  tooltip:
                                                      'Bagikan via WhatsApp',
                                                ),
                                                const SizedBox(width: 4),
                                                ElevatedButton.icon(
                                                  onPressed: () =>
                                                      showDetailDialog(
                                                          context, kunjungan),
                                                  icon: const Icon(
                                                      Icons
                                                          .remove_red_eye_outlined,
                                                      size: 16,
                                                      color: Colors.white),
                                                  label: const Text('Detail',
                                                      style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.white)),
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        _accentColor,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 12,
                                                        vertical: 6),
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(int id, String namaKnj) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Kunjungan Ini?'),
        content: Text('Data kunjungan ' +
            namaKnj +
            ' akan dihapus permanen. Anda yakin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteKunjungan(id);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}

class Kunjungan {
  final int idKnj;
  final String tglKnj;
  final String jamDariCreatedAt;
  final String lokasiKnj;
  final String latlongKnj;
  final String? fotoKnj;
  final String pekerjaanKnj;
  final String kategoriKnj;
  final String sumberKnj;
  final String hasilKnj;
  final String kontakKnj;
  final String namaPro;
  final String namaKnj;
  final String userKnj;
  final String divisiKnj;

  Kunjungan({
    required this.idKnj,
    required this.tglKnj,
    required this.jamDariCreatedAt,
    required this.lokasiKnj,
    required this.latlongKnj,
    this.fotoKnj,
    required this.pekerjaanKnj,
    required this.kategoriKnj,
    required this.sumberKnj,
    required this.hasilKnj,
    required this.kontakKnj,
    required this.namaPro,
    required this.namaKnj,
    required this.userKnj,
    required this.divisiKnj,
  });

  factory Kunjungan.fromJson(Map<String, dynamic> json) {
    DateTime parsedJam = DateFormat("HH:mm:ss").parse(json['jam']);
    String jam = DateFormat("HH:mm").format(parsedJam);
    final DateFormat formatter = DateFormat('d MMMM y', 'id');
    final formattedDate = formatter.format(DateTime.parse(json['tgl_knj']));

    return Kunjungan(
      idKnj: json['id'] ?? '',
      tglKnj: formattedDate,
      jamDariCreatedAt: jam,
      lokasiKnj: json['lokasi_knj'] ?? '',
      latlongKnj: json['latlong_knj'] ?? '',
      fotoKnj: json['foto_knj'],
      pekerjaanKnj: json['pekerjaan_knj'] ?? '',
      kategoriKnj: json['kategori_knj'] ?? '',
      sumberKnj: json['sumber_knj'] ?? '',
      hasilKnj: json['hasil_knj'] ?? '',
      kontakKnj: json['kontak_knj'] ?? '',
      namaPro: json['nama_pro'] ?? '',
      namaKnj: json['nama_knj'] ?? '',
      userKnj: json['user_knj'] ?? '',
      divisiKnj: json['user_divisi'] ?? '',
    );
  }
}
