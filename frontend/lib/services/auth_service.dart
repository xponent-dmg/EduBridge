import 'package:supabase_flutter/supabase_flutter.dart';

import '../config.dart';

class AuthService {
  static Future<void> initIfConfigured() async {
    if (!isSupabaseConfigured) {
      // ignore: avoid_print
      // Using print to ensure logs show up even in release; debugPrint can be throttled
      print('[AuthService] Supabase not configured; skipping init');
      return;
    }
    try {
      if (!Supabase.instance.isInitialized) {
        // ignore: avoid_print
        print('[AuthService] Initializing Supabase... url=$supabaseUrl');
        await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
        // ignore: avoid_print
        print('[AuthService] Supabase initialized');
      } else {
        // ignore: avoid_print
        print('[AuthService] Supabase already initialized');
      }
    } catch (e, st) {
      // ignore: avoid_print
      print('[AuthService] Supabase init failed: $e\n$st');
      rethrow;
    }
  }

  static bool get isInitialized => isSupabaseConfigured && Supabase.instance.isInitialized;

  static Future<SupabaseClient?> ensureClient() async {
    if (!isSupabaseConfigured) {
      // ignore: avoid_print
      print('[AuthService] ensureClient: not configured');
      return null;
    }
    if (!Supabase.instance.isInitialized) {
      // ignore: avoid_print
      print('[AuthService] ensureClient: initializing on-demand');
      await initIfConfigured();
    }
    return Supabase.instance.client;
  }

  static Future<String?> signIn(String email, String password) async {
    if (!isSupabaseConfigured) return null;
    try {
      final c = await ensureClient();
      final res = await c!.auth.signInWithPassword(email: email, password: password);
      return res.session?.accessToken;
    } catch (e, st) {
      // ignore: avoid_print
      print('[AuthService] signIn error: $e\n$st');
      rethrow;
    }
  }

  static Future<String?> signUp(String email, String password) async {
    if (!isSupabaseConfigured) return null;
    try {
      final c = await ensureClient();
      final res = await c!.auth.signUp(email: email, password: password);
      return res.session?.accessToken;
    } catch (e, st) {
      // ignore: avoid_print
      print('[AuthService] signUp error: $e\n$st');
      rethrow;
    }
  }

  static String? get currentToken => isInitialized ? Supabase.instance.client.auth.currentSession?.accessToken : null;
}
