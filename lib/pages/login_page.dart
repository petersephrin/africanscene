import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'reset_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _spinController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final err = await context.read<AuthProvider>().login(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (err != null && mounted) {
        setState(() {
          _errorMessage = err;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildLoginLoader() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.92),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
          constraints: const BoxConstraints(minWidth: 240),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Dual Concentric Rotating Rings
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Ring
                    AnimatedBuilder(
                      animation: _spinController,
                      builder: (_, child) {
                        return Transform.rotate(
                          angle: _spinController.value * 2 * math.pi,
                          child: child,
                        );
                      },
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.borderLight,
                            width: 3.5,
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Inner Ring
                    AnimatedBuilder(
                      animation: _spinController,
                      builder: (_, child) {
                        return Transform.rotate(
                          angle: -_spinController.value * 2 * math.pi * 1.5,
                          child: child,
                        );
                      },
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.borderLight,
                            width: 3.5,
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppTheme.accentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Center Logo
                    Container(
                      width: 44,
                      height: 44,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Image.asset('assets/images/logo.jpeg', fit: BoxFit.contain),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Signing you in…',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Please wait a moment',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // Top Hero Header (hero-bg rounded-b-[2.5rem])
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 28,
                    bottom: 36,
                    left: 24,
                    right: 24,
                  ),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          'assets/images/logo.jpeg',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'African SCENe',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sustainable Community Energy Networks',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),

                // Form Area
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Welcome back',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Sign in to continue tracking records',
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                          const SizedBox(height: 24),

                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.dangerColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.dangerColor.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, size: 18, color: AppTheme.dangerColor),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(color: AppTheme.dangerColor, fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Email
                          const Text(
                            'Email Address',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'you@example.com',
                              prefixIcon: Icon(Icons.mail_outline, size: 20),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Email is required';
                              if (!v.contains('@')) return 'Please enter a valid email address';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password
                          const Text(
                            'Password',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outline, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Password is required';
                              if (v.length < 6) return 'Password must be at least 6 characters';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
                                );
                              },
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Sign In Button (btn-primary)
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              child: const Text(
                                'Sign In',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Loader Overlay
          if (_isLoading) _buildLoginLoader(),
        ],
      ),
    );
  }
}
