import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/deletion_request_model.dart';
import '../../theme/app_theme.dart';
import '../../components/record_preview_modal.dart';

class AdminDeletionRequestsPage extends StatefulWidget {
  const AdminDeletionRequestsPage({super.key});

  @override
  State<AdminDeletionRequestsPage> createState() => _AdminDeletionRequestsPageState();
}

class _AdminDeletionRequestsPageState extends State<AdminDeletionRequestsPage> {
  String _statusFilter = 'pending';

  @override
  Widget build(BuildContext context) {
    final adminData = context.watch<AdminDataProvider>();
    final auth = context.watch<AuthProvider>();
    final currentUser = auth.user;
    final allRequests = adminData.deletionRequests;
    final allRecords = adminData.records;
    final allSchools = adminData.schools;
    final schoolMap = Map.fromEntries(allSchools.map((s) => MapEntry(s.id, s.name)));

    final filtered = allRequests.where((req) {
      if (_statusFilter != 'all' && req.status.toDbString() != _statusFilter) return false;
      return true;
    }).toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Filter Tabs
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  const Text('Status Filter:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 14),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildFilterChip('Pending', 'pending', allRequests.where((r) => r.status == DeletionStatus.pending).length),
                      _buildFilterChip('Approved', 'approved', allRequests.where((r) => r.status == DeletionStatus.approved).length),
                      _buildFilterChip('Rejected', 'rejected', allRequests.where((r) => r.status == DeletionStatus.rejected).length),
                      _buildFilterChip('All Requests', 'all', allRequests.length),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Queue List
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline, size: 52, color: Colors.grey.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          Text('No $_statusFilter deletion requests in queue.', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final req = filtered[index];
                        final relatedRecord = allRecords.where((r) => r.id == req.recordId).firstOrNull;
                        final dateStr = req.createdAt != null
                            ? DateFormat('MMM d, y • h:mm a').format(req.createdAt!)
                            : '';

                        return Container(
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: _getStatusColor(req.status).withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          req.status.displayName.toUpperCase(),
                                          style: TextStyle(
                                            color: _getStatusColor(req.status),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        'Record ID: ${req.recordId.length > 12 ? req.recordId.substring(0, 12) + "..." : req.recordId}',
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  Text(dateStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Reason: "${req.reason}"',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontStyle: FontStyle.italic),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Requested by: ${req.requesterName ?? req.requestedBy}',
                                style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                              ),
                              if (req.reviewedBy != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Reviewed by: ${req.reviewerName ?? req.reviewedBy}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                              const SizedBox(height: 12),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (relatedRecord != null)
                                    TextButton.icon(
                                      icon: const Icon(Icons.visibility_outlined, size: 16),
                                      label: const Text('Inspect Record Data', style: TextStyle(fontSize: 12)),
                                      onPressed: () {
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (_) => RecordPreviewModal(
                                            record: relatedRecord,
                                            schoolName: schoolMap[relatedRecord.schoolId],
                                          ),
                                        );
                                      },
                                    ),
                                  if (req.status == DeletionStatus.pending && currentUser != null) ...[
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.dangerColor,
                                        side: const BorderSide(color: AppTheme.dangerColor),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      icon: const Icon(Icons.check, size: 16),
                                      label: const Text('Approve & Delete Record', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      onPressed: () async {
                                        await adminData.reviewDeletionRequest(
                                          requestId: req.id,
                                          recordId: req.recordId,
                                          status: DeletionStatus.approved,
                                          reviewer: currentUser,
                                        );
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Deletion request approved and record removed.'), backgroundColor: AppTheme.successColor),
                                          );
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      icon: const Icon(Icons.close, size: 16),
                                      label: const Text('Reject Request', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                      onPressed: () async {
                                        await adminData.reviewDeletionRequest(
                                          requestId: req.id,
                                          recordId: req.recordId,
                                          status: DeletionStatus.rejected,
                                          reviewer: currentUser,
                                        );
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Deletion request rejected.')),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ],
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

  Widget _buildFilterChip(String label, String value, int count) {
    final isSelected = _statusFilter == value;
    return ChoiceChip(
      label: Text('$label ($count)', style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : null)),
      selected: isSelected,
      selectedColor: AppTheme.accentColor,
      onSelected: (_) => setState(() => _statusFilter = value),
    );
  }

  Color _getStatusColor(DeletionStatus status) {
    switch (status) {
      case DeletionStatus.approved:
        return AppTheme.successColor;
      case DeletionStatus.rejected:
        return AppTheme.dangerColor;
      case DeletionStatus.pending:
        return AppTheme.warningColor;
    }
  }
}
