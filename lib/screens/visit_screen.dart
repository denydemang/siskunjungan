import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:sisflutterproject/services/session_service.dart';
import 'package:sisflutterproject/services/visit_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:safe_device/safe_device.dart';

// Color Scheme based on the dashboard image
const Color primaryColor =  Color(0xFF009688);// Dark blue from dashboard header
const Color accentColor =  Color(0xFF4CAF50);   // Green from the ▲ indicators
const Color backgroundColor = Color(0xFFF5F5F5); // Light gray background
const Color textColor = Color(0xFF333333);     // Dark text color
const Color errorColor = Color(0xFFE53935);     // Red for errors
const Color successColor = Color(0xFF43A047);   // Green for success messages
const Color warningColor = Color(0xFFFFA000);   // Amber for warnings
const Color disabledColor = Color(0xFFBDBDBD);  // Gray for disabled elements

class DropdownItem {
  final String value;
  final String displayText;

  DropdownItem({required this.value, required this.displayText});
}

class VisitScreen extends StatefulWidget {
  const VisitScreen({super.key});

  @override
  State<VisitScreen> createState() => _VisitScreenState();
}

class _VisitScreenState extends State<VisitScreen> {
  bool? _isRootedOrJailbroken;
  bool _fakeGpsDetected = false;
  String _fakeGpsMessage = '';

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _jobController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _projectController = TextEditingController();
  final TextEditingController _lokasiController = TextEditingController();
  double? lastLatitude;
  double? lastLongitude;
  bool isTeleport = false;
  XFile? _imageFile;
  String? _location;
  String? _namaDaerah;
  bool _isGettingLocation = false;
  bool _isLoadingProjects = false;
  String? _projectError;
  final Map<String, String> _locationCache = {};

  List<DropdownItem> _projectOptions = [];

  final List<DropdownItem> _categoryOptions = [
    DropdownItem(value: 'Reguler', displayText: 'Reguler'),
    DropdownItem(value: 'VIP', displayText: 'VIP'),
    DropdownItem(value: 'VVIP', displayText: 'VVIP'),
  ];

  final List<DropdownItem> _sourceOptions = [
    DropdownItem(value: 'Program Pohon', displayText: 'Program Pohon'),
    DropdownItem(value: 'Media Sosial', displayText: 'Media Sosial'),
    DropdownItem(value: 'Baligo', displayText: 'Baligo'),
    DropdownItem(value: 'Flyering', displayText: 'Flyering'),
  ];

  Future<void> _loadProjects() async {
    setState(() {
      _isLoadingProjects = true;
      _projectError = null;
    });
    try {
      final projects = await VisitService.fetchProjects();
      setState(() {
        _projectOptions = projects;
      });
    } catch (e) {
      setState(() {
        _projectError = e.toString();
        _projectOptions = [
          DropdownItem(value: '0', displayText: 'Belum Dapat'),
          DropdownItem(value: '1', displayText: 'Database'),
          DropdownItem(value: '2', displayText: 'Potensi'),
          DropdownItem(value: '3', displayText: 'Prospek'),
          DropdownItem(value: '4', displayText: 'Hot Prospek'),
          DropdownItem(value: '5', displayText: 'Booking'),
        ];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat project: $e'),
          backgroundColor: errorColor,
        ),
      );
    } finally {
      setState(() {
        _isLoadingProjects = false;
      });
    }
  }

  @override
  void dispose() {
    _companyController.dispose();
    _nameController.dispose();
    _jobController.dispose();
    _categoryController.dispose();
    _phoneController.dispose();
    _sourceController.dispose();
    _descriptionController.dispose();
    _projectController.dispose();
    _lokasiController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _checkRootJailbreak();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Form Kunjungan', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: backgroundColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                
                // Project Dropdown
                Row(
                  children: [
                    const Text('Nama Project', style: TextStyle(fontSize: 16, color: textColor)),
                  ],
                ),
                const SizedBox(height: 4),
                _isLoadingProjects
                  ? Center(child: CircularProgressIndicator(color: primaryColor))
                  : _projectError != null
                      ? Column(
                          children: [
                            _buildDropdownField(
                              controller: _projectController,
                              label: '',
                              icon: Icons.add_home_work,
                              items: _projectOptions,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Harap pilih project';
                                }
                                return null;
                              },
                            ),
                            Text(
                              _projectError!,
                              style: const TextStyle(color: errorColor),
                            ),
                            IconButton(
                              icon: Icon(Icons.refresh, color: primaryColor),
                              onPressed: _loadProjects,
                              tooltip: 'Refresh Data Project',
                            ),
                          ],
                        )
                      : _buildDropdownField(
                          controller: _projectController,
                          label: '',
                          icon: Icons.add_home_work,
                          items: _projectOptions,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Harap pilih project';
                            }
                            return null;
                          },
                        ),
                const SizedBox(height: 16),

                // Company Name
                Row(
                  children: [
                    const Text('Nama Perusahaan', style: TextStyle(fontSize: 16, color: textColor)),
                    const Text(' *(Wajib Diisi!)', style: TextStyle(color: errorColor)),
                  ],
                ),
                const SizedBox(height: 4),
                _buildTextField(
                  controller: _companyController,
                  label: '',
                  icon: Icons.business,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Harap masukkan nama perusahaan';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Full Name
                Row(
                  children: [
                    const Text('Nama Lengkap', style: TextStyle(fontSize: 16, color: textColor)),
                    const Text(' *(Wajib Diisi!)', style: TextStyle(color: errorColor)),
                  ],
                ),
                const SizedBox(height: 4),
                _buildTextField(
                  controller: _nameController,
                  label: '',
                  icon: Icons.person,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Harap masukkan nama lengkap';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Job
                Row(
                  children: [
                    const Text('Pekerjaan', style: TextStyle(fontSize: 16, color: textColor)),
                    const Text(' *(Wajib Diisi!)', style: TextStyle(color: errorColor)),
                  ],
                ),
                const SizedBox(height: 4),
                _buildTextField(
                  controller: _jobController,
                  label: '',
                  icon: Icons.work,
                ),
                const SizedBox(height: 16),
                
                // Category Dropdown
                const Text('Kategori', style: TextStyle(fontSize: 16, color: textColor)),
                const SizedBox(height: 4),
                _buildDropdownField(
                  controller: _categoryController,
                  label: '',
                  icon: Icons.category,
                  items: _categoryOptions,
                ),
                const SizedBox(height: 16),

                // Phone Number
                Row(
                  children: [
                    const Text('No HP', style: TextStyle(fontSize: 16, color: textColor)),
                    const Text(' *(Wajib Diisi!)', style: TextStyle(color: errorColor)),
                  ],
                ),
                const SizedBox(height: 4),
                _buildTextField(
                  controller: _phoneController,
                  label: '',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Harap masukkan nomor handphone';
                    }
                    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                      return 'Nomor handphone tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Source Dropdown
                const Text('Sumber', style: TextStyle(fontSize: 16, color: textColor)),
                const SizedBox(height: 4),
                _buildDropdownField(
                  controller: _sourceController,
                  label: '',
                  icon: Icons.source,
                  items: _sourceOptions,
                ),
                const SizedBox(height: 16),

                // Visit Description
                Row(
                  children: [
                    const Text('Deskripsi Hasil Kunjungan', style: TextStyle(fontSize: 16, color: textColor)),
                    const Text(' *(Wajib Diisi!)', style: TextStyle(color: errorColor)),
                  ],
                ),
                const SizedBox(height: 4),
                _buildTextField(
                  controller: _descriptionController,
                  label: '',
                  icon: Icons.description,
                  maxLines: 3,
                ),
                const SizedBox(height: 24),

                // Image Section
                Center(
                  child: Column(
                    children: [
                      IconButton(
                        icon: Icon(Icons.camera_alt, size: 40, color: primaryColor),
                        onPressed: _takePicture,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text('Ambil Gambar', style: TextStyle(color: textColor)),
                          Text('*', style: TextStyle(color: errorColor)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Preview Image and Location Info
                if (_imageFile != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle, color: successColor, size: 16),
                      const Text(
                        'Gambar berhasil diambil',
                        style: TextStyle(color: successColor, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Image.file(
                        File(_imageFile!.path),
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      const SizedBox(height: 16),
                      
                      if (_isGettingLocation)
                        Center(child: CircularProgressIndicator(color: primaryColor)),
                      
                      if (_location != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle, color: successColor, size: 16),
                            const Text(
                              'Lokasi berhasil diambil',
                              style: TextStyle(color: successColor, fontSize: 12),
                            ),
                            const Text(
                              'Koordinat:',
                              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                            ),
                            Text(_location!, style: const TextStyle(color: textColor)),
                            const SizedBox(height: 8),
                            const Text(
                              'Nama Daerah:',
                              style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
                            ),
                            Text(_namaDaerah ?? 'Sedang memuat nama daerah...', style: const TextStyle(color: textColor)),
                            const SizedBox(height: 16),
                          ],
                        ),
                    ],
                  ),

                // Save Button
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: _location == null || _imageFile == null 
                          ? disabledColor 
                          : primaryColor,
                    ),
                    onPressed: (_location == null || _imageFile == null || _isRootedOrJailbroken ==  true) 
                        ? null 
                        : _submitForm,
                    child: Text(
                      'SIMPAN',
                      style: TextStyle(
                        fontSize: 18,
                        color: _location == null || _imageFile == null 
                            ? Colors.grey[800]
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
    );
  }

  Widget _buildDropdownField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required List<DropdownItem> items,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<DropdownItem>(
      style: const TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textColor.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
      dropdownColor: Colors.white,
      items: items.map((DropdownItem item) {
        return DropdownMenuItem<DropdownItem>(
          value: item,
          child: Text(item.displayText, style: const TextStyle(color: textColor)),
        );
      }).toList(),
      onChanged: (DropdownItem? newValue) {
        if (newValue != null) {
          controller.text = newValue.value;
        }
      },
      validator: validator != null 
          ? (value) => validator(value?.value)
          : null,
      value: items.firstWhere(
        (item) => item.value == controller.text,
        orElse: () => items.first,
      ),
    );
  }

  Future<void> _takePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      imageQuality: 80,
    );
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
      // Automatically get location after taking picture
      await _getLocation();
    }
  }

  Future<void> _checkRootJailbreak() async {
    bool detected = await SafeDevice.isJailBroken;
      setState(() {
        _isRootedOrJailbroken = detected;
      });
      if(_isRootedOrJailbroken == true){
             await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Device Already Jailbreak', style: TextStyle(color: errorColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Your Device Already Rooted !, Please consider to un-root your device and try again !'),
            SizedBox(height: 10),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pop(context);
            },
            child: const Text('OK', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
      }
    }

  Future<void> _getLocation() async {
    setState(() {
      _isGettingLocation = true;
      _location = null;
      _namaDaerah = null;
      _fakeGpsDetected = false;
      _fakeGpsMessage = '';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aktifkan layanan lokasi terlebih dahulu'),
            backgroundColor: warningColor,
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin lokasi diperlukan untuk melanjutkan'),
              backgroundColor: warningColor,
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aktifkan izin lokasi di pengaturan device'),
            backgroundColor: warningColor,
          ),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Panggil API deteksi Fake GPS
      try {
        
         // Check Developer Mode Enable or Not

      
            bool isRealDevice = await SafeDevice.isRealDevice;

            if (isRealDevice == false){

              String msg = 'Kamu Sedang Di Emulator Mode';
              await _showRealDeviceDialog(
                  context,
                  msg,
              );
              return;
            }
            bool isDevelopmentModeEnable = await SafeDevice.isDevelopmentModeEnable;
            if (isDevelopmentModeEnable == true){

              String msg = 'Silakan Matikan Mode Pengembang Di Pengaturan Device Anda Terlebih Dahulu, Kemudian Coba Lagi !';
              await _showDeveloperModeEnabledDialog(
                  context,
                  msg,
              );
              return; // Batalkan proses pengambilan lokasi
            }

            double distance = 0;
             // Teleport check (loncat lokasi ekstrem)
            if (lastLatitude != null && lastLongitude != null) {
              distance = Geolocator.distanceBetween(
                lastLatitude!,
                lastLongitude!,
                position.latitude,
                position.longitude,
              );

              if (distance > 10000) {
                // 10 km loncatan
                isTeleport = true;
                
              } else {
                isTeleport = false;
              }
            }
            int distanceinKM = (distance / 100).round();
            if (isTeleport == true) {

             await _showLoncatLokasiDialog(
                  context,
                  'Terdapat Perbedaan Lokasi Yang Signifikan dengan Lokasi Sebelumnya, Distance Gap :  $distanceinKM Km',
              );
                return;
            }
             // Simpan posisi terakhir
            lastLatitude = position.latitude;
            lastLongitude = position.longitude;

 

            // Fake GPS/Mock Location

            bool isPositionMocked = position.isMocked;
            bool isMockLocation = await SafeDevice.isMockLocation;
          

            if (isMockLocation == true || isPositionMocked ==  true){
                  String msg= 'Fake GPS Terdeteksi,  Silakan Matikan Terlebih Dahulu App FakeGPS/ Aplikasi Serupa';
                  setState(() {
                  _fakeGpsDetected = true;
                  _fakeGpsMessage = msg;
                });
              await _showFakeGpsWarningDialog(
                  context,
                  msg,
              );
              return; // Batalkan proses pengambilan lokasi
            }

          //  final fakeGpsResponse = await _checkFakeGps(
          // latitude: position.latitude,
          // longitude: position.longitude,
          //   );
            
          //   if (fakeGpsResponse['status'] == 'warning') {
              
            
          //     // Tampilkan dialog peringatan dan batalkan pengambilan lokasi
            
              
        
          //   } 
          // else if (fakeGpsResponse['status'] == 'success'){
          //    await _showFakeGpsSuccessDialog(
          //     context,
          //     fakeGpsResponse['message'],
          //     fakeGpsResponse['distance_km'],
          //     fakeGpsResponse['vpn_detected'],
          //     fakeGpsResponse['gps_location'],
          //     fakeGpsResponse['ip_location'],
          //     fakeGpsResponse['ip'],
          //     fakeGpsResponse['org']
          //   );
          // }

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed To check FakeGPS!'),
            backgroundColor: errorColor,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
     
      String cacheKey = '${position.latitude},${position.longitude}';
      if (_locationCache.containsKey(cacheKey)) {
        setState(() {
          _location = cacheKey;
          _namaDaerah = _locationCache[cacheKey];
          _lokasiController.text = _namaDaerah!;
        });
      } else {
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );

          if (placemarks.isNotEmpty) {
            Placemark place = placemarks.first;
            setState(() {
              _location = cacheKey;
              _namaDaerah = [
                place.subLocality,
                place.locality,
                place.subAdministrativeArea,
                place.administrativeArea,
              ].where((part) => part?.isNotEmpty ?? false).join(', ');
              _lokasiController.text = _namaDaerah!;
              _locationCache[cacheKey] = _namaDaerah!;
            });
          }
        } on SocketException catch (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak ada koneksi internet untuk mendapatkan nama daerah'),
              backgroundColor: warningColor,
            ),
          );
          setState(() {
            _location = cacheKey;
            _namaDaerah = 'Lokasi (${_location})';
            _lokasiController.text = _namaDaerah!;
          });
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mendapatkan nama daerah: $e'),
              backgroundColor: errorColor,
            ),
          );
          setState(() {
            _location = cacheKey;
            _namaDaerah = 'Lokasi (${_location})';
            _lokasiController.text = _namaDaerah!;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed To Get Location: $e'),
          backgroundColor: errorColor,
        ),
      );
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  Future<void> _showFakeGpsWarningDialog(
    BuildContext context,
    String message,

  ) async {
    bool continueAnyway = false;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Location Warning!', style: TextStyle(color: warningColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${message}'),
            const SizedBox(height: 10),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Navigator.of(context).pop();
              Navigator.pop(context);
            },
            child: const Text('OK', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _showLoncatLokasiDialog(
    BuildContext context,
    String message,

  ) async {
    bool continueAnyway = false;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Location Warning!', style: TextStyle(color: warningColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${message}'),
            const SizedBox(height: 10),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Navigator.of(context).pop();
              Navigator.pop(context);
            },
            child: const Text('OK', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeveloperModeEnabledDialog(
    BuildContext context,
    String message,

  ) async {
    bool continueAnyway = false;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Developer Mode Aktif!', style: TextStyle(color: warningColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${message}'),
            const SizedBox(height: 10),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Navigator.of(context).pop();
              Navigator.pop(context);
            },
            child: const Text('OK', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }
    
  Future<void> _showRealDeviceDialog(
    BuildContext context,
    String message,

  ) async {
    bool continueAnyway = false;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Informasi !', style: TextStyle(color: accentColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${message}'),
            const SizedBox(height: 10),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Navigator.of(context).pop();
              Navigator.pop(context);
            },
            child: const Text('OK', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }
  
  Future<void> _showFakeGpsSuccessDialog(
    BuildContext context,
    String message,
    double distance,
    bool vpnDetected,
    List gpslocation,
    List iplocation,
    String ip ,
    String org

  ) async {
    bool continueAnyway = false;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Success!', style: TextStyle(color: successColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${message} , Jarak : ${distance} , Status VPN : ${vpnDetected.toString()} , GPS Laltlong : (${gpslocation[0]},${gpslocation[1]}) , IP Laltlong : (${iplocation[0]},${iplocation[1]}) , IP : ${ip} , ORG: ${org}' ),
            const SizedBox(height: 10),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Navigator.of(context).pop();
              Navigator.pop(context);
            },
            child: const Text('OK', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }
  Future<Map<String, dynamic>> _checkFakeGps({
    required double latitude,
    required double longitude,
  }) async {
    try {
      const String apiUrl = 'https://fakelocation.warungkode.com/api/check-location';
      final token = await SessionService.getToken();
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization' : token.toString()
          },
        body: json.encode({
          'latitude': latitude,
          'longitude': longitude,
          'image_base64': '', // Kosongkan seperti permintaan
          'root_jailbreak': _isRootedOrJailbroken, // Asumsi device tidak di-root
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to check fake GPS: ${response.statusCode}');
      }
    } catch (e) {
      // Jika API error, anggap lokasi valid tetapi beri warning
      return {
        'status': 'error',
        'message': 'Tidak dapat memverifikasi lokasi: $e',
        'distance_km': 0,
        'vpn_detected': false,
      };
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      if (_location == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Harap ambil lokasi terlebih dahulu!'),
            backgroundColor: warningColor,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      if (_imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Harap ambil gambar terlebih dahulu!'),
            backgroundColor: warningColor,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );

      try {
        if (_projectOptions.isNotEmpty && _projectController.text.isEmpty) {
          _projectController.text = _projectOptions.first.value;
        }
        if (_sourceOptions.isNotEmpty && _sourceController.text.isEmpty) {
          _sourceController.text = _sourceOptions.first.value;
        }
        if (_categoryOptions.isNotEmpty && _categoryController.text.isEmpty) {
          _categoryController.text = _categoryOptions.first.value;
        }

        Map response = await VisitService.submitVisit(
          projectId: _projectController.text,
          namaKnj: _nameController.text,
          tglKnj: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          lokasiknj: _namaDaerah ?? '-',
          latlongKnj: _location,
          pekerjaanKnj: _jobController.text,
          kategoriKnj: _categoryController.text,
          sumberKnj: _sourceController.text,
          hasilKnj: _descriptionController.text,  
          imageFile: _imageFile,
          kontakKnj: _phoneController.text
        );

        if (response.containsKey('success')) {
          setState(() {
            _imageFile = null;
            _location = null;
            _namaDaerah = null;
          });
          _formKey.currentState!.reset();
          _companyController.clear();
          _nameController.clear();
          _jobController.clear();
          _categoryController.clear();
          _phoneController.clear();
          _sourceController.clear();
          _descriptionController.clear();
          _projectController.clear();
          _lokasiController.clear();
          lastLatitude = null;
          lastLongitude = null;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data berhasil disimpan!'),
              backgroundColor: successColor,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan data!'),
            backgroundColor: errorColor,
            duration: Duration(seconds: 2),
          ),
        );
      } finally {
        Navigator.of(context).pop();
      }
    }
  }

  String _getDisplayText(List<DropdownItem> items, String value) {
    return items.firstWhere(
      (item) => item.value == value,
      orElse: () => DropdownItem(value: '', displayText: 'Tidak diketahui'),
    ).displayText;
  }
}

