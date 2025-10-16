import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';

import '../theme/app_theme.dart';
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

    // Check if Supabase is initialized (safe guard)
    if (!supabaseReady) {
      setState(() => errorMessage = 'Authentication service not available');
      return;
    }

    try {
      setState(() {
        sending = true;
        errorMessage = null;
      });
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.flutter://login-callback',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent')));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => errorMessage = 'Failed to send reset email. Please try again.');
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon and title
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.lock_reset, size: 48, color: AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Reset Your Password',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Text(
                  'Enter your email address and we\'ll send you a link to reset your password.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
                ),

                const SizedBox(height: 32),

                TextField(
                  controller: emailCtrl,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    hintText: 'Enter your email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _sendReset(),
                ),

                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(errorMessage!, style: TextStyle(color: AppTheme.error)),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                AppButton(
                  text: sending ? 'Sending...' : 'Send Reset Link',
                  isLoading: sending,
                  isFullWidth: true,
                  icon: Icons.send,
                  onPressed: sending ? null : _sendReset,
                ),

                const SizedBox(height: 16),

                Center(
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Back to Sign In'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
