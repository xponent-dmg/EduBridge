import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/auth_provider.dart';
import '../widgets/common/app_button.dart';

class VerifyOtpPage extends StatefulWidget {
  const VerifyOtpPage({super.key, required this.email});
  final String email;

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  final otpCtrl = TextEditingController();
  bool verifying = false;
  String? errorMessage;

  @override
  void dispose() {
    otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final token = otpCtrl.text.trim();
    if (token.isEmpty) {
      setState(() => errorMessage = 'Enter the OTP code from your email');
      return;
    }
    try {
      setState(() {
        verifying = true;
        errorMessage = null;
      });
      await Supabase.instance.client.auth.verifyOTP(email: widget.email, token: token, type: OtpType.email);
      if (!mounted) return;
      await Provider.of<AuthProvider>(context, listen: false).refreshCurrentUser();
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (_) => false);
    } catch (e) {
      if (mounted) setState(() => errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('We sent a code to ${widget.email}'),
              const SizedBox(height: 12),
              TextField(
                controller: otpCtrl,
                decoration: const InputDecoration(labelText: 'Enter OTP code', prefixIcon: Icon(Icons.lock_outline)),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 24),
              AppButton(
                text: verifying ? 'Verifying...' : 'Verify',
                isLoading: verifying,
                isFullWidth: true,
                onPressed: verifying ? null : _verify,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
