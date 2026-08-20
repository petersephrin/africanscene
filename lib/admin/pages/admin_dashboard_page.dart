import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/admin_data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/form_field_model.dart';
import '../../models/record_model.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

class AdminDashboardPage extends StatefulWidget {
  final ValueChanged<int>? onNavigate;

  const AdminDashboardPage({super.key, this.onNavigate});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  String _selectedFormType = 'all';
  String _selectedSchool = 'all';

  static const List<Color> _chartColors = [
    AppTheme.primaryColor,
    AppTheme.accentColor,
    Color(0xFF10B981), // Emerald
    Color(0xFF8B5CF6), // Violet
    Color(0xFFF97316), // Orange
    Color(0xFF06B6D4), // Cyan
  ];

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final adminData = context.watch<AdminDataProvider>();
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.user;

    final schools = adminData.schools;
    final researchers = adminData.researchers;
    final teachers = adminData.teachers;
    final staff = adminData.staff;
    final allRecords = adminData.records;
    final formFields = adminData.formFields;

    String getSchoolName(String schoolId) {
      final match = schools.where((s) => s.id == schoolId).toList();
      return match.isNotEmpty ? match.first.name : 'Unknown School';
    }

    // 1. Filter records
    final filteredRecords = allRecords.where((r) {
      if (_selectedFormType != 'all' && r.formType.toDbString() != _selectedFormType) return false;
      if (_selectedSchool != 'all' && r.schoolId != _selectedSchool) return false;
      return true;
    }).toList();

    // 2. Numeric form fields
    final numericFields = formFields.where((f) {
      if (_selectedFormType != 'all' && f.formType.toDbString() != _selectedFormType) return false;
      return f.fieldType == CustomFieldType.number || f.fieldType == CustomFieldType.percentage;
    }).toList()
      ..sort((a, b) => a.fieldOrder.compareTo(b.fieldOrder));

    // 3. School Performance data (per school aggregated averages of numeric fields)
    final schoolMap = <String, _SchoolAggregation>{};
    for (final rec in filteredRecords) {
      final sName = getSchoolName(rec.schoolId);
      if (!schoolMap.containsKey(rec.schoolId)) {
        schoolMap[rec.schoolId] = _SchoolAggregation(name: sName);
      }
      final entry = schoolMap[rec.schoolId]!;
      entry.count++;

      for (final field in numericFields) {
        final rawVal = rec.data[field.label] ?? rec.data[field.id];
        final numVal = rawVal is num ? rawVal.toDouble() : (double.tryParse(rawVal?.toString() ?? '') ?? 0.0);
        entry.totals[field.label] = (entry.totals[field.label] ?? 0.0) + numVal;
      }
    }

    final schoolPerformanceList = schoolMap.values.map((entry) {
      final averages = <String, double>{};
      for (final field in numericFields) {
        final total = entry.totals[field.label] ?? 0.0;
        averages[field.label] = entry.count > 0 ? (total / entry.count) : 0.0;
      }
      return _SchoolMetric(name: entry.name, values: averages);
    }).toList();

    // 4. Records over time (monthly aggregation)
    final monthMap = <String, int>{};
    for (final r in filteredRecords) {
      if (r.createdAt != null) {
        final key = DateFormat('yyyy-MM').format(r.createdAt!);
        monthMap[key] = (monthMap[key] ?? 0) + 1;
      }
    }
    final sortedMonths = monthMap.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final recordsOverTime = sortedMonths.length > 12 ? sortedMonths.sublist(sortedMonths.length - 12) : sortedMonths;

    // 5. Records by form type
    final typeCounts = <String, int>{};
    for (final r in filteredRecords) {
      final t = r.formType.displayName;
      typeCounts[t] = (typeCounts[t] ?? 0) + 1;
    }

    // 6. Recent records
    final recentRecords = List<RecordModel>.from(filteredRecords)
      ..sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
    final topRecent = recentRecords.take(5).toList();

    final pendingSyncCount = allRecords.where((r) => !r.synced).length;
    final staffAndTeachersCount = staff.length + teachers.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header (Greeting, User Name, Role Badge, Pending Sync)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_greeting()},',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        currentUser?.firstName.isNotEmpty == true
                            ? currentUser!.firstName
                            : (currentUser?.name.isNotEmpty == true ? currentUser!.name.split(' ').first : 'Admin'),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      const Text('👋', style: TextStyle(fontSize: 20)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          currentUser?.role == UserRole.superAdmin ? 'Super Admin' : 'Staff',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accentColor,
                          ),
                        ),
                      ),
                      if (pendingSyncCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$pendingSyncCount pending sync',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2. 4 Top KPI Metric Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 760;
              return GridView.count(
                crossAxisCount: isWide ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: isWide ? 1.45 : 1.35,
                children: [
                  _buildKpiCard(
                    context,
                    label: 'Schools',
                    value: '${schools.length}',
                    icon: Icons.account_balance_outlined,
                    iconColor: AppTheme.primaryColor,
                    bgColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                    onTap: () => widget.onNavigate?.call(1),
                  ),
                  _buildKpiCard(
                    context,
                    label: 'Researchers',
                    value: '${researchers.length}',
                    icon: Icons.science_outlined,
                    iconColor: AppTheme.accentColor,
                    bgColor: AppTheme.accentColor.withValues(alpha: 0.1),
                    onTap: () => widget.onNavigate?.call(2),
                  ),
                  _buildKpiCard(
                    context,
                    label: 'Staff + Teachers',
                    value: '$staffAndTeachersCount',
                    icon: Icons.people_outline,
                    iconColor: const Color(0xFF10B981),
                    bgColor: const Color(0xFF10B981).withValues(alpha: 0.1),
                    onTap: () => widget.onNavigate?.call(4),
                  ),
                  _buildKpiCard(
                    context,
                    label: 'Total Records',
                    value: '${allRecords.length}',
                    icon: Icons.bar_chart,
                    iconColor: const Color(0xFF8B5CF6),
                    bgColor: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    onTap: () => widget.onNavigate?.call(6),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // 3. Dashboard Filters Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.filter_list, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
                    const SizedBox(width: 6),
                    const Text('Dashboard Filters', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Record Type', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodySmall?.color)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).dividerColor),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedFormType,
                            underline: const SizedBox(),
                            isDense: true,
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All Types', style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: 'weekly', child: Text('Weekly', style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: 'termly', child: Text('Termly', style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: 'annually', child: Text('Annually', style: TextStyle(fontSize: 13))),
                              DropdownMenuItem(value: 'special', child: Text('Special', style: TextStyle(fontSize: 13))),
                            ],
                            onChanged: (val) => setState(() => _selectedFormType = val ?? 'all'),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('School', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Theme.of(context).textTheme.bodySmall?.color)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).dividerColor),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedSchool,
                            underline: const SizedBox(),
                            isDense: true,
                            items: [
                              const DropdownMenuItem(value: 'all', child: Text('All Schools', style: TextStyle(fontSize: 13))),
                              ...schools.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, style: const TextStyle(fontSize: 13)))),
                            ],
                            onChanged: (val) => setState(() => _selectedSchool = val ?? 'all'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Dynamic Charts: School Performance & Submissions Over Time
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 820;

              final performanceCard = Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'School Performance ${_selectedFormType != 'all' ? "($_selectedFormType)" : ""}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (schoolPerformanceList.isEmpty || numericFields.isEmpty)
                      const SizedBox(
                        height: 220,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.bar_chart, size: 36, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('No numeric data to display', style: TextStyle(fontSize: 13, color: Colors.grey)),
                              SizedBox(height: 4),
                              Text('Add numeric form fields and submit records to see performance charts', style: TextStyle(fontSize: 11, color: Colors.grey), textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      )
                    else ...[
                      SizedBox(
                        height: 220,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: _calculateMaxBarY(schoolPerformanceList, numericFields),
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (group) => Theme.of(context).cardColor,
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  final fieldName = rodIndex < numericFields.length ? numericFields[rodIndex].label : '';
                                  return BarTooltipItem(
                                    '$fieldName\n${rod.toY.toStringAsFixed(1)}',
                                    TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: rod.color),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (val, meta) {
                                    final idx = val.toInt();
                                    if (idx >= 0 && idx < schoolPerformanceList.length) {
                                      final name = schoolPerformanceList[idx].name;
                                      final shortName = name.length > 12 ? '${name.substring(0, 12)}…' : name;
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(shortName, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                      );
                                    }
                                    return const SizedBox();
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 32,
                                  getTitlesWidget: (val, meta) => Text(
                                    val.toInt().toString(),
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (val) => FlLine(
                                color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
                                strokeWidth: 1,
                                dashArray: [4, 4],
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: List.generate(schoolPerformanceList.length, (i) {
                              final item = schoolPerformanceList[i];
                              return BarChartGroupData(
                                x: i,
                                barRods: List.generate(numericFields.take(4).length, (fIdx) {
                                  final field = numericFields[fIdx];
                                  final val = item.values[field.label] ?? 0.0;
                                  return BarChartRodData(
                                    toY: val,
                                    color: _chartColors[fIdx % _chartColors.length],
                                    width: 14,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(4),
                                      topRight: Radius.circular(4),
                                    ),
                                  );
                                }),
                              );
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: List.generate(numericFields.take(4).length, (idx) {
                          final f = numericFields[idx];
                          final c = _chartColors[idx % _chartColors.length];
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 8, height: 8, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
                              const SizedBox(width: 5),
                              Text(f.label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              );

              final lineCard = Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Submissions Over Time', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (recordsOverTime.isEmpty)
                      const SizedBox(
                        height: 220,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time, size: 36, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('No records yet', style: TextStyle(fontSize: 13, color: Colors.grey)),
                            ],
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 220,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (val) => FlLine(
                                color: Theme.of(context).dividerColor.withValues(alpha: 0.6),
                                strokeWidth: 1,
                                dashArray: [4, 4],
                              ),
                            ),
                            titlesData: FlTitlesData(
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (val, meta) {
                                    final idx = val.toInt();
                                    if (idx >= 0 && idx < recordsOverTime.length) {
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text(recordsOverTime[idx].key, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                      );
                                    }
                                    return const SizedBox();
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 28,
                                  getTitlesWidget: (val, meta) => Text(
                                    val.toInt().toString(),
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(recordsOverTime.length, (i) {
                                  return FlSpot(i.toDouble(), recordsOverTime[i].value.toDouble());
                                }),
                                isCurved: true,
                                color: AppTheme.primaryColor,
                                barWidth: 2.5,
                                dotData: const FlDotData(show: true),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: performanceCard),
                    const SizedBox(width: 16),
                    Expanded(child: lineCard),
                  ],
                );
              } else {
                return Column(
                  children: [
                    performanceCard,
                    const SizedBox(height: 16),
                    lineCard,
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 20),

          // 5. Records by Type (Pie) & Recent Submissions
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 820;

              final pieCard = Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Records by Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (typeCounts.isEmpty)
                      const SizedBox(
                        height: 200,
                        child: Center(
                          child: Text('No records', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ),
                      )
                    else ...[
                      SizedBox(
                        height: 160,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 40,
                            sections: List.generate(typeCounts.length, (i) {
                              final entry = typeCounts.entries.elementAt(i);
                              final color = _chartColors[i % _chartColors.length];
                              return PieChartSectionData(
                                value: entry.value.toDouble(),
                                color: color,
                                radius: 30,
                                showTitle: false,
                              );
                            }),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: List.generate(typeCounts.length, (i) {
                          final entry = typeCounts.entries.elementAt(i);
                          final color = _chartColors[i % _chartColors.length];
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                              const SizedBox(width: 5),
                              Text(entry.key, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              );

              final recentCard = Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Recent Submissions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        InkWell(
                          onTap: () => widget.onNavigate?.call(6),
                          child: const Text(
                            'View all',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (topRecent.isEmpty)
                      const SizedBox(
                        height: 120,
                        child: Center(
                          child: Text('No records yet', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: topRecent.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final r = topRecent[index];
                          final isSynced = r.synced;

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? AppTheme.mutedDark.withValues(alpha: 0.5)
                                  : AppTheme.mutedLight.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSynced ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        getSchoolName(r.schoolId),
                                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${r.formType.toDbString()} · ${r.submittedBy}',
                                        style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.access_time, size: 11, color: Theme.of(context).textTheme.bodySmall?.color),
                                        const SizedBox(width: 3),
                                        Text(
                                          r.createdAt != null ? DateFormat('M/d/yyyy').format(r.createdAt!) : '',
                                          style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      isSynced ? 'Synced' : 'Local',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isSynced ? const Color(0xFF059669) : const Color(0xFFD97706),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 4, child: pieCard),
                    const SizedBox(width: 16),
                    Expanded(flex: 6, child: recentCard),
                  ],
                );
              } else {
                return Column(
                  children: [
                    pieCard,
                    const SizedBox(height: 16),
                    recentCard,
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 20),

          // 6. Form Fields Overview
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Form Fields Overview', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    InkWell(
                      onTap: () => widget.onNavigate?.call(5),
                      child: const Text(
                        'Manage fields',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 600;
                    return GridView.count(
                      crossAxisCount: isWide ? 4 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: isWide ? 2.0 : 1.8,
                      children: [
                        _buildFormFieldBox('Weekly', formFields.where((f) => f.formType == FormType.weekly).length),
                        _buildFormFieldBox('Termly', formFields.where((f) => f.formType == FormType.termly).length),
                        _buildFormFieldBox('Annually', formFields.where((f) => f.formType == FormType.annually).length),
                        _buildFormFieldBox('Special', formFields.where((f) => f.formType == FormType.special).length),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFieldBox(String type, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.mutedDark.withValues(alpha: 0.5)
            : AppTheme.mutedLight.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$count', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(type, style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
        ],
      ),
    );
  }

  double _calculateMaxBarY(List<_SchoolMetric> list, List<FormFieldModel> fields) {
    double maxVal = 0.0;
    for (final s in list) {
      for (final f in fields) {
        final v = s.values[f.label] ?? 0.0;
        if (v > maxVal) maxVal = v;
      }
    }
    if (maxVal <= 0) return 10.0;
    return (maxVal * 1.25);
  }
}

class _SchoolAggregation {
  final String name;
  final totals = <String, double>{};
  int count = 0;

  _SchoolAggregation({required this.name});
}

class _SchoolMetric {
  final String name;
  final Map<String, double> values;

  _SchoolMetric({required this.name, required this.values});
}
