import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';

import '../theme/app_theme.dart';
import '../widgets/common/app_button.dart';

class OtpAuthPage extends StatefulWidget {
  const OtpAuthPage({super.key});

  @override
  State<OtpAuthPage> createState() => _OtpAuthPageState();
}

class _OtpAuthPageState extends State<OtpAuthPage> {
  final emailCtrl = TextEditingController();
  bool sending = false;
  String? errorMessage;

  @override
  void dispose() {
    emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => errorMessage = 'Enter a valid email');
      return;
    }

    // Check if Supabase is initialized (safe guard)
    if (!supabaseReady) {
      setState(() => errorMessage = 'Authentication service not available. Please try demo mode.');
      return;
    }

    try {
      setState(() {
        sending = true;
        errorMessage = null;
      });
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'io.supabase.flutter://login-callback',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP sent to your email')));
      Navigator.pushNamed(context, '/auth/verify-otp', arguments: email);
    } catch (e) {
      if (mounted) setState(() => errorMessage = 'Failed to send OTP: ${e.toString()}');
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/start'),
            child: const Text('Demo mode', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.mail, size: 60, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Sign in with Email OTP',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We will send a one-time code to your email',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
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
                    text: sending ? 'Sending...' : 'Send OTP',
                    isLoading: sending,
                    isFullWidth: true,
                    onPressed: sending ? null : _sendOtp,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/auth/forgot'),
                    child: const Text('Forgot password?'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
