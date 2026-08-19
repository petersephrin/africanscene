import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/school_provider.dart';
import '../models/form_field_model.dart';
import '../theme/app_theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final school = context.watch<SchoolProvider>();
    final user = auth.user;
    final schools = school.schools;
    final records = school.records;

    final userSchools = schools.where((s) => user?.schoolIds.contains(s.id) ?? false).toList();

    final recordTypes = [
      {
        'type': FormType.weekly,
        'label': 'Weekly Records',
        'icon': Icons.calendar_today_outlined,
      },
      {
        'type': FormType.termly,
        'label': 'Termly Records',
        'icon': Icons.menu_book_outlined,
      },
      {
        'type': FormType.annually,
        'label': 'Annual Records',
        'icon': Icons.school_outlined,
      },
      {
        'type': FormType.special,
        'label': 'Special Records',
        'icon': Icons.star_outline,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Hero Header (hero-bg rounded-b-[2rem])
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
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
                  children: [
                    // Circular Avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.person, size: 44, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.name ?? 'User Profile',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.mail_outline, size: 13, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Sections Container
          const SizedBox(height: 20),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 512),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A. Your Schools Section
                    Text(
                      'YOUR SCHOOLS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (userSchools.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: const Text('No schools currently assigned to your account.', style: TextStyle(fontSize: 12)),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: userSchools.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final s = userSchools[index];
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Theme.of(context).dividerColor),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.apartment, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        s.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${s.location} · ${s.type}',
                                        style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${s.students} students',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    // B. Records Section
                    const SizedBox(height: 24),
                    Text(
                      'RECORDS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recordTypes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final cat = recordTypes[index];
                        final formType = cat['type'] as FormType;
                        final count = records.where((r) => r.formType == formType).length;

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(cat['icon'] as IconData, color: AppTheme.primaryColor, size: 18),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cat['label'] as String,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      '$count record${count != 1 ? "s" : ""} submitted',
                                      style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                            ],
                          ),
                        );
                      },
                    ),

                    // C. Summary Card
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total records submitted',
                                style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color),
                              ),
                              Text(
                                '${records.length}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Schools assigned',
                                style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color),
                              ),
                              Text(
                                '${userSchools.length}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // D. Sign Out Button (destructive bubble-button)
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.dangerColor,
                          side: BorderSide(color: AppTheme.dangerColor.withValues(alpha: 0.3)),
                          backgroundColor: AppTheme.dangerColor.withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                        onPressed: () => context.read<AuthProvider>().logout(),
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text(
                          'Sign Out',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
    );
  }
}
