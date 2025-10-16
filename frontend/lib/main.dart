import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    await AuthService.initIfConfigured();
  } catch (e, st) {
    // ignore: avoid_print
    print('[main] Init error: $e\n$st');
  }

  // ignore: avoid_print
  print('[main] Running app');
  runApp(const AppProviders(child: MyApp()));
}
