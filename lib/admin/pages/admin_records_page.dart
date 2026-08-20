import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_data_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/record_model.dart';
import '../../models/form_field_model.dart';
import '../../services/firestore_service.dart';
import '../../services/export_service.dart';
import '../../theme/app_theme.dart';

class AdminRecordsPage extends StatefulWidget {
  const AdminRecordsPage({super.key});

  @override
  State<AdminRecordsPage> createState() => _AdminRecordsPageState();
}

class _AdminRecordsPageState extends State<AdminRecordsPage> {
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();

  String _searchQuery = '';
  String _filterType = 'all'; // 'all', 'weekly', 'termly', 'annually', 'special'
  String _filterSchool = 'all'; // 'all' or schoolId
  int _page = 0;
  static const int _pageSize = 50;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ==========================================
  // CSV EXPORT LOGIC
  // ==========================================
  Future<void> _exportToCSV(List<RecordModel> recordsToExport, String label, Map<String, String> schoolMap) async {
    if (recordsToExport.isEmpty) return;

    const metaKeys = {'submittedBy', 'school', 'time'};
    final keySet = <String>{};
    for (final r in recordsToExport) {
      for (final k in r.data.keys) {
        if (!metaKeys.contains(k)) {
          keySet.add(k);
        }
      }
    }
    final dataKeys = keySet.toList()..sort();

    final headers = ['School', 'Form Type', 'Submitted By', 'Date & Time', 'Status', ...dataKeys];
    final rows = <List<dynamic>>[];

    for (final r in recordsToExport) {
      final schoolName = schoolMap[r.schoolId] ?? r.schoolId;
      final dateStr = r.createdAt != null
          ? DateFormat('yyyy-MM-dd HH:mm').format(r.createdAt!)
          : '';
      final status = r.synced ? 'Synced' : 'Pending';

      final row = <dynamic>[
        schoolName,
        r.formType.displayName,
        r.submittedBy,
        dateStr,
        status,
        ...dataKeys.map((k) {
          final val = r.data[k];
          if (val == null) return '';
          return val.toString();
        }),
      ];
      rows.add(row);
    }

    final filename = 'records-$label-${DateFormat('yyyy-MM-dd').format(DateTime.now())}';

    await ExportService.exportToCsv(
      filename: filename,
      headers: headers,
      rows: rows,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported ${recordsToExport.length} records to CSV.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  // ==========================================
  // VERSION HISTORY DIALOG
  // ==========================================
  void _showVersionHistoryDialog(RecordModel record, String schoolName) {
    final themeProvider = context.read<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder: (ctx) => FutureBuilder<List<RecordVersionModel>>(
        future: _firestoreService.fetchRecordVersions(record.id),
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final versions = snapshot.data ?? [];

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Theme.of(context).cardColor,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520, maxHeight: 600),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.history_rounded, size: 20, color: AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Version History & Audit Log',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppTheme.textLight : AppTheme.textDark,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(ctx),
                          color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                        ),
                      ],
                    ),

                    Text(
                      '$schoolName • ${record.formType.displayName} Record',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                      ),
                    ),

                    const SizedBox(height: 16),
                    Divider(color: Theme.of(context).dividerColor),
                    const SizedBox(height: 12),

                    // Version List Content
                    Expanded(
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : versions.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.history_rounded,
                                        size: 40,
                                        color: (isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight)
                                            .withValues(alpha: 0.4),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No historical revisions recorded for this record.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  itemCount: versions.length,
                                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                                  itemBuilder: (context, idx) {
                                    final ver = versions[idx];
                                    final dateStr = ver.createdAt != null
                                        ? DateFormat('MMM d, yyyy · h:mm a').format(ver.createdAt!)
                                        : '—';

                                    return Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: isDark ? AppTheme.mutedDark : const Color(0xFFF7F5F3),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isDark ? AppTheme.borderDark : const Color(0xFFEBE6E2),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: isDark ? const Color(0xFF38251E) : const Color(0xFFFDEEE7),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  'Version ${ver.versionNumber}',
                                                  style: const TextStyle(
                                                    color: AppTheme.primaryColor,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                dateStr,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Reason: ${ver.editReason.isNotEmpty ? ver.editReason : "Unspecified update"}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              fontStyle: FontStyle.italic,
                                              color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Edited by: ${ver.editedBy.isNotEmpty ? ver.editedBy : "Admin"}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                    ),

                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDark ? AppTheme.borderDark : const Color(0xFFEBE6E2),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ==========================================
  // RECORD PREVIEW MODAL
  // ==========================================
  void _showRecordPreviewDialog(RecordModel record, String schoolName) {
    final themeProvider = context.read<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    const metaKeys = {'submittedBy', 'school', 'time'};
    final dataEntries = record.data.entries.where((e) => !metaKeys.contains(e.key)).toList();

    final dateStr = record.createdAt != null
        ? DateFormat('EEE, d MMM yyyy').format(record.createdAt!)
        : '—';
    final timeStr = record.createdAt != null
        ? DateFormat('h:mm a').format(record.createdAt!)
        : '—';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).cardColor,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.description_outlined, size: 20, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          '${record.formType.displayName} Record',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.textLight : AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                    ),
                  ],
                ),

                Text(
                  'Submitted on $dateStr at $timeStr',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                  ),
                ),

                const SizedBox(height: 16),
                Divider(color: Theme.of(context).dividerColor),
                const SizedBox(height: 16),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Meta Info Grid 2x2
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // School
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.school_outlined,
                                    size: 16,
                                    color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'SCHOOL',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                            color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          schoolName,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Submitted By
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.person_outline_rounded,
                                    size: 16,
                                    color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'SUBMITTED BY',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                            color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          record.submittedBy,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date & Time
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 16,
                                    color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'DATE & TIME',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                            color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$dateStr · $timeStr',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Status
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    record.synced ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                                    size: 16,
                                    color: record.synced ? AppTheme.primaryColor : const Color(0xFFDC2626),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'STATUS',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                            color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          record.synced ? 'Synced' : 'Pending',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: record.synced ? AppTheme.primaryColor : const Color(0xFFDC2626),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),
                        Divider(color: Theme.of(context).dividerColor),
                        const SizedBox(height: 14),

                        // Form Data Values
                        Text(
                          'RECORD DATA',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                            color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                          ),
                        ),
                        const SizedBox(height: 8),

                        if (dataEntries.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'No form data available',
                              style: TextStyle(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                              ),
                            ),
                          )
                        else
                          Column(
                            children: dataEntries.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final key = entry.value.key;
                              final val = entry.value.value;

                              return Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: isDark ? AppTheme.borderDark : const Color(0xFFEBE6E2),
                                      width: 0.8,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 5,
                                      child: Text(
                                        '${idx + 1}. $key',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? AppTheme.textMutedDark : const Color(0xFF85746E),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      flex: 5,
                                      child: Text(
                                        val is bool ? (val ? 'Yes' : 'No') : val.toString(),
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
                Divider(color: Theme.of(context).dividerColor),
                const SizedBox(height: 14),

                // Dialog Footer Actions
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showVersionHistoryDialog(record, schoolName);
                      },
                      icon: const Icon(Icons.history_rounded, size: 16),
                      label: const Text('Version History', style: TextStyle(fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isDark ? AppTheme.borderDark : const Color(0xFFEBE6E2),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                    ),
                    const Spacer(),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isDark ? AppTheme.borderDark : const Color(0xFFEBE6E2),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      ),
                      child: const Text('Close', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // MAIN BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final adminData = context.watch<AdminDataProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    final records = adminData.records;
    final schools = adminData.schools;
    final schoolMap = Map.fromEntries(schools.map((s) => MapEntry(s.id, s.name)));

    final filtered = records.where((r) {
      final matchSchool = _filterSchool == 'all' || r.schoolId == _filterSchool;
      final matchType = _filterType == 'all' || r.formType.toDbString() == _filterType;

      if (!matchSchool || !matchType) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase().trim();
        final sName = (schoolMap[r.schoolId] ?? '').toLowerCase();
        final subBy = r.submittedBy.toLowerCase();
        final matchData = r.data.values.any((v) => v.toString().toLowerCase().contains(q));
        if (!sName.contains(q) && !subBy.contains(q) && !matchData) return false;
      }
      return true;
    }).toList();

    final paginated = filtered.take((_page + 1) * _pageSize).toList();
    final hasMore = paginated.length < filtered.length;

    final syncedCount = filtered.where((r) => r.synced).length;
    final pendingCount = filtered.where((r) => !r.synced).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Section: Title, Subtitle, and "Export CSV" Button
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 620;
                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Records',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.textLight : AppTheme.textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${records.length} total submissions across all schools',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: filtered.isEmpty
                            ? null
                            : () => _exportToCSV(filtered, _filterType == 'all' ? 'all' : _filterType, schoolMap),
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text(
                          'Export CSV',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                          disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'All Records',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppTheme.textLight : AppTheme.textDark,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${records.length} total submissions across all schools',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: filtered.isEmpty
                          ? null
                          : () => _exportToCSV(filtered, _filterType == 'all' ? 'all' : _filterType, schoolMap),
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text(
                        'Export CSV',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                        disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // 2. Stats Cards (3 cards: Total, Synced, Pending)
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Total',
                    value: '${records.length}',
                    valueColor: isDark ? AppTheme.textLight : AppTheme.textDark,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Synced',
                    value: '$syncedCount',
                    valueColor: AppTheme.primaryColor,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Pending',
                    value: '$pendingCount',
                    valueColor: const Color(0xFFDC2626),
                    isDark: isDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 3. Export by Type Buttons Row
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EXPORT BY FORM TYPE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: FormType.values.map((type) {
                    final typeRecords = records.where((r) => r.formType == type).toList();
                    return InkWell(
                      onTap: typeRecords.isEmpty
                          ? null
                          : () => _exportToCSV(typeRecords, type.toDbString(), schoolMap),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF231E1B) : const Color(0xFFF7F5F3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? AppTheme.borderDark : const Color(0xFFEBE6E2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.download_rounded,
                              size: 14,
                              color: typeRecords.isEmpty
                                  ? (isDark ? AppTheme.textMutedDark : const Color(0xFF85746E)).withValues(alpha: 0.4)
                                  : AppTheme.primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${type.displayName} (${typeRecords.length})',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: typeRecords.isEmpty
                                    ? (isDark ? AppTheme.textMutedDark : const Color(0xFF85746E)).withValues(alpha: 0.4)
                                    : (isDark ? AppTheme.textLight : AppTheme.textDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 4. Search and Filters Row
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 680;
                if (isNarrow) {
                  return Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF231E1B) : const Color(0xFFF7F5F3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppTheme.borderDark : const Color(0xFFEBE6E2),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              color: isDark ? AppTheme.textMutedDark : const Color(0xFF85746E),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) => setState(() {
                                  _searchQuery = val;
                                  _page = 0;
                                }),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search records…',
                                  hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppTheme.textMutedDark : const Color(0xFF85746E),
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16),
                                color: isDark ? AppTheme.textMutedDark : const Color(0xFF85746E),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                    _page = 0;
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF231E1B) : const Color(0xFFF7F5F3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? AppTheme.borderDark : const Color(0xFFEBE6E2),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.filter_list_rounded,
                                    size: 16,
                                    color: isDark ? AppTheme.textMutedDark : const Color(0xFF85746E),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _filterType,
                                        isExpanded: true,
                                        dropdownColor: Theme.of(context).cardColor,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                        ),
                                        items: const [
                                          DropdownMenuItem(value: 'all', child: Text('All types')),
                                          DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                                          DropdownMenuItem(value: 'termly', child: Text('Termly')),
                                          DropdownMenuItem(value: 'annually', child: Text('Annually')),
                                          DropdownMenuItem(value: 'special', child: Text('Special')),
                                        ],
                                        onChanged: (val) => setState(() {
                                          _filterType = val ?? 'all';
                                          _page = 0;
                                        }),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF231E1B) : const Color(0xFFF7F5F3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? AppTheme.borderDark : const Color(0xFFEBE6E2),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _filterSchool,
                                  isExpanded: true,
                                  dropdownColor: Theme.of(context).cardColor,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                  ),
                                  items: [
                                    const DropdownMenuItem(value: 'all', child: Text('All schools', overflow: TextOverflow.ellipsis)),
                                    ...schools.map((s) => DropdownMenuItem(
                                      value: s.id,
                                      child: Text(s.name, overflow: TextOverflow.ellipsis),
                                    )),
                                  ],
                                  onChanged: (val) => setState(() {
                                    _filterSchool = val ?? 'all';
                                    _page = 0;
                                  }),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                }

                return Row(
                  children: [
                    // Search Input
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF231E1B) : const Color(0xFFF7F5F3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppTheme.borderDark : const Color(0xFFEBE6E2),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search_rounded,
                              color: isDark ? AppTheme.textMutedDark : const Color(0xFF85746E),
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) => setState(() {
                                  _searchQuery = val;
                                  _page = 0;
                                }),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search records…',
                                  hintStyle: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppTheme.textMutedDark : const Color(0xFF85746E),
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  filled: false,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                            if (_searchQuery.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16),
                                color: isDark ? AppTheme.textMutedDark : const Color(0xFF85746E),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                    _page = 0;
                                  });
                                },
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Form Type Filter Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF231E1B) : const Color(0xFFF7F5F3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppTheme.borderDark : const Color(0xFFEBE6E2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.filter_list_rounded,
                            size: 16,
                            color: isDark ? AppTheme.textMutedDark : const Color(0xFF85746E),
                          ),
                          const SizedBox(width: 6),
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _filterType,
                              dropdownColor: Theme.of(context).cardColor,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppTheme.textLight : AppTheme.textDark,
                              ),
                              items: const [
                                DropdownMenuItem(value: 'all', child: Text('All types')),
                                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                                DropdownMenuItem(value: 'termly', child: Text('Termly')),
                                DropdownMenuItem(value: 'annually', child: Text('Annually')),
                                DropdownMenuItem(value: 'special', child: Text('Special')),
                              ],
                              onChanged: (val) => setState(() {
                                _filterType = val ?? 'all';
                                _page = 0;
                              }),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // School Filter Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF231E1B) : const Color(0xFFF7F5F3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppTheme.borderDark : const Color(0xFFEBE6E2),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _filterSchool,
                          dropdownColor: Theme.of(context).cardColor,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppTheme.textLight : AppTheme.textDark,
                          ),
                          items: [
                            const DropdownMenuItem(value: 'all', child: Text('All schools')),
                            ...schools.map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name),
                            )),
                          ],
                          onChanged: (val) => setState(() {
                            _filterSchool = val ?? 'all';
                            _page = 0;
                          }),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // 5. Records Table Card
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppTheme.borderDark : const Color(0xFFEBE6E2),
                  width: 1,
                ),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              clipBehavior: Clip.antiAlias,
              child: filtered.isEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(vertical: 64),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.bar_chart_rounded,
                            size: 44,
                            color: (isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight)
                                .withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No records matching "$_searchQuery"'
                                : 'No records found',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                            ),
                          ),
                          if (_searchQuery.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            OutlinedButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _page = 0;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: isDark ? AppTheme.borderDark : const Color(0xFFEBE6E2),
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Clear search'),
                            ),
                          ],
                        ],
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final double tableWidth = constraints.maxWidth > 860 ? constraints.maxWidth : 860;
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: tableWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                            // Table Header Row
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E1917) : const Color(0xFFFAF7F5),
                                border: Border(
                                  bottom: BorderSide(
                                    color: isDark ? AppTheme.borderDark : const Color(0xFFEBE6E2),
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'SCHOOL',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.6,
                                        color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'TYPE',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.6,
                                        color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'SUBMITTED BY',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.6,
                                        color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'DATE & TIME',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.6,
                                        color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'STATUS',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.6,
                                        color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 60,
                                    child: Text(
                                      'VIEW',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.6,
                                        color: Color(0xFF85746E),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Table Body Rows
                            ...paginated.asMap().entries.map((entry) {
                              final index = entry.key;
                              final r = entry.value;
                              final isLast = index == paginated.length - 1;
                              final schoolName = schoolMap[r.schoolId] ?? 'School ${r.schoolId}';
                              final initialLetter = schoolName.trim().isNotEmpty
                                  ? schoolName.trim()[0].toUpperCase()
                                  : 'S';
                              final dateStr = r.createdAt != null
                                  ? DateFormat('MMM d, yyyy · h:mm a').format(r.createdAt!)
                                  : '—';

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                decoration: BoxDecoration(
                                  border: isLast
                                      ? null
                                      : Border(
                                          bottom: BorderSide(
                                            color: isDark ? AppTheme.borderDark : const Color(0xFFEBE6E2),
                                            width: 1,
                                          ),
                                        ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // 1. School
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 26,
                                            height: 26,
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xFF38251E)
                                                  : const Color(0xFFFDEEE7),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              initialLetter,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              schoolName,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // 2. Type
                                    Expanded(
                                      flex: 2,
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF3B332E) : const Color(0xFFF3ECE6),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            r.formType.toDbString(),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),

                                    // 3. Submitted By
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        r.submittedBy,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? AppTheme.textMutedDark : const Color(0xFF85746E),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                    // 4. Date & Time
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.access_time_rounded,
                                            size: 13,
                                            color: isDark ? AppTheme.textMutedDark : const Color(0xFF85746E),
                                          ),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: Text(
                                              dateStr,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark ? AppTheme.textMutedDark : const Color(0xFF85746E),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // 5. Status
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        children: [
                                          Icon(
                                            r.synced ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded,
                                            size: 13,
                                            color: r.synced ? AppTheme.primaryColor : const Color(0xFFDC2626),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            r.synced ? 'Synced' : 'Pending',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: r.synced ? AppTheme.primaryColor : const Color(0xFFDC2626),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // 6. View Button
                                    SizedBox(
                                      width: 60,
                                      child: Center(
                                        child: IconButton(
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                          icon: Icon(
                                            Icons.visibility_outlined,
                                            size: 17,
                                            color: isDark ? AppTheme.textMutedDark : const Color(0xFF85746E),
                                          ),
                                          tooltip: 'Preview record',
                                          onPressed: () => _showRecordPreviewDialog(r, schoolName),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),

                            // Load More Button
                            if (hasMore)
                              Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: isDark ? AppTheme.borderDark : const Color(0xFFEBE6E2),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: TextButton(
                                  onPressed: () => setState(() => _page++),
                                  child: Text(
                                    'Load more (${filtered.length - paginated.length} remaining)',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
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

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color valueColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : const Color(0xFFEBE6E2),
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
            ),
          ),
        ],
      ),
    );
  }
}
