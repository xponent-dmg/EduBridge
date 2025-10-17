import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/app_button.dart';

class UnifiedAuthPage extends StatefulWidget {
  const UnifiedAuthPage({super.key});

  @override
  State<UnifiedAuthPage> createState() => _UnifiedAuthPageState();
}

class _UnifiedAuthPageState extends State<UnifiedAuthPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers for sign in
  final emailSignInCtrl = TextEditingController();
  final passwordSignInCtrl = TextEditingController();
  final focusNodeEmailSignIn = FocusNode();
  final focusNodePasswordSignIn = FocusNode();

  // Controllers for sign up
  final nameCtrl = TextEditingController();
  final emailSignUpCtrl = TextEditingController();
  final passwordSignUpCtrl = TextEditingController();
  final focusNodeName = FocusNode();
  final focusNodeEmailSignUp = FocusNode();
  final focusNodePasswordSignUp = FocusNode();

  String selectedRole = 'student';
  bool isLoading = false;
  String? errorMessage;

  // Password visibility toggles
  bool _passwordSignInVisible = false;
  bool _passwordSignUpVisible = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        errorMessage = null;
      });
    });
  }

  @override
  void dispose() {
    // Dispose controllers
    _tabController.dispose();
    emailSignInCtrl.dispose();
    passwordSignInCtrl.dispose();
    nameCtrl.dispose();
    emailSignUpCtrl.dispose();
    passwordSignUpCtrl.dispose();

    // Dispose focus nodes
    focusNodeEmailSignIn.dispose();
    focusNodePasswordSignIn.dispose();
    focusNodeName.dispose();
    focusNodeEmailSignUp.dispose();
    focusNodePasswordSignUp.dispose();

    super.dispose();
  }

  Future<void> _handleSignIn() async {
    final email = emailSignInCtrl.text.trim();
    final password = passwordSignInCtrl.text;

    if (email.isEmpty || !email.contains('@')) {
      setState(() => errorMessage = 'Please enter a valid email');
      return;
    }

    if (password.isEmpty) {
      setState(() => errorMessage = 'Please enter your password');
      return;
    }

    // Check if Supabase is initialized (safe guard)
    if (!supabaseReady) {
      setState(() => errorMessage = 'Authentication service not available. Please try demo mode.');
      return;
    }

    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Sign in with email and password
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.signIn(email, password);

      if (!mounted) return;

      if (success) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        setState(() => errorMessage = authProvider.errorMessage ?? 'Authentication failed');
      }
    } catch (e) {
      if (mounted) {
        setState(() => errorMessage = 'Sign in failed: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _handleSignUp() async {
    final name = nameCtrl.text.trim();
    final email = emailSignUpCtrl.text.trim();
    final password = passwordSignUpCtrl.text;

    if (name.isEmpty) {
      setState(() => errorMessage = 'Please enter your name');
      return;
    }

    if (email.isEmpty || !email.contains('@')) {
      setState(() => errorMessage = 'Please enter a valid email');
      return;
    }

    if (password.isEmpty) {
      setState(() => errorMessage = 'Please enter a password');
      return;
    }

    if (password.length < 6) {
      setState(() => errorMessage = 'Password must be at least 6 characters');
      return;
    }

    // Check if Supabase is initialized (safe guard)
    if (!supabaseReady) {
      setState(() => errorMessage = 'Authentication service not available. Please try demo mode.');
      return;
    }

    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Send OTP for sign up verification
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'io.supabase.flutter://login-callback',
        data: {'name': name, 'role': selectedRole, 'password': password},
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('OTP sent to your email! Please verify to complete registration.')));

      // Pass sign-up info to verification page
      Navigator.pushNamed(
        context,
        '/auth/verify-otp',
        arguments: {'email': email, 'name': name, 'role': selectedRole, 'password': password, 'isSignUp': true},
      );
    } catch (e) {
      if (mounted) {
        setState(() => errorMessage = 'Failed to send verification code. Please try again.');
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryColor.withOpacity(0.1), Colors.white, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with logo and demo button
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.school, size: 48, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'EduBridge',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Connecting Students & Companies',
                      style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Tabs - Using built-in TabBar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                height: 50, // Fixed height for better proportions
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(25), // More rounded corners
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(25)),
                    labelColor: Colors.white,
                    unselectedLabelColor: AppTheme.textMuted,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    tabs: const [
                      Tab(text: 'Sign In'),
                      Tab(text: 'Sign Up'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const ClampingScrollPhysics(),
                  children: [_buildSignInForm(), _buildSignUpForm()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignInForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcoming header
          Text(
            'Welcome Back!',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to continue your learning journey',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 32),

          // Email field with enhanced styling
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: TextField(
              controller: emailSignInCtrl,
              focusNode: focusNodeEmailSignIn,
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'Enter your email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                floatingLabelStyle: TextStyle(color: AppTheme.primaryColor),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              style: const TextStyle(fontSize: 16),
              onSubmitted: (_) => focusNodePasswordSignIn.requestFocus(),
            ),
          ),

          const SizedBox(height: 20),

          // Password field with enhanced styling
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: TextField(
              controller: passwordSignInCtrl,
              focusNode: focusNodePasswordSignIn,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                floatingLabelStyle: TextStyle(color: AppTheme.primaryColor),
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordSignInVisible ? Icons.visibility_off : Icons.visibility,
                    color: AppTheme.primaryColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _passwordSignInVisible = !_passwordSignInVisible;
                    });
                  },
                  tooltip: _passwordSignInVisible ? 'Hide password' : 'Show password',
                ),
              ),
              obscureText: !_passwordSignInVisible,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _handleSignIn(),
              style: const TextStyle(fontSize: 16),
            ),
          ),

          if (errorMessage != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.error, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Sign in button with enhanced styling
          AppButton(
            text: 'Sign In',
            isLoading: isLoading,
            isFullWidth: true,
            icon: Icons.login,
            onPressed: isLoading ? null : _handleSignIn,
            height: 56, // Taller button for better touch target
          ),

          const SizedBox(height: 20),

          // Forgot password link with enhanced styling
          Center(
            child: TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/auth/forgot'),
              icon: const Icon(Icons.help_outline, size: 18),
              label: const Text('Forgot Password?', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSignUpForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcoming header
          Text(
            'Create Account',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Join EduBridge and start your journey',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 28),

          // Name field with enhanced styling
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: TextField(
              controller: nameCtrl,
              focusNode: focusNodeName,
              decoration: InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your name',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                floatingLabelStyle: TextStyle(color: AppTheme.primaryColor),
              ),
              textInputAction: TextInputAction.next,
              style: const TextStyle(fontSize: 16),
              onSubmitted: (_) => focusNodeEmailSignUp.requestFocus(),
            ),
          ),

          const SizedBox(height: 20),

          // Email field with enhanced styling
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: TextField(
              controller: emailSignUpCtrl,
              focusNode: focusNodeEmailSignUp,
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'Enter your email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                floatingLabelStyle: TextStyle(color: AppTheme.primaryColor),
              ),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              style: const TextStyle(fontSize: 16),
              onSubmitted: (_) => focusNodePasswordSignUp.requestFocus(),
            ),
          ),

          const SizedBox(height: 20),

          // Password field with enhanced styling
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: TextField(
              controller: passwordSignUpCtrl,
              focusNode: focusNodePasswordSignUp,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Create a password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                floatingLabelStyle: TextStyle(color: AppTheme.primaryColor),
                suffixIcon: IconButton(
                  icon: Icon(
                    _passwordSignUpVisible ? Icons.visibility_off : Icons.visibility,
                    color: AppTheme.primaryColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _passwordSignUpVisible = !_passwordSignUpVisible;
                    });
                  },
                  tooltip: _passwordSignUpVisible ? 'Hide password' : 'Show password',
                ),
              ),
              obscureText: !_passwordSignUpVisible,
              textInputAction: TextInputAction.done,
              style: const TextStyle(fontSize: 16),
            ),
          ),

          const SizedBox(height: 24),

          // Role selector with more compact styling
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.badge_outlined, color: AppTheme.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'I am a',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _RoleOption(
                        title: 'Student',
                        icon: Icons.school,
                        isSelected: selectedRole == 'student',
                        onTap: () => setState(() => selectedRole = 'student'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RoleOption(
                        title: 'Company',
                        icon: Icons.business,
                        isSelected: selectedRole == 'company',
                        onTap: () => setState(() => selectedRole = 'company'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (errorMessage != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.error.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppTheme.error, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      errorMessage!,
                      style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // Create account button with enhanced styling
          AppButton(
            text: 'Create Account',
            isLoading: isLoading,
            isFullWidth: true,
            icon: Icons.person_add,
            onPressed: isLoading ? null : _handleSignUp,
            height: 56, // Taller button for better touch target
          ),

          const SizedBox(height: 20),

          // Terms and conditions text
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'By signing up, you agree to our Terms & Privacy Policy',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleOption({required this.title, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3))
            else
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 3, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with animated container
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? Colors.white : AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 8),
            // Title with animated text style
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textDark,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              child: Text(title),
            ),
          ],
        ),
      ),
    );
  }
}
