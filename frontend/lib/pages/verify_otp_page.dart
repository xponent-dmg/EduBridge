import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';

import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/common/app_button.dart';

class VerifyOtpPage extends StatefulWidget {
  const VerifyOtpPage({super.key, this.email, this.signUpData});
  final String? email;
  final Map<String, dynamic>? signUpData;

  @override
  State<VerifyOtpPage> createState() => _VerifyOtpPageState();
}

class _VerifyOtpPageState extends State<VerifyOtpPage> {
  // Six text editing controllers for the 6 OTP digits
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());

  // Six focus nodes for the 6 OTP input fields
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool verifying = false;
  String? errorMessage;

  @override
  void dispose() {
    // Dispose all controllers and focus nodes
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  // Get the complete OTP code from all fields
  String get _otpCode {
    return _otpControllers.map((controller) => controller.text).join();
  }

  // Handle when a digit is entered in an OTP field
  void _onOtpDigitChanged(int index, String value) {
    if (value.length == 1) {
      // Auto-advance to next field
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last digit entered, hide keyboard
        _focusNodes[index].unfocus();
        // Auto-verify when all digits are entered
        if (_otpCode.length == 6) {
          _verify();
        }
      }
    }
  }

  // Handle backspace in OTP fields
  void _onOtpKeyEvent(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace && _otpControllers[index].text.isEmpty && index > 0) {
        // Move to previous field on backspace if current field is empty
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  Future<void> _verify() async {
    final token = _otpCode;
    if (token.length != 6) {
      setState(() => errorMessage = 'Please enter all 6 digits of the verification code');
      return;
    }

    // Check if Supabase is initialized (safe guard)
    if (!supabaseReady) {
      setState(() => errorMessage = 'Authentication service not available');
      return;
    }

    // Get email from either direct prop or signUpData
    final email = widget.email ?? widget.signUpData?['email'] as String?;
    if (email == null) {
      setState(() => errorMessage = 'Invalid email');
      return;
    }

    final isSignUp = widget.signUpData?['isSignUp'] == true;

    try {
      setState(() {
        verifying = true;
        errorMessage = null;
      });

      // Verify OTP
      final response = await Supabase.instance.client.auth.verifyOTP(email: email, token: token, type: OtpType.email);

      if (!mounted) return;

      // If this is a sign-up, set password within the same verified session and register app user
      if (isSignUp && response.session != null) {
        final name = widget.signUpData?['name'] as String? ?? email;
        final role = widget.signUpData?['role'] as String? ?? 'student';
        final password = widget.signUpData?['password'] as String?;

        // If a password was provided during sign-up, set it on the current user without logging out
        if (password != null && password.isNotEmpty) {
          try {
            await Supabase.instance.client.auth.updateUser(UserAttributes(password: password));
          } catch (e) {
            // Non-fatal: proceed even if password update fails; user can use magic link/OTP
            print('Password set failed after OTP verify: $e');
          }
        }

        // Ensure user exists in backend `users` table using current access token
        try {
          final currentToken =
              Supabase.instance.client.auth.currentSession?.accessToken ?? response.session!.accessToken;
          final apiClient = ApiClient(authToken: currentToken);
          await apiClient.post('/users', body: {'name': name, 'email': email, 'role': role});
        } catch (e) {
          // Ignore error if user already exists
          print('User creation error (may already exist): $e');
        }
      }

      // Refresh user data
      await Provider.of<AuthProvider>(context, listen: false).refreshCurrentUser();

      // Navigate to dashboard
      Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (_) => false);
    } catch (e) {
      if (mounted) {
        setState(() => errorMessage = 'Verification failed: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.email ?? widget.signUpData?['email'] as String? ?? '';
    final isSignUp = widget.signUpData?['isSignUp'] == true;

    return Scaffold(
      appBar: AppBar(title: Text(isSignUp ? 'Verify Account' : 'Verify OTP')),
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
                    child: const Icon(Icons.verified_user, size: 48, color: AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  isSignUp ? 'Verify Your Account' : 'Verify Your Identity',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                Text('We sent a verification code to:', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),

                Text(email, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),

                const SizedBox(height: 32),

                // OTP digit input fields
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) => _buildOtpDigitField(index)),
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
                  text: verifying ? 'Verifying...' : 'Verify',
                  isLoading: verifying,
                  isFullWidth: true,
                  icon: Icons.verified_outlined,
                  onPressed: verifying ? null : _verify,
                ),

                const SizedBox(height: 16),

                Center(
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Go Back'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build a single OTP digit input field
  Widget _buildOtpDigitField(int index) {
    return SizedBox(
      width: 45,
      height: 55,
      child: RawKeyboardListener(
        focusNode: FocusNode(),
        onKey: (event) => _onOtpKeyEvent(index, event),
        child: TextField(
          controller: _otpControllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.error),
            ),
          ),
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(1)],
          onChanged: (value) => _onOtpDigitChanged(index, value),
          autofocus: index == 0, // Auto-focus the first field
        ),
      ),
    );
  }
}
