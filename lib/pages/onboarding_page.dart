import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'icon': Icons.menu_book_outlined,
      'title': 'Track School Records',
      'description': 'Easily log weekly, termly, and annual energy & research records for your schools across Africa.',
    },
    {
      'icon': Icons.apartment_outlined,
      'title': 'Multiple Schools',
      'description': 'Manage records for multiple schools. Switch between them seamlessly from one dashboard.',
    },
    {
      'icon': Icons.bolt_outlined,
      'title': 'Energy Insights',
      'description': 'Track electricity usage, STEM lessons, and student performance data to power better decisions.',
    },
    {
      'icon': Icons.bar_chart_outlined,
      'title': 'Offline Ready',
      'description': "Log data anytime, even without internet. Records sync automatically when you're back online.",
    },
  ];

  void _next() {
    if (_currentIndex < _slides.length - 1) {
      setState(() => _currentIndex++);
    } else {
      context.read<AuthProvider>().completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentIndex];

    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Top Hero Header with Rounded Bottom Curves
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 24,
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
                      const SizedBox(height: 12),
                      const Text(
                        'African SCENe',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sustainable Community Energy Networks',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),

                // Skip Button
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  right: 16,
                  child: InkWell(
                    onTap: () => context.read<AuthProvider>().completeOnboarding(),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Slide Content
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Icon(
                          slide['icon'] as IconData,
                          size: 40,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        slide['title'] as String,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        slide['description'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Navigation Dots & Action Button
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 32),
              child: Column(
                children: [
                  // Dot Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (index) {
                      final isActive = index == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: isActive ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.primaryColor
                              : (Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Next / Get Started Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentIndex < _slides.length - 1 ? 'Next' : 'Get Started',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
