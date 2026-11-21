import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/env.dart';
import '../models/app_profile.dart';

class AuthService {
  AuthService(this._client);

  final SupabaseClient _client;

  Stream<AuthState> get authChanges => _client.auth.onAuthStateChange;

  Future<void> signIn(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<bool> signUp(String name, String email, String password) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
    );
    return response.session != null;
  }

  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: Env.authRedirect,
    );
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<AppProfile?> fetchProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select('id, email, full_name, roles(name)')
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    return AppProfile.fromMap(row);
  }
}
