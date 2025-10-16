import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pages/unified_auth_page.dart';
import 'pages/verify_otp_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/main_navigator.dart';
import 'pages/onboarding_page.dart';
import 'pages/profile_admin_pages.dart';
import 'pages/portfolio_page.dart';
import 'pages/submission_pages.dart';
import 'pages/role_select_page.dart';
import 'pages/splash_screen.dart';
import 'pages/tasks_pages.dart';
import 'providers/auth_provider.dart';
import 'theme/app_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: avoid_print
    print('[MyApp] Building MaterialApp');

    return MaterialApp(
      title: 'EduBridge',
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) {
          // ignore: avoid_print
          print('[Router] /');
          return const SplashScreen();
        },
        '/onboarding': (context) {
          // ignore: avoid_print
          print('[Router] /onboarding');
          return const OnboardingPage();
        },
        '/start': (context) {
          // ignore: avoid_print
          print('[Router] /start');
          return const RoleSelectPage();
        },
        '/auth': (context) {
          // ignore: avoid_print
          print('[Router] /auth');
          return const UnifiedAuthPage();
        },
        '/auth/verify-otp': (context) {
          // ignore: avoid_print
          print('[Router] /auth/verify-otp');
          final args = ModalRoute.of(context)?.settings.arguments;

          // Handle both String (email only) and Map (sign-up data) arguments
          if (args is Map<String, dynamic>) {
            return VerifyOtpPage(signUpData: args);
          } else if (args is String) {
            return VerifyOtpPage(email: args);
          }

          return const VerifyOtpPage(email: '');
        },
        '/auth/forgot': (context) {
          // ignore: avoid_print
          print('[Router] /auth/forgot');
          return const ForgotPasswordPage();
        },
        '/dashboard': (context) {
          // ignore: avoid_print
          print('[Router] /dashboard');
          final args = ModalRoute.of(context)?.settings.arguments;
          final authProvider = Provider.of<AuthProvider>(context, listen: false);

          if (args is Map && args['role'] != null) {
            // Mock mode
            authProvider.setMockUser(args['role'] as String);
          }

          // Use MainNavigator for bottom-nav pages (efficient indexed stack)
          return const MainNavigator();
        },
        '/tasks': (context) {
          // ignore: avoid_print
          print('[Router] /tasks');
          return const TaskListPage();
        },
        '/tasks/detail': (context) {
          // ignore: avoid_print
          print('[Router] /tasks/detail');
          final taskId = ModalRoute.of(context)?.settings.arguments;
          return TaskDetailPage(taskId: taskId);
        },
        '/tasks/create': (context) {
          // ignore: avoid_print
          print('[Router] /tasks/create');
          final companyId = ModalRoute.of(context)?.settings.arguments;
          return CreateTaskPage(companyId: companyId);
        },
        '/company/tasks': (context) {
          // ignore: avoid_print
          print('[Router] /company/tasks');
          final companyId = ModalRoute.of(context)?.settings.arguments;
          if (companyId == null || (companyId is String && companyId.isEmpty)) {
            return const Scaffold(body: Center(child: Text('Company ID is required')));
          }
          return CompanyTasksPage(companyId: companyId);
        },
        '/submissions': (context) {
          // ignore: avoid_print
          print('[Router] /submissions');
          return const MySubmissionsPage();
        },
        '/submissions/create': (context) {
          // ignore: avoid_print
          print('[Router] /submissions/create');
          final taskId = ModalRoute.of(context)?.settings.arguments;
          return CreateSubmissionPage(taskId: taskId);
        },
        '/submissions/review': (context) {
          // ignore: avoid_print
          print('[Router] /submissions/review');
          final taskId = ModalRoute.of(context)?.settings.arguments;
          return ReviewSubmissionsPage(taskId: taskId);
        },
        '/portfolio': (context) {
          // ignore: avoid_print
          print('[Router] /portfolio');
          final userId =
              ModalRoute.of(context)?.settings.arguments ??
              Provider.of<AuthProvider>(context, listen: false).currentUser?.userId;
          return PortfolioPage(userId: userId);
        },
        '/profile': (context) {
          print('[Router] /profile');
          final userId =
              ModalRoute.of(context)?.settings.arguments ??
              Provider.of<AuthProvider>(context, listen: false).currentUser?.userId;
          return ProfilePage(userId: userId);
        },
        '/admin': (context) {
          // ignore: avoid_print
          print('[Router] /admin');
          return const AdminPage();
        },
      },
    );
  }
}
