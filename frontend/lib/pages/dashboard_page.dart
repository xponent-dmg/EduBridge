import 'package:flutter/material.dart';

import '../services/api_client.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key, this.authToken});
  final String? authToken;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final ApiClient api;
  Map<String, dynamic>? me; // fetched user model
  Map<String, dynamic>? edupoints; // balance and txs
  bool loading = true;

  @override
  void initState() {
    super.initState();
    api = ApiClient(authToken: widget.authToken);
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      // For demo: fetch all users and pick first as current if no auth user endpoint exists
      final users = await api.get('/users');
      final list = (users['data'] as List?) ?? [];
      me = list.isNotEmpty ? list.first as Map<String, dynamic> : null;

      if (me != null) {
        final tx = await api.get('/edupoints/${me!['user_id']}');
        edupoints = tx['data'] as Map<String, dynamic>;
      }
    } catch (_) {
      // ignore in minimal UI
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = me?['role'] ?? 'student';
    return Scaffold(
      appBar: AppBar(title: const Text('EduBridge')),
      drawer: _NavDrawer(role: role),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  Text('Welcome ${me?['name'] ?? ''}', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  if (edupoints != null)
                    Card(
                      child: ListTile(
                        title: const Text('EduPoints Balance'),
                        subtitle: Text('${edupoints!['balance'] ?? 0}'),
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (role == 'student') _StudentSection(api: api),
                  if (role == 'company') _CompanySection(api: api, companyId: me?['user_id']),
                  if (role == 'admin') _AdminSection(api: api),
                ],
              ),
            ),
    );
  }
}

class _StudentSection extends StatefulWidget {
  const _StudentSection({required this.api});
  final ApiClient api;

  @override
  State<_StudentSection> createState() => _StudentSectionState();
}

class _StudentSectionState extends State<_StudentSection> {
  List tasks = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await widget.api.get('/tasks');
      tasks = (res['data'] as List?) ?? [];
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Available Tasks', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (loading) const LinearProgressIndicator(),
        ...tasks
            .take(5)
            .map(
              (t) => Card(
                child: ListTile(
                  title: Text(t['title'] ?? ''),
                  subtitle: Text((t['domains'] as List?)?.join(', ') ?? ''),
                  onTap: () => Navigator.pushNamed(context, '/tasks/detail', arguments: t['task_id']),
                ),
              ),
            ),
        TextButton(onPressed: () => Navigator.pushNamed(context, '/tasks'), child: const Text('View all tasks')),
      ],
    );
  }
}

class _CompanySection extends StatelessWidget {
  const _CompanySection({required this.api, required this.companyId});
  final ApiClient api;
  final dynamic companyId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Company Tools', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/tasks/create', arguments: companyId),
              icon: const Icon(Icons.add),
              label: const Text('Post Task'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.pushNamed(context, '/company/tasks', arguments: companyId),
              child: const Text('View Posted Tasks'),
            ),
          ],
        ),
      ],
    );
  }
}

class _AdminSection extends StatelessWidget {
  const _AdminSection({required this.api});
  final ApiClient api;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Admin', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        FilledButton.tonal(onPressed: () => Navigator.pushNamed(context, '/admin'), child: const Text('Open Admin')),
      ],
    );
  }
}

class _NavDrawer extends StatelessWidget {
  const _NavDrawer({required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(child: Text('EduBridge')),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Dashboard'),
            onTap: () => Navigator.pushReplacementNamed(context, '/dashboard'),
          ),
          ListTile(
            leading: const Icon(Icons.task),
            title: const Text('Tasks'),
            onTap: () => Navigator.pushNamed(context, '/tasks'),
          ),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('My Submissions'),
            onTap: () => Navigator.pushNamed(context, '/submissions'),
          ),
          ListTile(
            leading: const Icon(Icons.work_outline),
            title: const Text('Portfolio'),
            onTap: () => Navigator.pushNamed(context, '/portfolio'),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(role == 'admin' ? 'Admin' : 'Profile'),
            onTap: () => Navigator.pushNamed(context, role == 'admin' ? '/admin' : '/profile'),
          ),
        ],
      ),
    );
  }
}
