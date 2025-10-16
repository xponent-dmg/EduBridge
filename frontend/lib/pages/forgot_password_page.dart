import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/common/app_button.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final emailCtrl = TextEditingController();
  bool sending = false;
  String? errorMessage;

  @override
  void dispose() {
    emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    final email = emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => errorMessage = 'Enter a valid email');
      return;
    }
    try {
      setState(() {
        sending = true;
        errorMessage = null;
      });
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent')));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Enter your email to receive a password reset link.'),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 24),
              AppButton(
                text: sending ? 'Sending...' : 'Send Reset Link',
                isLoading: sending,
                isFullWidth: true,
                onPressed: sending ? null : _sendReset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
