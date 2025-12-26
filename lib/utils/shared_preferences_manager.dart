import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesManager {
  static const String _keyRememberMe = 'remember_me';
  static const String _keyLoginData = 'login_data';
  static const String _keyUserId = 'user_id';
  static const String _keyPassword = 'password';

  // Save Remember Me preference
  static Future<void> setRememberMe(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberMe, value);
  }

  // Get Remember Me preference
  static Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyRememberMe) ?? false;
  }

  // Save login data (whole response)
  static Future<void> saveLoginData(Map<String, dynamic> loginData) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(loginData);
    await prefs.setString(_keyLoginData, jsonString);
  }

  // Get saved login data
  static Future<Map<String, dynamic>?> getLoginData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyLoginData);
    if (jsonString != null) {
      try {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Save user credentials (for Remember Me)
  static Future<void> saveUserCredentials({
    required String userId,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
    await prefs.setString(_keyPassword, password);
  }

  // Get saved user credentials
  static Future<Map<String, String>?> getUserCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_keyUserId);
    final password = prefs.getString(_keyPassword);

    if (userId != null && password != null) {
      return {'userId': userId, 'password': password};
    }
    return null;
  }

  // Clear all saved data
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRememberMe);
    await prefs.remove(_keyLoginData);
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyPassword);
    await prefs.remove('token');
  }

  // Clear only login data (keep credentials if Remember Me is checked)
  static Future<void> clearLoginData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLoginData);
  }

  // Clear only credentials
  static Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyPassword);
  }

  // Save token directly
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  // Get token from saved login data or direct token storage
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    // First try direct token storage
    final directToken = prefs.getString('token');
    if (directToken != null && directToken.isNotEmpty) {
      return directToken;
    }
    // Fallback to login data
    final loginData = await getLoginData();
    if (loginData != null && loginData['token'] != null) {
      return loginData['token'] as String?;
    }
    return null;
  }

  // Save staff ID
  static Future<void> saveStaffId(String staffId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('staff_id', staffId);
  }

  // Get staff ID
  static Future<String?> getStaffId() async {
    final prefs = await SharedPreferences.getInstance();
    // First try direct storage
    final directStaffId = prefs.getString('staff_id');
    if (directStaffId != null && directStaffId.isNotEmpty) {
      return directStaffId;
    }
    // Fallback to login data
    final loginData = await getLoginData();
    if (loginData != null) {
      // Check various keys where user data might be stored
      Map<String, dynamic>? userData;
      if (loginData['staff'] is Map) {
        userData = loginData['staff'] as Map<String, dynamic>;
      } else if (loginData['user'] is Map) {
        userData = loginData['user'] as Map<String, dynamic>;
      } else if (loginData['data'] is Map) {
        userData = loginData['data'] as Map<String, dynamic>;
      } else if (loginData.containsKey('_id') || loginData.containsKey('id')) {
        // The loginData itself might be the user object
        userData = loginData;
      }

      if (userData != null) {
        return (userData['_id'] ?? userData['id']) as String?;
      }
    }
    return null;
  }

  // Save user role
  static Future<void> saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);
  }

  // Get user role
  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    // First try direct storage
    final directRole = prefs.getString('user_role');
    if (directRole != null && directRole.isNotEmpty) {
      return directRole;
    }
    // Fallback to login data
    final loginData = await getLoginData();
    if (loginData != null && loginData['role'] != null) {
      return loginData['role'] as String?;
    }
    return null;
  }

  // Save FCM token
  static Future<void> saveFcmToken(String fcmToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fcm_token', fcmToken);
  }

  // Get FCM token
  static Future<String?> getFcmToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('fcm_token');
  }
}
