import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  bool get isAdmin => _user?['role'] == 'admin';
  bool get isDokter => _user?['role'] == 'dokter';
  bool get isTerapis => _user?['role'] == 'terapis';
  bool get isAuthenticated => _token != null;
  bool get hasCompletedQna => _user?['hasCompletedQna'] ?? false;

  Future<void> loadUser() async {
    print('Memulai loadUser..');
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      print('Token dari sharedPreferences: $_token');

      final userString = prefs.getString('user');
      if (userString != null) {
        _user = jsonDecode(userString);
        print('User data: $user');
      } else {
        print('Tidak ada data user di SharedPreferences');
        _token = null;
      }
    } catch (e) {
      print('Error loading user: $e');
      _token = null;
      _user = null;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user');
    } finally {
      notifyListeners();
    }
  }

  Future<void> login(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('token', token);
    await prefs.setString('user', jsonEncode(user));

    _token = token;
    _user = user;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    _token = null;
    _user = null;
    notifyListeners();
  }
}