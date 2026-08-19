import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../theme/app_theme.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleAdminLogin() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      setState(() => _errorMessage = 'Please enter both email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final err = await context.read<AuthProvider>().login(email, pass);
      if (mounted) {
        if (err != null) {
          setState(() => _errorMessage = err);
        } else {
          final auth = context.read<AuthProvider>();
          if (!auth.isAdmin) {
            await auth.logout();
            setState(() => _errorMessage = 'Access denied. Administrator privileges required.');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      body: Stack(
        children: [
          // Theme Toggle at Top Right
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: InkWell(
              onTap: () => themeProvider.toggleTheme(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Icon(
                  isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round_outlined,
                  size: 18,
                  color: isDark ? AppTheme.accentDark : AppTheme.textMutedLight,
                ),
              ),
            ),
          ),

          // Centered Form
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with Logo & Shield Badge
                    Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 68,
                          height: 68,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Image.asset('assets/images/logo.jpeg', fit: BoxFit.contain),
                        ),
                        Positioned(
                          bottom: -4,
                          right: -4,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.shield_outlined, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Admin Portal',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'African SCENe Research Platform',
                      style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color),
                    ),
                    const SizedBox(height: 28),

                    // Card Container
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Theme.of(context).dividerColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sign in to continue',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 18),

                          // Email input
                          const Text('Email address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'admin@africascene.admin',
                              prefixIcon: Icon(Icons.mail_outline, size: 18),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Password input
                          const Text('Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _passCtrl,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outline, size: 18),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  size: 18,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ),

                          if (_errorMessage != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.dangerColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppTheme.dangerColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: AppTheme.dangerColor, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          // Sign In Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleAdminLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text(
                                _isLoading ? 'Signing in…' : 'Sign In',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Switch to researcher login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Not an admin? ',
                          style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: const Text(
                            'Go to researcher login',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
