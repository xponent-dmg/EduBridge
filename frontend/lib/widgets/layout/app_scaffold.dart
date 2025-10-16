import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import 'bottom_nav_bar.dart';

class ExternalNavScope extends InheritedWidget {
  final bool hasBottomNav;
  const ExternalNavScope({super.key, required this.hasBottomNav, required Widget child}) : super(child: child);

  static ExternalNavScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ExternalNavScope>();
  }

  @override
  bool updateShouldNotify(covariant ExternalNavScope oldWidget) => hasBottomNav != oldWidget.hasBottomNav;
}

class AppScaffold extends StatelessWidget {
  final Widget body;
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool showBottomNav;
  final int currentIndex;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? drawer;
  final PreferredSizeWidget? customAppBar;

  const AppScaffold({
    super.key,
    required this.body,
    this.title = 'EduBridge',
    this.actions,
    this.showBackButton = true,
    this.showBottomNav = true,
    this.currentIndex = 0,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.drawer,
    this.customAppBar,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.currentUser?.role ?? 'student';
    final externalBottomNav = ExternalNavScope.maybeOf(context)?.hasBottomNav ?? false;

    return Scaffold(
      // appBar: customAppBar ?? AppBar(title: Text(title), automaticallyImplyLeading: showBackButton, actions: actions),
      drawer: drawer,
      body: SafeArea(child: body),
      bottomNavigationBar: (showBottomNav && !externalBottomNav)
          ? AppBottomNavBar(currentIndex: currentIndex, userRole: userRole)
          : null,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
    );
  }
}
