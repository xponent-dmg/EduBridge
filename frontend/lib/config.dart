// App configuration (dotenv preferred; falls back to defaults)

final String backendBaseUrl = 'https://edubridge-xux6.onrender.com';

final String supabaseUrl = 'https://pvfernqzjurygimrveon.supabase.co';
final String supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB2ZmVybnF6anVyeWdpbXJ2ZW9uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY5MDM1MDksImV4cCI6MjA3MjQ3OTUwOX0.WxK3qU-x-gosvNH3YH00PIs6anQoRExKHBXvw_L05lc";


// Set to true after Supabase.initialize completes in main.dart.
// Use this instead of touching Supabase.instance in guard checks to avoid
// "Supabase should be initialized" errors during early app startup.
bool supabaseReady = false;
