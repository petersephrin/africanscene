import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/admin_data_provider.dart';
import '../../models/form_field_model.dart';
import '../../theme/app_theme.dart';

class AdminDashboardPage extends StatefulWidget {
  final ValueChanged<int>? onNavigate;

  const AdminDashboardPage({super.key, this.onNavigate});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  String _selectedSchool = 'all';
  String _selectedFormType = 'all';

  @override
  Widget build(BuildContext context) {
    final adminData = context.watch<AdminDataProvider>();
    final schools = adminData.schools;
    final researchers = adminData.researchers;
    final teachers = adminData.teachers;
    final allRecords = adminData.records;
    final formFields = adminData.formFields;
    final deletionRequests = adminData.deletionRequests;

    // Filter records
    final filteredRecords = allRecords.where((r) {
      if (_selectedSchool != 'all' && r.schoolId != _selectedSchool) return false;
      if (_selectedFormType != 'all' && r.formType.toDbString() != _selectedFormType) return false;
      return true;
    }).toList();

    final pendingDelCount = deletionRequests.where((r) => r.status.name == 'pending').length;

    // Distribution by form type
    final weeklyCount = filteredRecords.where((r) => r.formType == FormType.weekly).length;
    final termlyCount = filteredRecords.where((r) => r.formType == FormType.termly).length;
    final annuallyCount = filteredRecords.where((r) => r.formType == FormType.annually).length;
    final specialCount = filteredRecords.where((r) => r.formType == FormType.special).length;

    final chartColors = [
      AppTheme.primaryColor,
      AppTheme.accentColor,
      const Color(0xFF10B981),
      const Color(0xFF8B5CF6),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.filter_list, size: 18, color: AppTheme.accentColor),
                    const SizedBox(width: 8),
                    const Text('Filter Data:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                DropdownButton<String>(
                  value: _selectedSchool,
                  underline: const SizedBox(),
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('All Institutions')),
                    ...schools.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                  ],
                  onChanged: (val) => setState(() => _selectedSchool = val ?? 'all'),
                ),
                DropdownButton<String>(
                  value: _selectedFormType,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Form Categories')),
                    DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                    DropdownMenuItem(value: 'termly', child: Text('Termly')),
                    DropdownMenuItem(value: 'annually', child: Text('Annually')),
                    DropdownMenuItem(value: 'special', child: Text('Special')),
                  ],
                  onChanged: (val) => setState(() => _selectedFormType = val ?? 'all'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5 Top KPI Cards
          LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            return GridView.count(
              crossAxisCount: isWide ? 5 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: isWide ? 1.4 : 1.35,
              children: [
                _buildKpiCard(context, 'Institutions', '${schools.length}', Icons.school_outlined, AppTheme.accentColor, () => widget.onNavigate?.call(1)),
                _buildKpiCard(context, 'Researchers', '${researchers.length}', Icons.biotech_outlined, AppTheme.primaryColor, () => widget.onNavigate?.call(2)),
                _buildKpiCard(context, 'Teachers', '${teachers.length}', Icons.person_pin_outlined, const Color(0xFF10B981), () => widget.onNavigate?.call(3)),
                _buildKpiCard(context, 'Submissions', '${filteredRecords.length}', Icons.description_outlined, const Color(0xFF8B5CF6), () => widget.onNavigate?.call(6)),
                _buildKpiCard(context, 'Pending Deletions', '$pendingDelCount', Icons.delete_sweep_outlined, AppTheme.dangerColor, () => widget.onNavigate?.call(7)),
              ],
            );
          }),
          const SizedBox(height: 20),

          // Charts Row
          LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 750;

            final pieWidget = Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Submissions by Form Type', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (filteredRecords.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 36),
                      child: Center(child: Text('No records submitted for selected filters.', style: TextStyle(color: Colors.grey))),
                    )
                  else ...[
                    SizedBox(
                      height: 180,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 40,
                          sections: [
                            if (weeklyCount > 0)
                              PieChartSectionData(value: weeklyCount.toDouble(), title: '$weeklyCount', color: chartColors[0], radius: 45, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            if (termlyCount > 0)
                              PieChartSectionData(value: termlyCount.toDouble(), title: '$termlyCount', color: chartColors[1], radius: 45, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            if (annuallyCount > 0)
                              PieChartSectionData(value: annuallyCount.toDouble(), title: '$annuallyCount', color: chartColors[2], radius: 45, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            if (specialCount > 0)
                              PieChartSectionData(value: specialCount.toDouble(), title: '$specialCount', color: chartColors[3], radius: 45, titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        _buildLegend('Weekly ($weeklyCount)', chartColors[0]),
                        _buildLegend('Termly ($termlyCount)', chartColors[1]),
                        _buildLegend('Annually ($annuallyCount)', chartColors[2]),
                        _buildLegend('Special ($specialCount)', chartColors[3]),
                      ],
                    ),
                  ],
                ],
              ),
            );

            final activityWidget = Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Institutional Coverage Overview', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ...schools.take(4).map((s) {
                    final schoolRecCount = allRecords.where((r) => r.schoolId == s.id).length;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(s.name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                              Text('$schoolRecCount records', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: allRecords.isNotEmpty ? (schoolRecCount / allRecords.length).clamp(0.05, 1.0) : 0,
                              color: AppTheme.accentColor,
                              backgroundColor: AppTheme.accentColor.withOpacity(0.1),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 5, child: pieWidget),
                  const SizedBox(width: 16),
                  Expanded(flex: 6, child: activityWidget),
                ],
              );
            } else {
              return Column(
                children: [
                  pieWidget,
                  const SizedBox(height: 16),
                  activityWidget,
                ],
              );
            }
          }),
        ],
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return InkWell(
      onTap: onTap,
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 16),
                ),
              ],
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
