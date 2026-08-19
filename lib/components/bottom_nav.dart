import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/form_field_model.dart';

class BottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final Function(FormType)? onSelectRecordType;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onSelectRecordType,
  });

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  bool _fabOpen = false;

  void _handleRecordSelect(FormType type) {
    setState(() => _fabOpen = false);
    if (widget.onSelectRecordType != null) {
      widget.onSelectRecordType!(type);
    } else {
      widget.onTap(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        // FAB Overlay Modal if open
        if (_fabOpen)
          Positioned(
            bottom: 74,
            child: Container(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFabOption(
                    icon: Icons.calendar_today_outlined,
                    label: 'Weekly Record',
                    onTap: () => _handleRecordSelect(FormType.weekly),
                  ),
                  const SizedBox(height: 8),
                  _buildFabOption(
                    icon: Icons.menu_book_outlined,
                    label: 'Termly Record',
                    onTap: () => _handleRecordSelect(FormType.termly),
                  ),
                  const SizedBox(height: 8),
                  _buildFabOption(
                    icon: Icons.school_outlined,
                    label: 'Annual Record',
                    onTap: () => _handleRecordSelect(FormType.annually),
                  ),
                  const SizedBox(height: 8),
                  _buildFabOption(
                    icon: Icons.star_outline,
                    label: 'Special Record',
                    onTap: () => _handleRecordSelect(FormType.special),
                  ),
                ],
              ),
            ),
          ),

        // Main Bottom Bar
        Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. Home
              _buildNavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                index: 0,
              ),

              // 2. Records
              _buildNavItem(
                icon: Icons.calendar_today_outlined,
                activeIcon: Icons.calendar_today,
                label: 'Records',
                index: 1,
              ),

              // Center FAB Space Placeholder
              const SizedBox(width: 48),

              // 3. Stats
              _buildNavItem(
                icon: Icons.bar_chart_outlined,
                activeIcon: Icons.bar_chart,
                label: 'Stats',
                index: 2,
              ),

              // 4. Profile
              _buildNavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
                index: 3,
              ),
            ],
          ),
        ),

        // Protruding Center FAB (-mt-5)
        Positioned(
          bottom: 24,
          child: GestureDetector(
            onTap: () => setState(() => _fabOpen = !_fabOpen),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _fabOpen
                    ? (isDark ? Colors.white : Colors.black87)
                    : AppTheme.primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  _fabOpen ? Icons.close : Icons.add_circle_outline,
                  color: _fabOpen
                      ? (isDark ? Colors.black : Colors.white)
                      : Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
  }) {
    final isActive = widget.currentIndex == index;
    final color = isActive
        ? AppTheme.primaryColor
        : (Theme.of(context).brightness == Brightness.dark ? AppTheme.textMutedDark : AppTheme.textMutedLight);

    return InkWell(
      onTap: () {
        if (_fabOpen) setState(() => _fabOpen = false);
        widget.onTap(index);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isActive ? activeIcon : icon, color: color, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFabOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minWidth: 190),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
