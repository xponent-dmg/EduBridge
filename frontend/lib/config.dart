// App configuration (dotenv preferred; falls back to defaults)
import 'package:flutter_dotenv/flutter_dotenv.dart';

final String backendBaseUrl = dotenv.env['BACKEND_URL'] ?? 'https://edubridge-xux6.onrender.com';

final String supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 'https://pvfernqzjurygimrveon.supabase.co';
final String supabaseAnonKey =
    dotenv.env['SUPABASE_ANON_KEY'] ??
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB2ZmVybnF6anVyeWdpbXJ2ZW9uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY5MDM1MDksImV4cCI6MjA3MjQ3OTUwOX0.WxK3qU-x-gosvNH3YH00PIs6anQoRExKHBXvw_L05lc";

bool get isSupabaseConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
