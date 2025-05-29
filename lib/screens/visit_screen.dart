import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';
import 'package:intl/intl.dart';

import 'package:sisflutterproject/services/visit_service.dart';

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
  
  String? _selectedTime = '07.00';
  XFile? _imageFile;
  String? _location;
  bool _isGettingLocation = false;


  // Define dropdown options with separate values and display text
  final List<DropdownItem> _projectOptions = [
    DropdownItem(value: '0', displayText: 'Belum Dapat'),
    DropdownItem(value: '1', displayText: 'Database'),
    DropdownItem(value: '2', displayText: 'Potensi'),
    DropdownItem(value: '3', displayText: 'Prospek'),
    DropdownItem(value: '4', displayText: 'Hot Prospek'),
    DropdownItem(value: '5', displayText: 'Booking'),
  ];

  final List<DropdownItem> _categoryOptions = [
    DropdownItem(value: 'cat0', displayText: 'Reguler'),
    DropdownItem(value: 'cat1', displayText: 'VIP'),
    DropdownItem(value: 'cat2', displayText: 'VVIP'),
  ];

  final List<DropdownItem> _sourceOptions = [
    DropdownItem(value: 'src0', displayText: 'Program Pohon'),
    DropdownItem(value: 'src1', displayText: 'Media Sosial'),
    DropdownItem(value: 'src2', displayText: 'Baligo'),
    DropdownItem(value: 'src3', displayText: 'Flyering'),
  ];

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visit'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 24),

              // Form Title
              const Text(
                'Form Kunjungan Konsumen',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 20, thickness: 1),
              const SizedBox(height: 16),

              // Project Dropdown
              _buildDropdownField(
                controller: _projectController,
                label: 'Nama Project',
                icon: Icons.add_home_work,
                items: _projectOptions,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harap pilih project';
                  }
                  return null;
                },
              ),

              // Company Name
              _buildTextField(
                controller: _companyController,
                label: 'Nama Perusahaan',
                icon: Icons.business,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harap masukkan nama perusahaan';
                  }
                  return null;
                },
              ),

              // Full Name
              _buildTextField(
                controller: _nameController,
                label: 'Nama Lengkap',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Harap masukkan nama lengkap';
                  }
                  return null;
                },
              ),

              // Job
              _buildTextField(
                controller: _jobController,
                label: 'Pekerjaan',
                icon: Icons.work,
              ),
              
              // Job
              _buildTextField(
                controller: _lokasiController,
                label: 'Lokasi',
                icon: Icons.gps_fixed,
              ),

              // Category Dropdown
              _buildDropdownField(
                controller: _categoryController,
                label: 'Kategori',
                icon: Icons.category,
                items: _categoryOptions,
              ),

              // Phone Number
              _buildTextField(
                controller: _phoneController,
                label: 'No Hp',
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

              // Source Dropdown
              _buildDropdownField(
                controller: _sourceController,
                label: 'Sumber',
                icon: Icons.source,
                items: _sourceOptions,
              ),

              // Visit Description
              _buildTextField(
                controller: _descriptionController,
                label: 'Deskripsi Hasil Kunjungan',
                icon: Icons.description,
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Image and Location Section
              const Text(
                'Ambil Gambar dan Lokasi',
                style: TextStyle(fontWeight: FontWeight.bold),
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
                      const Text('Ambil Gambar'),
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
                          : const Text('Ambil Lokasi'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Preview Image
              if (_imageFile != null)
                Column(
                  children: [
                    const Text(
                      'Gambar yang diambil:',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
                    const Text(
                      'Lokasi:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(_location!),
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
                  ),
                  onPressed: _submitForm,
                  child: const Text(
                    'SAVE',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
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
      ),
    );
  }

  Widget _buildDropdownField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required List<DropdownItem> items,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<DropdownItem>(
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

  Future<void> _getLocation() async {
    setState(() {
      _isGettingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lokasi tidak aktif')),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Izin lokasi ditolak')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin lokasi ditolak permanen')),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _location = 'Lat: ${position.latitude.toStringAsFixed(4)}, '
                   'Lng: ${position.longitude.toStringAsFixed(4)}';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mendapatkan lokasi: $e')),
      );
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

 void _submitForm() async {
  if (_formKey.currentState!.validate()) {
    // Show loading indicator
 
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    print({
        'projectId': _projectController.text,
        'namaKnj': _nameController.text,
        'tglKnj': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'lokasiknj': _lokasiController.text,
        'latlongKnj': _location,
        'pekerjaanKnj': _jobController.text,
        'kategoriKnj': _categoryController.text,
        'sumberKnj':  _sourceController.text,
        'hasilKnj': _descriptionController.text,  
        'imageFile': _imageFile,
        'kontakKnj': _phoneController.text
    });
    try {
      // Call service to submit data
     
        Map response = await VisitService.submitVisit(
        projectId: _projectController.text,
        namaKnj: _nameController.text,
        tglKnj: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        lokasiknj: _lokasiController.text,
        latlongKnj: _location,
        pekerjaanKnj: _jobController.text,
        kategoriKnj: _categoryController.text,
        sumberKnj:  _sourceController.text,
        hasilKnj: _descriptionController.text,  
        imageFile: _imageFile,
        kontakKnj: _phoneController.text
      );

      if (response.containsKey('success')){

          // Reset form
     
        setState(() {
          _imageFile = null;
          _location = null;
        });
       _formKey.currentState!.reset();
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data Berhasil Tersimpan !'),
          duration: Duration(seconds: 2),
        ),
      );
      }
    
      
    } catch (e){
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data Gagal tersimpan !'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    
    finally {
      // Hide loading indicator
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