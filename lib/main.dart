import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/school_provider.dart';
import 'providers/admin_data_provider.dart';
import 'providers/theme_provider.dart';
import 'theme/app_theme.dart';
import 'pages/onboarding_page.dart';
import 'pages/login_page.dart';
import 'pages/reset_password_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/record_form_page.dart';
import 'pages/stats_page.dart';
import 'pages/profile_page.dart';
import 'components/top_nav.dart';
import 'components/bottom_nav.dart';
import 'admin/components/admin_layout.dart';
import 'admin/pages/admin_login_page.dart';
import 'models/form_field_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AfricanSceneApp());
}

class AfricanSceneApp extends StatelessWidget {
  const AfricanSceneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SchoolProvider()),
        ChangeNotifierProvider(create: (_) => AdminDataProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'African SCENe',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme(),
            darkTheme: AppTheme.darkTheme(),
            themeMode: themeProvider.themeMode,
            onGenerateRoute: (settings) {
              final uri = Uri.parse(settings.name ?? '/');

              // 1. Dedicated Admin Route (/admin or /admin/*)
              if (uri.path.startsWith('/admin')) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => const AdminSection(),
                );
              }

              // 2. Auth Routes
              if (uri.path == '/login') {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => const LoginPage(),
                );
              }
              if (uri.path == '/reset-password') {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => const ResetPasswordPage(),
                );
              }

              // 3. Root / Catch-all Route
              return MaterialPageRoute(
                settings: settings,
                builder: (_) => const RootRouter(),
              );
            },
          );
        },
      ),
    );
  }
}

/// Admin section route guard — renders AdminLogin or AdminLayout based on admin state
class AdminSection extends StatelessWidget {
  const AdminSection({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.accentColor),
        ),
      );
    }

    // Not logged in or not an admin -> show dedicated admin login
    if (!auth.isAdmin) {
      return const AdminLoginPage();
    }

    return const AdminLayout();
  }
}

/// Staff app section — routes between Onboarding, Staff Login, Admin redirect, and MainStaffShell
class RootRouter extends StatefulWidget {
  const RootRouter({super.key});

  @override
  State<RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<RootRouter> {
  String? _lastUserId;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school, size: 48, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 20),
              const CircularProgressIndicator(color: AppTheme.primaryColor),
            ],
          ),
        ),
      );
    }

    // If an admin lands here, route directly to the admin portal
    if (auth.isAdmin) {
      return const AdminLayout();
    }

    // If user has not completed onboarding
    if (!auth.hasOnboarded) {
      return const OnboardingPage();
    }

    // If not authenticated, show field researcher login
    if (!auth.isAuthenticated) {
      return const LoginPage();
    }

    // Authenticated researcher/teacher -> Initialize SchoolProvider
    final user = auth.user!;
    if (_lastUserId != user.id) {
      _lastUserId = user.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<SchoolProvider>().init(user);
      });
    }

    return const MainStaffShell();
  }
}

class MainStaffShell extends StatefulWidget {
  const MainStaffShell({super.key});

  @override
  State<MainStaffShell> createState() => _MainStaffShellState();
}

class _MainStaffShellState extends State<MainStaffShell> {
  int _currentIndex = 0;
  FormType _activeRecordFormType = FormType.weekly;

  void _navigateToRecordType(FormType type) {
    setState(() {
      _activeRecordFormType = type;
      _currentIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      DashboardPage(onNavigateToForm: _navigateToRecordType),
      RecordFormPage(key: ValueKey(_activeRecordFormType), initialFormType: _activeRecordFormType),
      const StatsPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      appBar: const TopNav(),
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNav(
        currentIndex: _currentIndex,
        onTap: (idx) => setState(() => _currentIndex = idx),
        onSelectRecordType: _navigateToRecordType,
      ),
    );
  }
}
