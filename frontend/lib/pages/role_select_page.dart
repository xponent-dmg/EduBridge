import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/common/app_button.dart';

class RoleSelectPage extends StatelessWidget {
  const RoleSelectPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFF5F7FA)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Logo and title
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)],
                ),
                child: const Icon(Icons.school, size: 60, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 16),
              Text(
                'EduBridge',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 8),
              Text('Choose your role to continue', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 40),

              // Role selection cards
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildRoleCard(
                        context,
                        title: 'Student',
                        description: 'Complete tasks, build your portfolio, and gain real-world experience',
                        icon: Icons.school,
                        color: AppTheme.primaryColor,
                        onTap: () => _selectRole(context, 'student'),
                      ),
                      const SizedBox(height: 16),
                      _buildRoleCard(
                        context,
                        title: 'Company',
                        description: 'Post tasks, review submissions, and find talented students',
                        icon: Icons.business,
                        color: AppTheme.secondaryColor,
                        onTap: () => _selectRole(context, 'company'),
                      ),
                      const SizedBox(height: 16),
                      _buildRoleCard(
                        context,
                        title: 'Admin',
                        description: 'Manage users, tasks, and platform settings',
                        icon: Icons.admin_panel_settings,
                        color: AppTheme.accentColor,
                        onTap: () => _selectRole(context, 'admin'),
                      ),
                    ],
                  ),
                ),
              ),

              // Sign in option
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account?'),
                    TextButton(onPressed: () => Navigator.pushNamed(context, '/auth'), child: const Text('Sign In')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _selectRole(BuildContext context, String role) {
    Navigator.pushNamed(context, '/dashboard', arguments: {'role': role});
  }
}
