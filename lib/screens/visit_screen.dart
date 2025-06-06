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
        SnackBar(content: Text('Gagal memuat project: $e')),
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
        title: const Text('Form Kunjungan'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
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
                  const Text('Nama Project', style: TextStyle(fontSize: 16)),
                ],
              ),
              const SizedBox(height: 4),
              _isLoadingProjects
                ? const Center(child: CircularProgressIndicator())
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
                            style: TextStyle(color: Colors.red),
                          ),
                          IconButton(
                            icon: Icon(Icons.refresh),
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
                  const Text('Nama Perusahaan', style: TextStyle(fontSize: 16)),
                  const Text(' *(Wajib Diisi!)', style: TextStyle(color: Colors.red )),
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
                  const Text('Nama Lengkap', style: TextStyle(fontSize: 16)),
                  const Text(' *(Wajib Diisi!)', style: TextStyle(color: Colors.red )),
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
                  const Text('Pekerjaan', style: TextStyle(fontSize: 16)),
                  const Text(' *(Wajib Diisi!)', style: TextStyle(color: Colors.red )),
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
              const Text('Kategori', style: TextStyle(fontSize: 16)),
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
                  const Text('No HP', style: TextStyle(fontSize: 16)),
                  const Text(' *(Wajib Diisi!)', style: TextStyle(color: Colors.red )),
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
              const Text('Sumber', style: TextStyle(fontSize: 16)),
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
                  const Text('Deskripsi Hasil Kunjungan', style: TextStyle(fontSize: 16)),
                  const Text(' *(Wajib Diisi!)', style: TextStyle(color: Colors.red )),
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

              // Image and Location Section
              const Row(
                children: [
                  Text(
                    'Ambil Gambar dan Lokasi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(' *(Wajib Diisi!)', style: TextStyle(color: Colors.red )),
                ],
              ),
              const SizedBox(height: 8),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.camera_alt, size: 40),
                        onPressed: _takePicture,
                      ),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Ambil Gambar'),
                          Text('*', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.location_on, size: 40),
                        onPressed: _isGettingLocation ? null : _getLocation,
                      ),
                      _isGettingLocation 
                          ? const CircularProgressIndicator()
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Ambil Lokasi'),
                                Text('*', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Preview Image
              if (_imageFile != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const Text(
                      'Gambar berhasil diambil',
                      style: TextStyle(color: Colors.green, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Image.file(
                      File(_imageFile!.path),
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              
              // Location Info
              if (_location != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const Text(
                      'Lokasi berhasil diambil',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    ),
                    const Text(
                      'Koordinat:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(_location!),
                    const SizedBox(height: 8),
                    const Text(
                      'Nama Daerah:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(_namaDaerah ?? 'Sedang memuat nama daerah...'),
                   
                    const SizedBox(height: 16),
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
                        ? Colors.grey 
                        : Theme.of(context).primaryColor,
                  ),
                  onPressed: (_location == null || _imageFile == null || _isRootedOrJailbroken ==  true) 
                      ? null 
                      : _submitForm,
                  child: Text(
                    'SIMPAN',
                    style: TextStyle(
                      fontSize: 18,
                      color: _location == null || _imageFile == null 
                          ? Colors.grey 
                          : Colors.white, // atau warna lain yang Anda inginkan
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
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
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.grey[50],
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
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: items.map((DropdownItem item) {
        return DropdownMenuItem<DropdownItem>(
          value: item,
          child: Text(item.displayText),
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
    }
  }

  Future<void> _checkRootJailbreak() async {
    bool detected = await RootJailbreakDetector.isRooted();
      setState(() {
        _isRootedOrJailbroken = detected;
      });
      if(_isRootedOrJailbroken == true){
             await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Device Already Jailbreak'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Device Already Rooted !, Please consider to un-root your device and try again !'),
            const SizedBox(height: 10),
            // Text('Jarak antara GPS dan IP: ${distance.toStringAsFixed(2)} km'),
            // if (vpnDetected) const Text('VPN Terdeteksi'),
            
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pop(context);

            },
            child: const Text('OK'),
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
          const SnackBar(content: Text('Aktifkan layanan lokasi terlebih dahulu')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin lokasi diperlukan untuk melanjutkan')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aktifkan izin lokasi di pengaturan device')),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Panggil API deteksi Fake GPS
      try {
         final fakeGpsResponse = await _checkFakeGps(
        latitude: position.latitude,
        longitude: position.longitude,
          );
          
          if (fakeGpsResponse['status'] == 'warning') {
            setState(() {
              _fakeGpsDetected = true;
              _fakeGpsMessage = fakeGpsResponse['message'];
            });
            // Tampilkan dialog peringatan dan batalkan pengambilan lokasi
            await _showFakeGpsWarningDialog(
              context,
              fakeGpsResponse['message'],
              fakeGpsResponse['distance_km'],
              fakeGpsResponse['vpn_detected'],
            );
            
            return; // Batalkan proses pengambilan lokasi
          }

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed To check FakeGPS!'),
            duration: Duration(seconds: 2),
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
            const SnackBar(content: Text('Tidak ada koneksi internet untuk mendapatkan nama daerah')),
          );
          setState(() {
            _location = cacheKey;
            _namaDaerah = 'Lokasi (${_location})';
            _lokasiController.text = _namaDaerah!;
          });
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mendapatkan nama daerah: $e')),
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
        SnackBar(content: Text('Failed To Get Location: $e')),
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
    double distance,
    bool vpnDetected,
  ) async {
    bool continueAnyway = false;
    
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Location Warning!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 10),
            // Text('Jarak antara GPS dan IP: ${distance.toStringAsFixed(2)} km'),
            // if (vpnDetected) const Text('VPN Terdeteksi'),
            
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pop(context);
            },
            child: const Text('OK'),
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
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      if (_imageFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Harap ambil gambar terlebih dahulu!'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data berhasil disimpan!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal menyimpan data!'),
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


class RootJailbreakDetector {
  static Future<bool> isRooted() async {
    if (kIsWeb) return false;

    if (Platform.isAndroid) {
      List<String> paths = [
        '/system/app/Superuser.apk',
        '/sbin/su',
        '/system/bin/su',
        '/system/xbin/su',
        '/data/local/xbin/su',
        '/data/local/bin/su',
        '/system/sd/xbin/su',
        '/system/bin/failsafe/su',
        '/data/local/su',
      ];

      for (var path in paths) {
        if (await File(path).exists()) {
          return true;
        }
      }

      try {
        final tags = await File('/system/build.prop').readAsString();
        if (tags.contains('test-keys')) {
          return true;
        }
      } catch (e) {}

      try {
        ProcessResult result = await Process.run('which', ['su']);
        if (result.stdout.toString().isNotEmpty) {
          return true;
        }
      } catch (e) {}

      return false;
    } else if (Platform.isIOS) {
      List<String> jailbreakPaths = [
        '/Applications/Cydia.app',
        '/Library/MobileSubstrate/MobileSubstrate.dylib',
        '/bin/bash',
        '/usr/sbin/sshd',
        '/etc/apt',
      ];

      for (var path in jailbreakPaths) {
        if (await File(path).exists()) {
          return true;
        }
      }

      // Dummy cek url scheme jailbreak, skip dan return false
      return false;
    } else {
      return false;
    }
  }
}
