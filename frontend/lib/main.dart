import 'package:flutter/material.dart';

import 'pages/auth_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/profile_admin_pages.dart';
import 'pages/portfolio_page.dart';
import 'pages/submission_pages.dart';
import 'pages/tasks_pages.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.initIfConfigured();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EduBridge',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal)),
      initialRoute: '/auth',
      routes: {
        '/auth': (context) => const AuthPage(),
        '/dashboard': (context) {
          final token = ModalRoute.of(context)?.settings.arguments as String?;
          return DashboardPage(authToken: token);
        },
        '/tasks': (context) => const TaskListPage(),
        '/tasks/detail': (context) {
          final taskId = ModalRoute.of(context)?.settings.arguments;
          return TaskDetailPage(taskId: taskId);
        },
        '/tasks/create': (context) {
          final companyId = ModalRoute.of(context)?.settings.arguments;
          return CreateTaskPage(companyId: companyId);
        },
        '/submissions': (context) => const MySubmissionsPage(),
        '/submissions/create': (context) {
          final taskId = ModalRoute.of(context)?.settings.arguments;
          // Minimal: userId would come from session; using 1 as placeholder
          return CreateSubmissionPage(taskId: taskId, userId: 1);
        },
        '/portfolio': (context) {
          // Minimal: userId placeholder; wire actual after auth/user endpoint
          return const PortfolioPage(userId: 1);
        },
        '/profile': (context) => const ProfilePage(userId: 1),
        '/admin': (context) => const AdminPage(),
      },
    );
  }
}
