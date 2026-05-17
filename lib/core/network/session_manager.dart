import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionManager {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Save auth token
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  // Get auth token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  // Delete token (on logout)
  Future<void> clearSession() async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userKey);
  }

  // Save User profile metadata (for fast offline reads)
  Future<void> saveUser(Map<String, dynamic> userMap) async {
    final String userJson = jsonEncode(userMap);
    await _secureStorage.write(key: _userKey, value: userJson);
  }

  // Read offline User profile
  Future<Map<String, dynamic>?> getUser() async {
    final String? userJson = await _secureStorage.read(key: _userKey);
    if (userJson != null) {
      return jsonDecode(userJson) as Map<String, dynamic>;
    }
    return null;
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final String? token = await getToken();
    return token != null;
  }
}
