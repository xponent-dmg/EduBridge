import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';

class AuthService {
  static Future<String?> signIn(String email, String password) async {
    if (!supabaseReady) return null;
    try {
      final c = Supabase.instance.client;
      final res = await c.auth.signInWithPassword(email: email, password: password);
      return res.session?.accessToken;
    } catch (e, st) {
      // ignore: avoid_print
      print('[AuthService] signIn error: $e\n$st');
      rethrow;
    }
  }

  static Future<String?> signUp(String email, String password) async {
    if (!supabaseReady) return null;
    try {
      final c = Supabase.instance.client;
      final res = await c.auth.signUp(email: email, password: password);
      return res.session?.accessToken;
    } catch (e, st) {
      // ignore: avoid_print
      print('[AuthService] signUp error: $e\n$st');
      rethrow;
    }
  }

  static String? get currentToken => supabaseReady ? Supabase.instance.client.auth.currentSession?.accessToken : null;
}
