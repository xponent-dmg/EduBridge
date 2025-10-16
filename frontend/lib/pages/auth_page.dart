import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common/app_button.dart';

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
  bool passwordVisible = false;

  @override
  void dispose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      if (isLogin) {
        final success = await authProvider.signIn(emailCtrl.text.trim(), passwordCtrl.text);

        if (!mounted) return;

        if (success) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else if (authProvider.errorMessage != null) {
          _showErrorSnackbar(authProvider.errorMessage!);
        }
      } else {
        final success = await authProvider.signUp(emailCtrl.text.trim(), passwordCtrl.text, nameCtrl.text.trim(), role);

        if (!mounted) return;

        if (success) {
          Navigator.pushReplacementNamed(context, '/dashboard');
        } else if (authProvider.errorMessage != null) {
          _showErrorSnackbar(authProvider.errorMessage!);
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackbar(e.toString());
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoading = authProvider.status == AuthStatus.loading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo and title
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.school, size: 60, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    isLogin ? 'Welcome Back' : 'Create Account',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLogin ? 'Sign in to continue to EduBridge' : 'Sign up to start your journey',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 32),

                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        if (!isLogin)
                          TextFormField(
                            controller: nameCtrl,
                            decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                            textInputAction: TextInputAction.next,
                            validator: (v) => v != null && v.isNotEmpty ? null : 'Please enter your name',
                          ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: emailCtrl,
                          decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          validator: (v) => v != null && v.contains('@') ? null : 'Please enter a valid email',
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: passwordCtrl,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(passwordVisible ? Icons.visibility_off : Icons.visibility),
                              onPressed: () {
                                setState(() {
                                  passwordVisible = !passwordVisible;
                                });
                              },
                            ),
                          ),
                          obscureText: !passwordVisible,
                          textInputAction: isLogin ? TextInputAction.done : TextInputAction.next,
                          validator: (v) =>
                              v != null && v.length >= 6 ? null : 'Password must be at least 6 characters',
                        ),
                        if (!isLogin) ...[
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: role,
                            decoration: const InputDecoration(labelText: 'I am a', prefixIcon: Icon(Icons.badge)),
                            items: const [
                              DropdownMenuItem(value: 'student', child: Text('Student')),
                              DropdownMenuItem(value: 'company', child: Text('Company')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  role = value;
                                });
                              }
                            },
                          ),
                        ],
                        const SizedBox(height: 24),
                        AppButton(
                          text: isLogin ? 'Sign In' : 'Create Account',
                          isLoading: isLoading,
                          isFullWidth: true,
                          onPressed: isLoading ? null : _submit,
                        ),
                      ],
                    ),
                  ),

                  // Toggle login/register
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(isLogin ? 'Don\'t have an account?' : 'Already have an account?'),
                      TextButton(
                        onPressed: () => setState(() => isLogin = !isLogin),
                        child: Text(isLogin ? 'Sign Up' : 'Sign In'),
                      ),
                    ],
                  ),

                  // Demo mode option
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text('Or continue without an account', style: TextStyle(color: Colors.grey.shade600)),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/start'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                    child: const Text('Continue in Demo Mode'),
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
