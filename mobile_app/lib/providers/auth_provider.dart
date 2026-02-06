import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;
  String? _token;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      final data = await _authService.login(email, password);
      _token = data['token'];
      _user = User.fromJson(data['user']);
      await _saveDataToPrefs();
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signup(String email, String password, String role) async {
    _setLoading(true);
    try {
      final data = await _authService.signup(email, password, role);
      _token = data['token'];
      _user = User.fromJson(data['user']);
      await _saveDataToPrefs();
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _token = null;
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('auth_token')) return;

    _token = prefs.getString('auth_token');
    // In a real app, you might want to fetch user profile here using the token
    // For now, we will just assume logged in, but we lack User object. 
    // Ideally, we persist User object or fetch it.
    // Let's implement basics:
    final userId = prefs.getString('user_id');
    final email = prefs.getString('user_email');
    final role = prefs.getString('user_role');
    
    if (userId != null) {
      _user = User(
        id: prefs.getString('user_mongo_id') ?? '',
        userId: userId,
        email: email ?? '',
        role: role ?? 'user'
      );
    }
    
    notifyListeners();
  }

  Future<void> _saveDataToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) await prefs.setString('auth_token', _token!);
    if (_user != null) {
      await prefs.setString('user_mongo_id', _user!.id);
      await prefs.setString('user_id', _user!.userId);
      await prefs.setString('user_email', _user!.email);
      await prefs.setString('user_role', _user!.role);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
