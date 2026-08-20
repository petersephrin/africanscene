import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/deletion_request_model.dart';
import '../../theme/app_theme.dart';

class AdminDeletionRequestsPage extends StatefulWidget {
  const AdminDeletionRequestsPage({super.key});

  @override
  State<AdminDeletionRequestsPage> createState() => _AdminDeletionRequestsPageState();
}

class _AdminDeletionRequestsPageState extends State<AdminDeletionRequestsPage> {
  // ==========================================
  // CONFIRM ACTION DIALOG (APPROVE / REJECT)
  // ==========================================
  void _confirmAction({
    required DeletionRequestModel request,
    required DeletionStatus action,
    required String requesterName,
    required String schoolName,
    required String formType,
  }) {
    final isApprove = action == DeletionStatus.approved;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isApprove ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
              color: isApprove ? AppTheme.successColor : AppTheme.dangerColor,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              isApprove ? 'Approve Deletion?' : 'Reject Request?',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          isApprove
              ? 'Are you sure you want to approve this deletion request from $requesterName? The $formType record for $schoolName will be permanently deleted.'
              : 'Are you sure you want to reject this deletion request from $requesterName? The record will remain intact.',
          style: const TextStyle(fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? AppTheme.successColor : AppTheme.dangerColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final adminData = context.read<AdminDataProvider>();
              final auth = context.read<AuthProvider>();
              final currentUser = auth.user;

              if (currentUser != null) {
                await adminData.reviewDeletionRequest(
                  requestId: request.id,
                  recordId: request.recordId,
                  status: action,
                  reviewer: currentUser,
                );

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isApprove
                            ? 'Request approved. Record has been deleted.'
                            : 'Request was rejected.',
                      ),
                      backgroundColor: isApprove ? AppTheme.successColor : const Color(0xFF4A3E39),
                    ),
                  );
                }
              }
            },
            child: Text(isApprove ? 'Approve & Delete' : 'Reject Request'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminData = context.watch<AdminDataProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    final allRequests = adminData.deletionRequests;
    final allRecords = adminData.records;
    final allSchools = adminData.schools;
    final allUsers = adminData.users;

    final schoolMap = Map.fromEntries(allSchools.map((s) => MapEntry(s.id, s.name)));
    final userMap = Map.fromEntries(allUsers.map((u) => MapEntry(u.id, u.name)));
    final recordMap = Map.fromEntries(allRecords.map((r) => MapEntry(r.id, r)));

    final pending = allRequests.where((r) => r.status == DeletionStatus.pending).toList();
    final resolved = allRequests.where((r) => r.status != DeletionStatus.pending).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Deletion Requests',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.textLight : AppTheme.textDark,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${pending.length} pending · ${resolved.length} resolved',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // 2. Pending Requests Section
            if (pending.isNotEmpty) ...[
              Text(
                'Pending Requests',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.textLight : AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: pending.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final req = pending[index];
                  final requesterName = req.requesterName ?? userMap[req.requestedBy] ?? req.requestedBy;
                  final relatedRecord = recordMap[req.recordId];
                  final schoolName = relatedRecord != null
                      ? (schoolMap[relatedRecord.schoolId] ?? 'School ${relatedRecord.schoolId}')
                      : 'Unknown School';
                  final formType = relatedRecord?.formType.displayName ?? 'Record';
                  final dateStr = req.createdAt != null
                      ? DateFormat('d/M/yyyy, h:mm:ss a').format(req.createdAt!)
                      : '—';

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF92400E) : const Color(0xFFFDE68A),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Name & Type
                              Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber_rounded,
                                    size: 16,
                                    color: Color(0xFFD97706),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    requesterName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF3B332E) : const Color(0xFFF3ECE6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      formType.toLowerCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 4),

                              // School & Date
                              Text(
                                '$schoolName · $dateStr',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppTheme.textMutedDark : const Color(0xFF85746E),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Reason Box
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF231E1B)
                                      : const Color(0xFFF7F5F3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '"${req.reason}"',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Right Action Buttons (Approve & Reject)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Approve Button
                            InkWell(
                              onTap: () => _confirmAction(
                                request: req,
                                action: DeletionStatus.approved,
                                requesterName: requesterName,
                                schoolName: schoolName,
                                formType: formType,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF064E3B).withValues(alpha: 0.3)
                                      : const Color(0xFFD1FAE5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.check_rounded,
                                  size: 18,
                                  color: isDark
                                      ? const Color(0xFF34D399)
                                      : const Color(0xFF047857),
                                ),
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Reject Button
                            InkWell(
                              onTap: () => _confirmAction(
                                request: req,
                                action: DeletionStatus.rejected,
                                requesterName: requesterName,
                                schoolName: schoolName,
                                formType: formType,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 18,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],

            // 3. Resolved Requests Section
            if (resolved.isNotEmpty) ...[
              Text(
                'Resolved',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.textLight : AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 12),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: resolved.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final req = resolved[index];
                  final isApproved = req.status == DeletionStatus.approved;
                  final requesterName = req.requesterName ?? userMap[req.requestedBy] ?? req.requestedBy;
                  final relatedRecord = recordMap[req.recordId];
                  final schoolName = relatedRecord != null
                      ? (schoolMap[relatedRecord.schoolId] ?? 'School ${relatedRecord.schoolId}')
                      : 'Unknown School';
                  final formType = relatedRecord?.formType.displayName ?? 'Record';
                  final dateStr = req.createdAt != null
                      ? DateFormat('d/M/yyyy, h:mm:ss a').format(req.createdAt!)
                      : '—';

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppTheme.borderDark : const Color(0xFFEBE6E2),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isApproved ? Icons.check_rounded : Icons.close_rounded,
                              size: 15,
                              color: isApproved ? const Color(0xFF059669) : const Color(0xFFDC2626),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              requesterName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? AppTheme.textLight : AppTheme.textDark,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF3B332E) : const Color(0xFFF3ECE6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                formType.toLowerCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isApproved
                                    ? (isDark
                                        ? const Color(0xFF064E3B).withValues(alpha: 0.3)
                                        : const Color(0xFFD1FAE5))
                                    : const Color(0xFFDC2626).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                req.status.toDbString(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: isApproved
                                      ? (isDark
                                          ? const Color(0xFF34D399)
                                          : const Color(0xFF047857))
                                      : const Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$schoolName · $dateStr',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppTheme.textMutedDark : const Color(0xFF85746E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '"${req.reason}"',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: isDark ? AppTheme.textMutedDark : const Color(0xFF85746E),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],

            // 4. Empty State
            if (allRequests.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 64),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppTheme.borderDark : const Color(0xFFEBE6E2),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.delete_outline_rounded,
                      size: 40,
                      color: (isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight)
                          .withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'No deletion requests',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
