import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:sisflutterproject/screens/login_screen.dart';
import 'package:sisflutterproject/services/session_service.dart'; // Pastikan ini benar
import 'package:url_launcher/url_launcher.dart';

class HistoryVisitScreen extends StatefulWidget {
  const HistoryVisitScreen({Key? key}) : super(key: key);

  @override
  State<HistoryVisitScreen> createState() => _HistoryVisitScreenState();
}

class _HistoryVisitScreenState extends State<HistoryVisitScreen> {
  final Color _primaryColor = const Color(0xFF01462B);
  final Color _secondaryColor = const Color(0xFF4DB6AC);
  final Color _accentColor = const Color(0xFFFFA000);

  List<Kunjungan> kunjunganList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchKunjunganData();
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

      // // 1. Coba buka Google Maps App via URI khusus
      // final Uri gmapsAppUri = Uri.parse('comgooglemaps://?q=$lat,$lng');

      // if (await canLaunchUrl(gmapsAppUri)) {
      //   await launchUrl(gmapsAppUri, mode: LaunchMode.externalApplication);
      //   return;
      // }

      // 2. Fallback ke web browser
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

      double.parse(parts[0]); // Validasi lat
      double.parse(parts[1]); // Validasi lng

      return latlong;
    } catch (e) {
      return '-';
    }
  }

  Future<void> fetchKunjunganData() async {
    final userId = await SessionService.getID();
    final token = await SessionService.getToken();
    // final token = '304cbaf2-1c24-4697-bce2-e040d771d29b';
    final url = Uri.parse(
        'https://fakelocation.warungkode.com/api/kunjungan/history/$userId');
    // final url = Uri.parse('http://192.168.192.98:8080/api/kunjungan/history/$userId');

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': token ?? ''},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final dataList = jsonData['data'] as List;

        setState(() {
          kunjunganList =
              dataList.map((item) => Kunjungan.fromJson(item)).toList();
          isLoading = false;
        });
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
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat data kunjungan')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
                        Icons.calendar_today, 'Tanggal', kunjungan.tglKnj),
                    _buildDetailItem(
                        Icons.access_time, 'Jam', kunjungan.jamDariCreatedAt),
                    _buildDetailItem(
                        Icons.business, 'Project', kunjungan.namaPro),
                    _buildDetailItem(Icons.abc, 'Nama', kunjungan.namaKnj),
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
                        Icons.work, 'Pekerjaan', kunjungan.pekerjaanKnj),
                    _buildDetailItem(
                        Icons.category, 'Kategori', kunjungan.kategoriKnj),
                    _buildDetailItem(
                        Icons.person, 'Kontak', kunjungan.kontakKnj),
                    _buildDetailItem(
                        Icons.source, 'Sumber', kunjungan.sumberKnj),
                    _buildDetailItem(
                        Icons.edit_note, 'Hasil', kunjungan.hasilKnj),

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

  @override
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_primaryColor.withOpacity(0.05), Colors.white],
          ),
        ),
        child: isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.teal),
                    SizedBox(height: 16),
                    Text("Memuat data kunjungan..."),
                  ],
                ),
              )
            : kunjunganList.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        "Data Kunjungan Tidak Ditemukan",
                        style: TextStyle(fontSize: 18, color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Menampilkan Maksimal 25 Kunjungan Terakhir",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: kunjunganList.length,
                            itemBuilder: (context, index) {
                              final kunjungan = kunjunganList[index];
                              return Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 20,
                                                backgroundColor:
                                                    _secondaryColor,
                                                child: Icon(
                                                    Icons.calendar_today,
                                                    size: 16,
                                                    color: Colors.white),
                                              ),
                                              const SizedBox(width: 12),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    kunjungan.tglKnj,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Jam: ${kunjungan.jamDariCreatedAt}',
                                                    style: const TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.black54),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          ElevatedButton.icon(
                                            onPressed: () => showDetailDialog(
                                                context, kunjungan),
                                            icon: const Icon(
                                              Icons.remove_red_eye_outlined,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                            label: const Text('Detail',
                                                style: TextStyle(
                                                    fontSize: 15,
                                                    color: Colors.white)),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: _accentColor,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              textStyle: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.normal),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on,
                                              size: 16, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Lokasi: ${kunjungan.lokasiKnj}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  const TextStyle(fontSize: 14),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.pin_drop,
                                              size: 16, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'LatLong: ${kunjungan.latlongKnj}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style:
                                                  const TextStyle(fontSize: 14),
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
                      ],
                    ),
                  ),
      ),
    );
  }
}

class Kunjungan {
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

  Kunjungan({
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
  });

  factory Kunjungan.fromJson(Map<String, dynamic> json) {
    // final DateTime jamParse = json['jam'];
    // final jam =
    //     '${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';
    DateTime parsedJam = DateFormat("HH:mm:ss").parse(json['jam']);
    String jam = DateFormat("HH:mm").format(parsedJam);
    final DateFormat formatter =
        DateFormat('d MMMM y', 'id'); // Format: 17 Februari 2025
    final formattedDate = formatter.format(DateTime.parse(json['tgl_knj']));

    return Kunjungan(
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
    );
  }
}
