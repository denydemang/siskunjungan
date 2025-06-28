import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:sisflutterproject/screens/visit_screen.dart';
import 'package:sisflutterproject/services/session_service.dart';



class VisitService {
  // static const String _baseUrl = 'http://192.168.192.98:8080/api'; 
  static const String _baseUrl = 'https://fakelocation.warungkode.com/api';
  static Future<Map> submitVisit({
    required String? projectId,
    required String? namaKnj,
    required String? tglKnj,
    required String? lokasiknj,
    required String? latlongKnj,
    required String? pekerjaanKnj,
    required String? kategoriKnj,
    required String? sumberKnj,
    required String? hasilKnj,
    required String? kontakKnj,
    required XFile? imageFile,

  }) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/kunjungan'));
      final token = await SessionService.getToken();
      // final token = '304cbaf2-1c24-4697-bce2-e040d771d29b';
      final userID = await SessionService.getID();
      if (token == null || token.isEmpty) {
        throw Exception('User not authenticated - Please login again');
      }
      request.headers['Authorization'] = token;

      print({
        'fieldToSend' : {
        'user_id': userID.toString(),
        'project_id': projectId.toString(),
        'nama_knj': namaKnj.toString(),
        'tgl_knj': tglKnj.toString(),
        'lokasi_knj': lokasiknj.toString(),
        'latlong_knj': latlongKnj.toString(),
        'pekerjaan_knj': pekerjaanKnj.toString(),
        'kategori_knj': kategoriKnj.toString(),
        'sumber_knj': sumberKnj.toString(),
        'hasil_knj': hasilKnj.toString(),
        'kontak_knj': kontakKnj.toString(),
        'token' : token
        }
      });
      // Add text fields
      request.fields.addAll({
        'user_id': userID.toString(),
        'project_id': projectId.toString(),
        'nama_knj': namaKnj.toString(),
        'tgl_knj': tglKnj.toString(),
        'lokasi_knj': lokasiknj.toString(),
        'latlong_knj': latlongKnj.toString(),
        'pekerjaan_knj': pekerjaanKnj.toString(),
        'kategori_knj': kategoriKnj.toString(),
        'sumber_knj': sumberKnj.toString(),
        'hasil_knj': hasilKnj.toString(),
        'kontak_knj': kontakKnj.toString(),
      });

      // Add image file if exists
      if (imageFile != null) {
        var file = await http.MultipartFile.fromPath(
          'foto_knj', 
          imageFile.path,
          filename: imageFile.name,
        );
        request.files.add(file);
      }

      // Send request
      var response = await request.send();
      final responseBody = await response.stream.bytesToString(); 
      print({
        'responseBody' :responseBody
      });
      // Check response
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(responseBody);

     
      }  else if (response.statusCode == 401){
        return ({
          'errorSession' : "Sesion Sudah Habis"
        });
      }
      else {
         throw Exception('error: Terdapat Error Saat Mengirim Data ,Code : ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('error: $e');
    }
  }

  // visit_service.dart
static Future<List<DropdownItem>> fetchProjects(String isPMR ) async {
  try {
    final token = await SessionService.getToken();
    // final token = '304cbaf2-1c24-4697-bce2-e040d771d29b';
    if (token == null) throw Exception('Token tidak tersedia');

    final response = await http.get(
      Uri.parse('$_baseUrl/project?ispmr='+isPMR), // Sesuaikan dengan endpoint API Anda
      headers: {
        'Authorization': token,
        'Accept': 'application/json',
      },
    );


    if (response.statusCode == 200) {
      final data = jsonDecode(response.body)['data'] as List;
      return data.map((project) {
        return DropdownItem(
          value: project['id'].toString(),
          displayText: project['nama_pro'],
        );
      }).toList();
    
    } 
    else if (response.statusCode == 401){
       throw Exception('Session Telah Habis');
    }
    else {
      throw Exception('Gagal memuat project: ${response.statusCode}');
    }
  } catch (e) {
    rethrow;
  }
}
}