import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/admin_data_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../pages/admin_dashboard_page.dart';
import '../pages/admin_schools_page.dart';
import '../pages/admin_researchers_page.dart';
import '../pages/admin_teachers_page.dart';
import '../pages/admin_staff_page.dart';
import '../pages/admin_form_fields_page.dart';
import '../pages/admin_records_page.dart';
import '../pages/admin_deletion_requests_page.dart';
import '../pages/admin_roles_page.dart';
import '../pages/admin_data_download_page.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _selectedPageIndex = 0;
  bool _isSidebarCollapsed = false;

  final List<Map<String, dynamic>> _navItems = [
    {'title': 'Dashboard', 'icon': Icons.dashboard_outlined, 'activeIcon': Icons.dashboard, 'superAdminOnly': false},
    {'title': 'Schools', 'icon': Icons.apartment_outlined, 'activeIcon': Icons.apartment, 'superAdminOnly': false},
    {'title': 'Researchers', 'icon': Icons.biotech_outlined, 'activeIcon': Icons.biotech, 'superAdminOnly': false},
    {'title': 'Teachers', 'icon': Icons.school_outlined, 'activeIcon': Icons.school, 'superAdminOnly': false},
    {'title': 'Staff', 'icon': Icons.people_outline, 'activeIcon': Icons.people, 'superAdminOnly': false},
    {'title': 'Form Fields', 'icon': Icons.description_outlined, 'activeIcon': Icons.description, 'superAdminOnly': false},
    {'title': 'Records', 'icon': Icons.bar_chart_outlined, 'activeIcon': Icons.bar_chart, 'superAdminOnly': false},
    {'title': 'Deletion Requests', 'icon': Icons.delete_outline, 'activeIcon': Icons.delete, 'superAdminOnly': false},
    {'title': 'Data Download', 'icon': Icons.download_outlined, 'activeIcon': Icons.download, 'superAdminOnly': false},
    {'title': 'Roles', 'icon': Icons.shield_outlined, 'activeIcon': Icons.shield, 'superAdminOnly': true},
  ];

  final List<Widget> _pages = const [
    AdminDashboardPage(),
    AdminSchoolsPage(),
    AdminResearchersPage(),
    AdminTeachersPage(),
    AdminStaffPage(),
    AdminFormFieldsPage(),
    AdminRecordsPage(),
    AdminDeletionRequestsPage(),
    AdminDataDownloadPage(),
    AdminRolesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final adminData = context.watch<AdminDataProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final currentUser = auth.user;
    final isSuperAdmin = currentUser?.role == UserRole.superAdmin;
    final unreadNotifications = adminData.deletionRequests.where((r) => r.status.name == 'pending').length;

    final visibleNavItems = _navItems.where((item) {
      if (item['superAdminOnly'] == true && !isSuperAdmin) return false;
      return true;
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;

        return Scaffold(
          drawer: isDesktop ? null : _buildSidebar(isCollapsed: false, onClose: () => Navigator.pop(context)),
          body: Row(
            children: [
              // Persistent Sidebar on Desktop
              if (isDesktop)
                _buildSidebar(isCollapsed: _isSidebarCollapsed),

              // Main Content Area
              Expanded(
                child: Column(
                  children: [
                    // Admin TopNav
                    Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        border: Border(
                          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          if (!isDesktop)
                            Builder(
                              builder: (ctx) => IconButton(
                                icon: const Icon(Icons.menu, size: 22),
                                onPressed: () => Scaffold.of(ctx).openDrawer(),
                              ),
                            ),
                          const SizedBox(width: 4),

                          // Page Title
                          Expanded(
                            child: Text(
                              visibleNavItems.length > _selectedPageIndex
                                  ? visibleNavItems[_selectedPageIndex]['title'] as String
                                  : 'Admin Panel',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),

                          // Database Seeder Button (Admin Utility)
                          IconButton(
                            icon: const Icon(Icons.cloud_sync_outlined, size: 20),
                            tooltip: 'Seed Database with Default Templates',
                            onPressed: () async {
                              await adminData.seedInitialDataIfEmpty();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Initial data check & seed completed.'), backgroundColor: AppTheme.successColor),
                                );
                              }
                            },
                          ),

                          // Dark/Light Theme Toggle
                          IconButton(
                            icon: Icon(
                              isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round_outlined,
                              size: 18,
                              color: isDark ? AppTheme.accentDark : AppTheme.textMutedLight,
                            ),
                            tooltip: 'Toggle Theme',
                            onPressed: () => themeProvider.toggleTheme(),
                          ),

                          // Notifications Bell
                          IconButton(
                            icon: Stack(
                              children: [
                                const Icon(Icons.notifications_none_outlined, size: 20),
                                if (unreadNotifications > 0)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: AppTheme.dangerColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            tooltip: 'Pending Deletions',
                            onPressed: () => setState(() => _selectedPageIndex = 7),
                          ),

                          const SizedBox(width: 8),

                          // Admin User Avatar
                          if (currentUser != null)
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                                  child: Text(
                                    currentUser.name.isNotEmpty ? currentUser.name[0].toUpperCase() : 'A',
                                    style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (isDesktop)
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        currentUser.name.split(' ').firstOrNull ?? 'Admin',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                      ),
                                      Text(
                                        currentUser.role.displayName,
                                        style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    // Page Body
                    Expanded(
                      child: IndexedStack(
                        index: _selectedPageIndex,
                        children: _pages,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSidebar({required bool isCollapsed, VoidCallback? onClose}) {
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.user;
    final width = isCollapsed ? 64.0 : 230.0;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          right: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Logo & Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Row(
              children: [
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: onClose,
                  ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset('assets/images/logo.jpeg', fit: BoxFit.contain),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'African SCENe',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'ADMIN PANEL',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
                    child: const Icon(Icons.chevron_left, size: 18, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),

          // User Profile Row
          if (!isCollapsed && currentUser != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                    child: Text(
                      currentUser.name.isNotEmpty ? currentUser.name[0].toUpperCase() : 'A',
                      style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser.name,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            currentUser.role.displayName,
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Section Header: MENU
          if (!isCollapsed)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 16, bottom: 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'MENU',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ),
            ),

          // Navigation Links
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              itemCount: _navItems.length,
              separatorBuilder: (_, __) => const SizedBox(height: 2),
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isSelected = _selectedPageIndex == index;

                return InkWell(
                  onTap: () {
                    setState(() => _selectedPageIndex = index);
                    if (onClose != null) onClose();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 12 : 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                      children: [
                        Icon(
                          isSelected ? item['activeIcon'] as IconData : item['icon'] as IconData,
                          size: 18,
                          color: isSelected ? Colors.white : Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        if (!isCollapsed) ...[
                          const SizedBox(width: 12),
                          Text(
                            item['title'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Log Out
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: InkWell(
              onTap: () => auth.logout(),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                  children: [
                    const Icon(Icons.logout, size: 18, color: AppTheme.dangerColor),
                    if (!isCollapsed) ...[
                      const SizedBox(width: 12),
                      const Text(
                        'Log Out',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.dangerColor),
                      ),
                    ],
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
