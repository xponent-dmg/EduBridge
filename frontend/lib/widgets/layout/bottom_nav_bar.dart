import 'package:flutter/material.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final String userRole;

  const AppBottomNavBar({super.key, required this.currentIndex, required this.userRole});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          items: _getNavItems(userRole),
          onTap: (index) => _onItemTapped(context, index, userRole),
        ),
      ),
    );
  }

  List<BottomNavigationBarItem> _getNavItems(String role) {
    if (role == 'student') {
      return [
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        const BottomNavigationBarItem(icon: Icon(Icons.task_alt), label: 'Tasks'),
        const BottomNavigationBarItem(icon: Icon(Icons.upload_file), label: 'Submissions'),
        const BottomNavigationBarItem(icon: Icon(Icons.work_outline), label: 'Portfolio'),
      ];
    } else if (role == 'company') {
      return [
        const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        const BottomNavigationBarItem(icon: Icon(Icons.task_alt), label: 'Tasks'),
        const BottomNavigationBarItem(icon: Icon(Icons.assignment_turned_in), label: 'Submissions'),
      ];
    } else if (role == 'admin') {
      return [
        const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        const BottomNavigationBarItem(icon: Icon(Icons.task), label: 'Tasks'),
        const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
        const BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Admin'),
      ];
    }

    // Default
    return [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      const BottomNavigationBarItem(icon: Icon(Icons.task_alt), label: 'Tasks'),
    ];
  }

  void _onItemTapped(BuildContext context, int index, String role) {
    if (index == currentIndex) return;

    if (role == 'student') {
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, '/dashboard');
          break;
        case 1:
          Navigator.pushReplacementNamed(context, '/tasks');
          break;
        case 2:
          Navigator.pushReplacementNamed(context, '/submissions');
          break;
        case 3:
          Navigator.pushReplacementNamed(context, '/portfolio');
          break;
      }
    } else if (role == 'company') {
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, '/dashboard');
          break;
        case 1:
          Navigator.pushReplacementNamed(context, '/tasks/create');
          break;
        case 2:
          Navigator.pushReplacementNamed(context, '/submissions/review');
          break;
      }
    } else if (role == 'admin') {
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, '/dashboard');
          break;
        case 1:
          Navigator.pushReplacementNamed(context, '/tasks');
          break;
        case 2:
          Navigator.pushReplacementNamed(context, '/users');
          break;
        case 3:
          Navigator.pushReplacementNamed(context, '/admin');
          break;
      }
    }
  }
}
