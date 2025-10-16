import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import 'auth_provider.dart';
import 'edupoints_provider.dart';
import 'portfolio_provider.dart';
import 'submission_provider.dart';
import 'task_provider.dart';
import 'user_provider.dart';

class AppProviders extends StatelessWidget {
  final Widget child;

  const AppProviders({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),

        ProxyProvider<AuthProvider, ApiClient>(update: (_, auth, __) => ApiClient(authToken: auth.token)),

        ChangeNotifierProxyProvider<ApiClient, TaskProvider>(
          create: (context) => TaskProvider(apiClient: Provider.of<ApiClient>(context, listen: false)),
          update: (_, apiClient, previous) => previous ?? TaskProvider(apiClient: apiClient),
        ),

        ChangeNotifierProxyProvider<ApiClient, SubmissionProvider>(
          create: (context) => SubmissionProvider(apiClient: Provider.of<ApiClient>(context, listen: false)),
          update: (_, apiClient, previous) => previous ?? SubmissionProvider(apiClient: apiClient),
        ),

        ChangeNotifierProxyProvider<ApiClient, PortfolioProvider>(
          create: (context) => PortfolioProvider(apiClient: Provider.of<ApiClient>(context, listen: false)),
          update: (_, apiClient, previous) => previous ?? PortfolioProvider(apiClient: apiClient),
        ),

        ChangeNotifierProxyProvider<ApiClient, EdupointsProvider>(
          create: (context) => EdupointsProvider(apiClient: Provider.of<ApiClient>(context, listen: false)),
          update: (_, apiClient, previous) => previous ?? EdupointsProvider(apiClient: apiClient),
        ),

        ChangeNotifierProxyProvider<ApiClient, UserProvider>(
          create: (context) => UserProvider(apiClient: Provider.of<ApiClient>(context, listen: false)),
          update: (_, apiClient, previous) => previous ?? UserProvider(apiClient: apiClient),
        ),
      ],
      child: child,
    );
  }
}
