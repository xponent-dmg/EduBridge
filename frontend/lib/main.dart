import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'providers/providers.dart';
import 'config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  try {
    // ignore: avoid_print
    print('[main] Starting app init');

    print('[main] Initializing Supabase with URL: $supabaseUrl');
    print('[main] Initializing Supabase with Anon Key: $supabaseAnonKey');
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    print('[main] Supabase initialized successfully');
  } catch (e, st) {
    // ignore: avoid_print
    print('[main] Supabase init error: $e\n$st');
  }

  // Set global flag AFTER initialization completes (success or failure)
  supabaseReady = true;

  // ignore: avoid_print
  print('[main] Running app');
  runApp(const AppProviders(child: MyApp()));
}
