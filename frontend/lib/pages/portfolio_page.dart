import 'package:flutter/material.dart';

import '../services/api_client.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key, required this.userId});
  final dynamic userId;

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  final api = ApiClient();
  List entries = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await api.get('/portfolio/${widget.userId}');
    entries = (res['data'] as List?) ?? [];
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Portfolio')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: entries.length,
              itemBuilder: (_, i) {
                final e = entries[i] as Map<String, dynamic>;
                final sub = e['submissions'] as Map<String, dynamic>?;
                final task = sub?['tasks'] as Map<String, dynamic>?;
                return Card(
                  child: ListTile(
                    title: Text(task?['title'] ?? 'Entry'),
                    subtitle: Text('Grade: ${sub?['grade'] ?? '-'}  Feedback: ${sub?['feedback'] ?? '-'}'),
                  ),
                );
              },
            ),
    );
  }
}
