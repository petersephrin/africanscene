import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../providers/school_provider.dart';
import '../models/form_field_model.dart';
import '../theme/app_theme.dart';
import '../components/school_switcher_modal.dart';

class DashboardPage extends StatelessWidget {
  final Function(FormType)? onNavigateToForm;

  const DashboardPage({super.key, this.onNavigateToForm});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final school = context.watch<SchoolProvider>();
    final user = auth.user;
    final activeSchool = school.activeSchool;
    final isOnline = school.isOnline;
    final pendingCount = school.pendingSyncCount;
    final firstName = user?.name.split(' ').firstOrNull ?? 'User';

    final recordCategories = [
      {
        'type': FormType.weekly,
        'label': 'Weekly',
        'desc': 'Weekly observations & data',
        'icon': Icons.calendar_today_outlined,
      },
      {
        'type': FormType.termly,
        'label': 'Termly',
        'desc': 'End of term summaries',
        'icon': Icons.menu_book_outlined,
      },
      {
        'type': FormType.annually,
        'label': 'Annually',
        'desc': 'Annual research findings',
        'icon': Icons.school_outlined,
      },
      {
        'type': FormType.special,
        'label': 'Special',
        'desc': 'Special events & notes',
        'icon': Icons.star_outline,
      },
    ];

    final recentRecords = school.records.take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Solid Hero Header with Curved Bottom (rounded-b-[2rem])
          Container(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 512),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting & Online Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_getGreeting()},',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$firstName 👋',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),

                        // Online / Offline Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isOnline
                                ? const Color(0xFF16A34A).withValues(alpha: 0.35)
                                : const Color(0xFFD97706).withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isOnline
                                  ? const Color(0xFF4ADE80).withValues(alpha: 0.4)
                                  : const Color(0xFFFBBF24).withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isOnline ? Icons.wifi : Icons.wifi_off,
                                size: 12,
                                color: isOnline ? const Color(0xFFBBF7D0) : const Color(0xFFFEF08A),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isOnline ? 'Online' : 'Offline',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isOnline ? const Color(0xFFBBF7D0) : const Color(0xFFFEF08A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // School Switcher Pill Button
                    InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const SchoolSwitcherModal(),
                        );
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.apartment, size: 16, color: Colors.white),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                activeSchool?.name ?? 'Select Assigned School',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.white70),
                          ],
                        ),
                      ),
                    ),

                    // Active School Info Card (bg-white/15 border border-white/25 rounded-2xl)
                    if (activeSchool != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        activeSchool.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on_outlined, size: 13, color: Colors.white.withValues(alpha: 0.7)),
                                          const SizedBox(width: 4),
                                          Text(
                                            activeSchool.location,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.white.withValues(alpha: 0.75),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        activeSchool.type,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white.withValues(alpha: 0.65),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Students Box (bg-white/20 rounded-xl)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.people_alt_outlined, size: 16, color: Colors.white70),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${activeSchool.students}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        'Students',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.65),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Motto
                            if (activeSchool.motto != null && activeSchool.motto!.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.lightbulb_outline, size: 14, color: Color(0xFFFBBF24)),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '"${activeSchool.motto}"',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                          color: Colors.white.withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // 2. Pending Sync Banner
          if (pendingCount > 0) ...[
            const SizedBox(height: 14),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 512),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: InkWell(
                    onTap: user != null ? () => school.syncRecords(user) : null,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.cloud_off, size: 16, color: Color(0xFFB45309)),
                              const SizedBox(width: 8),
                              Text(
                                '$pendingCount record${pendingCount > 1 ? "s" : ""} pending sync',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF92400E),
                                ),
                              ),
                            ],
                          ),
                          if (isOnline)
                            const Text(
                              'Tap to sync →',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFD97706),
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

          // 3. Add Records 2x2 Grid
          const SizedBox(height: 20),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 512),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Records',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.15,
                      ),
                      itemCount: recordCategories.length,
                      itemBuilder: (context, idx) {
                        final cat = recordCategories[idx];
                        final formType = cat['type'] as FormType;
                        final count = school.getRecordsByType(formType).length;

                        return InkWell(
                          onTap: () {
                            if (onNavigateToForm != null) {
                              onNavigateToForm!(formType);
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Theme.of(context).dividerColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(cat['icon'] as IconData, color: AppTheme.primaryColor, size: 20),
                                ),
                                const Spacer(),
                                Text(
                                  cat['label'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  cat['desc'] as String,
                                  style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$count record${count != 1 ? "s" : ""}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Recent Activity List
          const SizedBox(height: 24),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 512),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Activity',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    if (recentRecords.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.menu_book_outlined, size: 36, color: Colors.grey.withValues(alpha: 0.4)),
                              const SizedBox(height: 8),
                              const Text('No records yet', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text(
                                'Tap a record type above to get started',
                                style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: recentRecords.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final rec = recentRecords[index];
                          final isSynced = rec.synced;
                          final dateStr = rec.createdAt != null
                              ? DateFormat('d MMM yyyy').format(rec.createdAt!)
                              : '';

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Theme.of(context).dividerColor),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isSynced ? AppTheme.successColor : AppTheme.warningColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${rec.formType.displayName} Record',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${rec.formType.displayName} · $dateStr',
                                        style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isSynced
                                        ? const Color(0xFFDCFCE7)
                                        : const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    isSynced ? 'Synced' : 'Local',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isSynced ? const Color(0xFF15803D) : const Color(0xFFB45309),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
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
