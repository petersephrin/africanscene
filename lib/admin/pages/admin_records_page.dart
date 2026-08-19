import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_data_provider.dart';
import '../../models/record_model.dart';
import '../../theme/app_theme.dart';
import '../../components/record_preview_modal.dart';
import '../../components/version_history_modal.dart';

class AdminRecordsPage extends StatefulWidget {
  const AdminRecordsPage({super.key});

  @override
  State<AdminRecordsPage> createState() => _AdminRecordsPageState();
}

class _AdminRecordsPageState extends State<AdminRecordsPage> {
  String _searchQuery = '';
  String _schoolFilter = 'all';
  String _formTypeFilter = 'all';

  void _showDeleteDialog(RecordModel record) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Direct Admin Delete Record?'),
        content: const Text('Are you sure you want to permanently delete this record and its version history? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            onPressed: () async {
              await context.read<AdminDataProvider>().deleteRecord(record.id);
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Record deleted permanently.')));
              }
            },
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminData = context.watch<AdminDataProvider>();
    final records = adminData.records;
    final schools = adminData.schools;

    final schoolMap = Map.fromEntries(schools.map((s) => MapEntry(s.id, s.name)));

    final filtered = records.where((r) {
      if (_schoolFilter != 'all' && r.schoolId != _schoolFilter) return false;
      if (_formTypeFilter != 'all' && r.formType.toDbString() != _formTypeFilter) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final schoolName = (schoolMap[r.schoolId] ?? '').toLowerCase();
        final submittedBy = r.submittedBy.toLowerCase();
        final matchData = r.data.values.any((v) => v.toString().toLowerCase().contains(q));
        if (!schoolName.contains(q) && !submittedBy.contains(q) && !matchData) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Filter Controls
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Wrap(
                spacing: 16,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search records...',
                        prefixIcon: Icon(Icons.search, size: 20),
                        isDense: true,
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                  DropdownButton<String>(
                    value: _schoolFilter,
                    underline: const SizedBox(),
                    items: [
                      const DropdownMenuItem(value: 'all', child: Text('All Institutions')),
                      ...schools.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                    ],
                    onChanged: (val) => setState(() => _schoolFilter = val ?? 'all'),
                  ),
                  DropdownButton<String>(
                    value: _formTypeFilter,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All Categories')),
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                      DropdownMenuItem(value: 'termly', child: Text('Termly')),
                      DropdownMenuItem(value: 'annually', child: Text('Annually')),
                      DropdownMenuItem(value: 'special', child: Text('Special')),
                    ],
                    onChanged: (val) => setState(() => _formTypeFilter = val ?? 'all'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Records List
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No matching records in repository.', style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final r = filtered[index];
                        final schoolName = schoolMap[r.schoolId] ?? 'School ${r.schoolId}';
                        final dateStr = r.createdAt != null
                            ? DateFormat('MMM d, y • h:mm a').format(r.createdAt!)
                            : '';

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.assignment, color: AppTheme.accentColor, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(schoolName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor.withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            r.formType.displayName,
                                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                                          ),
                                        ),
                                        if (r.versionNumber > 1) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppTheme.accentColor.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'v${r.versionNumber}',
                                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.accentColor),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Submitted by: ${r.submittedBy} • $dateStr',
                                      style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.visibility_outlined, size: 16),
                                label: const Text('View', style: TextStyle(fontSize: 12)),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => RecordPreviewModal(record: r, schoolName: schoolName),
                                  );
                                },
                              ),
                              TextButton.icon(
                                icon: const Icon(Icons.history, size: 16),
                                label: const Text('History', style: TextStyle(fontSize: 12)),
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => VersionHistoryModal(recordId: r.id),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.dangerColor),
                                tooltip: 'Delete Permanently',
                                onPressed: () => _showDeleteDialog(r),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
