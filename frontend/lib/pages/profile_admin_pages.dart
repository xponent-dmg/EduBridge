import 'package:flutter/material.dart';

import '../services/api_client.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.userId});
  final dynamic userId;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final api = ApiClient();
  Map<String, dynamic>? user;
  final skillsCtrl = TextEditingController();
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await api.get('/users/${widget.userId}');
    user = res['data'] as Map<String, dynamic>?;
    skillsCtrl.text = (user?['skills'] as List?)?.join(', ') ?? '';
    setState(() => loading = false);
  }

  Future<void> _saveSkills() async {
    final skills = skillsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    await api.patch('/users/${widget.userId}/skills', body: {'skills': skills});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Skills updated')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?['name'] ?? ''),
                  Text(user?['email'] ?? ''),
                  const SizedBox(height: 12),
                  TextField(
                    controller: skillsCtrl,
                    decoration: const InputDecoration(labelText: 'Skills (comma separated)'),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(onPressed: _saveSkills, child: const Text('Save Skills')),
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
