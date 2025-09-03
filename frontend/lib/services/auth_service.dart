import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';

class AuthService {
  static Future<void> initIfConfigured() async {
    if (!isSupabaseConfigured) return;
    if (!Supabase.instance.isInitialized) {
      await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    }
  }

  static SupabaseClient? get client => isSupabaseConfigured ? Supabase.instance.client : null;

  static Future<String?> signIn(String email, String password) async {
    if (!isSupabaseConfigured) return null;
    final res = await client!.auth.signInWithPassword(email: email, password: password);
    return res.session?.accessToken;
  }

  static Future<String?> signUp(String email, String password) async {
    if (!isSupabaseConfigured) return null;
    final res = await client!.auth.signUp(email: email, password: password);
    return res.session?.accessToken;
  }

  static String? get currentToken => client?.auth.currentSession?.accessToken;
}
