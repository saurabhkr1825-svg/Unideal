import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../services/supabase_auth_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseAuthService _authService = SupabaseAuthService();
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      final response = await _authService.login(email, password);
      if (response.user != null) {
        await _mapSupabaseUserToModel(response.user!);
      }
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signup(String email, String password, String fullName, String role) async {
    _setLoading(true);
    try {
      final response = await _authService.signup(
        email, 
        password, 
        data: {
          'full_name': fullName,
          'role': role,
        },
      );
      if (response.user != null) {
        await _mapSupabaseUserToModel(response.user!);
      }
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
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    try {
      final session = _authService.currentSession;
      if (session != null && _authService.currentUser != null) {
        await _mapSupabaseUserToModel(_authService.currentUser!);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Auto-login error: $e");
      // Don't rethrow, just let it fail silently so app proceeds to Login
    }
  }

  Future<void> updateProfile({required String fullName, required String phone}) async {
    if (_user == null) return;
    _setLoading(true);
    try {
      await _authService.updateProfile(_user!.id, {
        'full_name': fullName,
        'phone': phone,
      });
      // Refresh local user data
      await _mapSupabaseUserToModel(_authService.currentUser!);
      notifyListeners();
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> reloadUser() async {
    try {
      if (_authService.currentUser != null) {
        await _mapSupabaseUserToModel(_authService.currentUser!);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error reloading user: $e");
    }
  }

  Future<void> _mapSupabaseUserToModel(supabase.User sbUser) async {
    final profile = await _authService.getProfile(sbUser.id);
    if (profile != null) {
      _user = User.fromJson(profile, sbUser.email ?? '');
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
