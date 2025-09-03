import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  bool isLogin = true;
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  String role = 'student';
  bool loading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      String? token;
      if (isLogin) {
        token = await AuthService.signIn(emailCtrl.text.trim(), passwordCtrl.text);
      } else {
        token = await AuthService.signUp(emailCtrl.text.trim(), passwordCtrl.text);
        // Also register user in backend users table
        final api = ApiClient(authToken: token);
        await api.post(
          '/users',
          body: {
            'name': nameCtrl.text.trim().isEmpty ? emailCtrl.text.trim() : nameCtrl.text.trim(),
            'email': emailCtrl.text.trim(),
            'role': role,
          },
        );
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/dashboard', arguments: token);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Auth failed: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(isLogin ? 'Login' : 'Register', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 16),
                    if (!isLogin)
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Name'),
                      ),
                    TextFormField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) => v != null && v.contains('@') ? null : 'Enter a valid email',
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: passwordCtrl,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: (v) => v != null && v.length >= 6 ? null : 'Min 6 chars',
                    ),
                    if (!isLogin) ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: role,
                        items: const [
                          DropdownMenuItem(value: 'student', child: Text('Student')),
                          DropdownMenuItem(value: 'company', child: Text('Company')),
                        ],
                        onChanged: (v) => setState(() => role = v ?? 'student'),
                        decoration: const InputDecoration(labelText: 'Register as'),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: loading ? null : _submit,
                        child: Text(loading ? 'Please wait...' : (isLogin ? 'Login' : 'Register')),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => isLogin = !isLogin),
                      child: Text(isLogin ? 'Need an account? Register' : 'Have an account? Login'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
