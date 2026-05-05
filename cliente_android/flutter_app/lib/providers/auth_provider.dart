import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../services/api_config.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      _user = UserModel.fromJson(jsonDecode(userJson));
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = UserModel.fromJson(data['user']);
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user', jsonEncode(_user!.toJson()));
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error login: $e');
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String phone,
    required String name,
    required String password,
    required String confirmPassword,
    required String birthdate,
  }) async {
    if (password != confirmPassword) return false;

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.register),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'phone': phone,
          'name': name,
          'password': password,
          'birthdate': birthdate,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error registro: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    notifyListeners();
  }

  Future<bool> updatePasswordByPhone(String phone, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.reset),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'password': newPassword,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error reset pass: $e');
      return false;
    }
  }
}
