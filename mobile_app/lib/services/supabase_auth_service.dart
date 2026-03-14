import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<AuthResponse> signup(String email, String password, {required Map<String, dynamic> data}) async {
    final AuthResponse res = await _client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
    return res;
  }

  Future<AuthResponse> login(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  Future<void> sendPasswordReset(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    return await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .single();
  }

  Future<String?> getAdminId() async {
    final response = await _client
        .from('profiles')
        .select('id')
        .eq('role', 'admin')
        .limit(1)
        .maybeSingle();
    return response?['id'];
  }

  User? get currentUser => _client.auth.currentUser;

  Session? get currentSession => _client.auth.currentSession;
  
  Future<void> updateProfile(String userId, Map<String, dynamic> updates) async {
    await _client
        .from('profiles')
        .update(updates)
        .eq('id', userId);
  }

  Map<String, dynamic>? get userMetadata => _client.auth.currentUser?.userMetadata;
}
