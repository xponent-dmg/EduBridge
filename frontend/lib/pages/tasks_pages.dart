import 'package:flutter/material.dart';

import '../services/api_client.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  final api = ApiClient();
  List tasks = [];
  bool loading = true;
  String domainFilter = '';
  RangeValues effortFilter = const RangeValues(0, 40);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await api.get('/tasks');
    tasks = (res['data'] as List?) ?? [];
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = tasks.where((t) {
      final domains = (t['domains'] as List?)?.cast<String>() ?? [];
      final effort = (t['effort_hours'] ?? 0) as num;
      final matchesDomain = domainFilter.isEmpty || domains.contains(domainFilter);
      final matchesEffort = effort >= effortFilter.start && effort <= effortFilter.end;
      return matchesDomain && matchesEffort;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(labelText: 'Filter by domain'),
                    onChanged: (v) => setState(() => domainFilter = v.trim()),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Effort:'),
                Expanded(
                  child: RangeSlider(
                    values: effortFilter,
                    min: 0,
                    max: 80,
                    divisions: 16,
                    labels: RangeLabels('${effortFilter.start.toInt()}', '${effortFilter.end.toInt()}'),
                    onChanged: (v) => setState(() => effortFilter = v),
                  ),
                ),
              ],
            ),
          ),
          if (loading) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final t = filtered[i];
                return Card(
                  child: ListTile(
                    title: Text(t['title'] ?? ''),
                    subtitle: Text((t['domains'] as List?)?.join(', ') ?? ''),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pushNamed(context, '/tasks/detail', arguments: t['task_id']),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TaskDetailPage extends StatefulWidget {
  const TaskDetailPage({super.key, required this.taskId});
  final dynamic taskId;

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  final api = ApiClient();
  Map<String, dynamic>? task;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await api.get('/tasks/${widget.taskId}');
    task = res['data'] as Map<String, dynamic>?;
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task Detail')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task?['title'] ?? '', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(task?['description'] ?? ''),
                  const SizedBox(height: 8),
                  Text('Domains: ${(task?['domains'] as List?)?.join(', ') ?? ''}'),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pushNamed(context, '/submissions/create', arguments: task?['task_id']),
                      child: const Text('Submit Solution'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class CreateTaskPage extends StatefulWidget {
  const CreateTaskPage({super.key, required this.companyId});
  final dynamic companyId;

  @override
  State<CreateTaskPage> createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  final api = ApiClient();
  final _formKey = GlobalKey<FormState>();
  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final domainsCtrl = TextEditingController();
  double effort = 2;
  DateTime? expiry;
  bool loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      await api.post(
        '/tasks',
        body: {
          'company_id': widget.companyId,
          'title': titleCtrl.text.trim(),
          'description': descCtrl.text.trim(),
          'domains': domainsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
          'effort_hours': effort.toInt(),
          'expiry_date': expiry?.toIso8601String(),
        },
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task created')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Task')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              TextFormField(
                controller: descCtrl,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextFormField(
                controller: domainsCtrl,
                decoration: const InputDecoration(labelText: 'Domains (comma separated)'),
              ),
              const SizedBox(height: 12),
              Text('Effort Hours: ${effort.toInt()}'),
              Slider(min: 1, max: 80, divisions: 79, value: effort, onChanged: (v) => setState(() => effort = v)),
              Row(
                children: [
                  Expanded(child: Text('Expiry: ${expiry?.toIso8601String() ?? 'None'}')),
                  TextButton(
                    onPressed: () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: now,
                        lastDate: now.add(const Duration(days: 365)),
                        initialDate: now,
                      );
                      if (picked != null) setState(() => expiry = picked);
                    },
                    child: const Text('Pick date'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: loading ? null : _submit, child: Text(loading ? 'Please wait...' : 'Create')),
            ],
          ),
        ),
      ),
    );
  }
}
