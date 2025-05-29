// services/session_service.dart
import 'dart:ffi';

import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  // Define proper key names as constants
  static const String _tokenKey = 'auth_token';
  static const String _emailKey = 'user_email';
  static const String _idKey = '';
  static const String _jenisUserKey = 'user_jenis';
  static const String _divisiKey = 'user_divisi';
  static const String _nameKey = 'user_name';

  static Future<void> 
  saveSession({
    required String token,
    required String name,
    required String email,
    required String jenisUser,
    required String id,
    required String divisi,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString(_tokenKey, token),
        prefs.setString(_nameKey, name),
        prefs.setString(_emailKey, email),
        prefs.setString(_jenisUserKey, jenisUser),
        prefs.setString(_divisiKey, divisi),
        prefs.setString(_idKey, id),
      ]);
    } catch (e) {
      throw Exception('Failed to save session: $e');
    }
  }

  static Future<String?> getToken() async {
    // SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getName() async {
    // SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

    static Future<String?> getID() async {
    // SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_idKey);
  }


  static Future<String?> getEmail() async {
    // SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }


  static Future<String?> getJenisUser() async {
    // SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_jenisUserKey);
  }

  static Future<String?> getDivisi() async {
    // SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_divisiKey);
  }

  static Future<void> clearSession() async {
    try {
      // SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove(_tokenKey),
        prefs.remove(_jenisUserKey),
        prefs.remove(_divisiKey),
        prefs.remove(_nameKey),
        prefs.remove(_emailKey),
        prefs.remove(_idKey),
      ]);

      
    } catch (e) {
      throw Exception('Failed to clear session: $e');
    }
  }

  // Helper method to check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}