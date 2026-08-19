import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/school_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'notification_modal.dart';

class TopNav extends StatelessWidget implements PreferredSizeWidget {
  const TopNav({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final school = context.watch<SchoolProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final isOnline = school.isOnline;
    final unreadCount = school.notifications.where((n) => !n.read).length;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo Image
          Image.asset(
            'assets/images/logo.jpeg',
            height: 38,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Text(
              'African SCENe',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.primaryColor),
            ),
          ),

          // Right Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Online / Offline Status Dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isOnline ? AppTheme.primaryColor : AppTheme.dangerColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),

              // Theme Switcher Button (w-9 h-9 rounded-xl bg-muted)
              InkWell(
                onTap: () => themeProvider.toggleTheme(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.mutedDark : AppTheme.mutedLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round_outlined,
                    size: 18,
                    color: isDark ? AppTheme.accentDark : AppTheme.textMutedLight,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Notification Bell
              InkWell(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const NotificationModal(),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.mutedDark : AppTheme.mutedLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none_outlined,
                        size: 20,
                        color: isDark ? AppTheme.textLight : AppTheme.textMutedLight,
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          top: 6,
                          right: 6,
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
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
