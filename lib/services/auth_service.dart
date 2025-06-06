import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl =
      'https://fakelocation.warungkode.com/api'; 

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/users/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final message = jsonDecode(response.body)['errors']['general'][0];
      throw Exception(message ?? 'Login failed');
    }
  }

  static Future<Map<String,dynamic>> logout({
    required String? token,
    required String? email,
  }) async {
    final url = Uri.parse('$baseUrl/users/logout');
    Duration timeout = const Duration(seconds: 10);
    try {
      final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': token, 'email' :email }),
      ).timeout(timeout);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
      final message = jsonDecode(response.body)['errors']['general'][0];
      throw Exception(message ?? 'Log Out Failed');
    }
    } catch (e) {
        throw Exception(e);
    }
     
  }
}
