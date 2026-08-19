import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSendReset() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Email is required');
      return;
    }
    if (!email.contains('@')) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final err = await context.read<AuthProvider>().resetPassword(email);
      if (mounted) {
        if (err == null) {
          setState(() => _isSent = true);
        } else {
          setState(() => _errorMessage = err);
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
    if (_isSent) {
      return Scaffold(
        body: Column(
          children: [
            // Top Hero Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 24,
                bottom: 32,
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
                    width: 76,
                    height: 76,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Image.asset('assets/images/logo.jpeg', fit: BoxFit.contain),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'African SCENe',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sustainable Community Energy Networks',
                    style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.75)),
                  ),
                ],
              ),
            ),

            // Success Card
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 380),
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: Color(0xFFDCFCE7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 36),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Check Your Email',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'We\'ve sent password reset instructions to ${_emailCtrl.text.trim()}',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                              ),
                              child: const Text('Back to Login', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Hero Header
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 24,
                    bottom: 32,
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
                        width: 76,
                        height: 76,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Image.asset('assets/images/logo.jpeg', fit: BoxFit.contain),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Reset Password',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Enter your email to receive reset instructions',
                        style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.75)),
                      ),
                    ],
                  ),
                ),

                // Back button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 16,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Row(
                        children: [
                          Icon(Icons.arrow_back, size: 16, color: Colors.white),
                          SizedBox(width: 4),
                          Text('Back', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Form Area
            Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Forgot your password?',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'No worries — we\'ll send you reset instructions.',
                      style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color),
                    ),
                    const SizedBox(height: 20),

                    if (_errorMessage != null) ...[
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
                      const SizedBox(height: 14),
                    ],

                    const Text('Email Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'you@example.com',
                        prefixIcon: Icon(Icons.mail_outline, size: 20),
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSendReset,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                        child: Text(
                          _isLoading ? 'Sending Link…' : 'Send Reset Link',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Back to login',
                          style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
