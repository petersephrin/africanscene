import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/school_provider.dart';
import '../models/form_field_model.dart';
import '../theme/app_theme.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final school = context.watch<SchoolProvider>();
    final activeSchool = school.activeSchool;
    final records = activeSchool != null
        ? school.records.where((r) => r.schoolId == activeSchool.id).toList()
        : school.records;

    final total = records.length;
    final synced = records.where((r) => r.synced && !r.isOffline).length;
    final pending = total - synced;

    final types = [
      {
        'type': FormType.weekly,
        'label': 'Weekly Records',
        'icon': Icons.calendar_today_outlined,
        'bg': AppTheme.primaryColor.withValues(alpha: 0.1),
        'fg': AppTheme.primaryColor,
      },
      {
        'type': FormType.termly,
        'label': 'Termly Records',
        'icon': Icons.menu_book_outlined,
        'bg': AppTheme.accentColor.withValues(alpha: 0.1),
        'fg': AppTheme.accentColor,
      },
      {
        'type': FormType.annually,
        'label': 'Annual Records',
        'icon': Icons.school_outlined,
        'bg': const Color(0xFF8B5CF6).withValues(alpha: 0.1),
        'fg': const Color(0xFF8B5CF6),
      },
      {
        'type': FormType.special,
        'label': 'Special Records',
        'icon': Icons.star_outline,
        'bg': Colors.grey.withValues(alpha: 0.1),
        'fg': Colors.grey,
      },
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Hero Header (hero-bg rounded-b-[2rem])
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
                    const Text(
                      'Statistics',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activeSchool?.name ?? 'Assigned School',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Summary KPI Cards (3-column grid)
          const SizedBox(height: 20),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 512),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            context: context,
                            icon: Icons.bar_chart,
                            iconColor: AppTheme.primaryColor,
                            value: '$total',
                            label: 'Total Records',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildSummaryCard(
                            context: context,
                            icon: Icons.check_circle_outline,
                            iconColor: const Color(0xFF22C55E),
                            value: '$synced',
                            label: 'Synced',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildSummaryCard(
                            context: context,
                            icon: Icons.access_time,
                            iconColor: const Color(0xFFF59E0B),
                            value: '$pending',
                            label: 'Pending',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 3. Records by Type Breakdown with Progress Bars
                    const Text(
                      'Records by Type',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: types.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = types[index];
                        final formType = item['type'] as FormType;
                        final count = records.where((r) => r.formType == formType).length;
                        final double pct = total > 0 ? (count / total) : 0.0;

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
                                  color: item['bg'] as Color,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(item['icon'] as IconData, color: item['fg'] as Color, size: 18),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          item['label'] as String,
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                        ),
                                        Text(
                                          '$count',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(999),
                                      child: LinearProgressIndicator(
                                        value: pct,
                                        minHeight: 6,
                                        backgroundColor: Theme.of(context).brightness == Brightness.dark
                                            ? AppTheme.mutedDark
                                            : AppTheme.mutedLight,
                                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // 4. Recent Records List
                    const SizedBox(height: 24),
                    if (records.isNotEmpty) ...[
                      const Text(
                        'Recent Records',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: records.take(5).length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final r = records[index];
                          final isSync = r.synced && !r.isOffline;
                          final dateStr = r.createdAt != null
                              ? DateFormat('d MMM yyyy').format(r.createdAt!)
                              : '';
                          final timeStr = r.data['time'] ?? '';

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
                                    color: isSync ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r.formType.displayName,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        '$dateStr${timeStr.isNotEmpty ? " · $timeStr" : ""}',
                                        style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? AppTheme.mutedDark
                                        : AppTheme.mutedLight,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    r.submittedBy.split(' ').firstOrNull ?? 'Unknown',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: Theme.of(context).textTheme.bodySmall?.color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.bar_chart_outlined, size: 36, color: Colors.grey.withValues(alpha: 0.4)),
                              const SizedBox(height: 8),
                              const Text('No records yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 2),
                              Text('Start adding records to see your stats', style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
                            ],
                          ),
                        ),
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

  Widget _buildSummaryCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}
