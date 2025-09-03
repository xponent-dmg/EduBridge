// App configuration

// Backend base URL. Override at runtime with: --dart-define=BACKEND_URL=http://10.0.2.2:5050
const String backendBaseUrl = String.fromEnvironment('BACKEND_URL', defaultValue: 'http://localhost:5050');

// Supabase configuration. Provide via --dart-define or leave empty to disable auth UI.
const String supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
const String supabaseAnonKey = String.fromEnvironment('SUPABASE_SERVICE_ROLE_KEY', defaultValue: '');

bool get isSupabaseConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
