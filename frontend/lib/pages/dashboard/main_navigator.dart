import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/layout/app_scaffold.dart';
import 'dashboard_page.dart';
import '../tasks/tasks_pages.dart';
import '../submissions/submission_pages.dart';
import '../portfolio/portfolio_page.dart';
import '../profile/profile_admin_pages.dart';

/// MainNavigator holds an indexed page stack for efficient bottom nav rendering.
/// Only renders the active page; avoids rebuilding inactive pages.
class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  // Keep page widgets alive by storing them
  final List<Widget> _cachedPages = [];
  String? _lastUserId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize pages once
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.userId;
    final userRole = authProvider.currentUser?.role ?? 'student';
    final isCompany = userRole == 'company';

    if (_cachedPages.isEmpty) {
      if (isCompany) {
        _cachedPages.addAll([const DashboardPage(), const TaskListPage(), ProfilePage(userId: userId)]);
      } else {
        _cachedPages.addAll([
          const DashboardPage(),
          const TaskListPage(),
          const MySubmissionsPage(),
          PortfolioPage(userId: userId),
        ]);
      }
      _lastUserId = userId;
    } else if (_lastUserId != userId) {
      // Update pages that depend on userId when auth changes
      if (isCompany) {
        _cachedPages[2] = ProfilePage(userId: userId);
      } else {
        _cachedPages[3] = PortfolioPage(userId: userId);
      }
      _lastUserId = userId;
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final userRole = authProvider.currentUser?.role ?? 'student';

    return ExternalNavScope(
      hasBottomNav: true,
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _cachedPages),
        bottomNavigationBar: _buildBottomNav(userRole),
      ),
    );
  }

  Widget _buildBottomNav(String userRole) {
    final isCompany = userRole == 'company';

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _currentIndex,
      onTap: _onTabTapped,
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey,
      items: isCompany
          ? const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
              BottomNavigationBarItem(icon: Icon(Icons.task_alt), label: 'Tasks'),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
            ]
          : const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
              BottomNavigationBarItem(icon: Icon(Icons.task_alt), label: 'Tasks'),
              BottomNavigationBarItem(icon: Icon(Icons.upload_file), label: 'Submissions'),
              BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Portfolio'),
            ],
    );
  }
}
