import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app.dart';
import 'providers/providers.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

  try {
    // ignore: avoid_print
    print('[main] Starting app init');
    try {
      await dotenv.load(fileName: ".env");
      // ignore: avoid_print
      print('[main] .env loaded');
    } catch (e) {
      // ignore: avoid_print
      print('[main] .env not found or failed to load: $e');
    }
    await AuthService.initIfConfigured();
  } catch (e, st) {
    // ignore: avoid_print
    print('[main] Init error: $e\n$st');
  }

  // ignore: avoid_print
  print('[main] Running app');
  runApp(const AppProviders(child: MyApp()));
}
