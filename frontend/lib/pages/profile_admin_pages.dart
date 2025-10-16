import 'package:flutter/material.dart';

import '../services/api_client.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, this.userId});

  final dynamic userId;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final api = ApiClient();
  // Map<String, dynamic>? user;
  final skillsCtrl = TextEditingController();
  Map<String, dynamic>? me;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      // ignore: avoid_print
      print('[Dashboard] Loading current user and edupoints');
      // Demo mode: try to pick a user by desired role; if none exists, create one
      final desiredRole = 'student';
      final users = await api.get('/users');
      final list = (users['data'] as List?) ?? [];
      final candidates = list.where((u) => (u as Map)['role'] == desiredRole).toList();
      if (candidates.isNotEmpty) {
        me = candidates.first as Map<String, dynamic>;
      } else {
        // create demo user for this role
        final millis = DateTime.now().millisecondsSinceEpoch;
        final created = await api.post(
          '/users',
          body: {
            'name': 'Demo ${desiredRole[0].toUpperCase()}${desiredRole.substring(1)}',
            'email': 'demo_${desiredRole}_$millis@example.com',
            'role': desiredRole,
          },
        );
        me = created['data'] as Map<String, dynamic>?;
      }
    } catch (_) {
      // ignore in minimal UI
      // ignore: avoid_print
      print('[Dashboard] Failed to load user/edupoints');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _saveSkills(userId) async {
    final skills = skillsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    await api.patch('/users/$userId/skills', body: {'skills': skills});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Skills updated')));
  }

  @override
  Widget build(BuildContext context) {
    final userId = widget.userId ?? ModalRoute.of(context)?.settings.arguments;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(me?['name'] ?? ''),
                  Text(me?['email'] ?? ''),
                  const SizedBox(height: 12),
                  TextField(
                    controller: skillsCtrl,
                    decoration: const InputDecoration(labelText: 'Skills (comma separated)'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => _saveSkills(userId ?? me?['user_id']),
                    child: const Text('Save Skills'),
                  ),
                ],
              ),
            ),
    );
  }
}

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final api = ApiClient();
  List users = [];
  List tasks = [];
  List submissions = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final resUsers = await api.get('/users');
      users = (resUsers['data'] as List?) ?? [];
      final resTasks = await api.get('/tasks');
      tasks = (resTasks['data'] as List?) ?? [];
      // Minimal: show counts only; submissions listing would need extra endpoint
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _StatCard(title: 'Users', value: users.length.toString()),
                  _StatCard(title: 'Tasks', value: tasks.length.toString()),
                  _StatCard(title: 'Submissions', value: '—'),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        width: 220,
        height: 120,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
        ),
      ),
    );
  }
}
