import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> signUp(String email, String password) async {
    final response = await _client.auth.signUp(email, password);
    if (response.error != null) {
      throw response.error!;
    }
  }

  Future<void> signIn(String email, String password) async {
    final response = await _client.auth.signIn(email: email, password: password);
    if (response.error != null) {
      throw response.error!;
    }
  }

  Future<void> signOut() async {
    final response = await _client.auth.signOut();
    if (response.error != null) {
      throw response.error!;
    }
  }
}
