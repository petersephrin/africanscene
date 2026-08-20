import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_data_provider.dart';
import '../../models/form_field_model.dart';
import '../../services/export_service.dart';
import '../../theme/app_theme.dart';

enum ExportTarget {
  schools,
  researchers,
  teachers,
  staff,
  formFields,
  deletionRequests,
  recordsAll,
  recordsWeekly,
  recordsTermly,
  recordsAnnually,
  recordsSpecial,
}

enum ExportFormat {
  csv,
  xlsx,
  json,
}

class AdminDataDownloadPage extends StatefulWidget {
  const AdminDataDownloadPage({super.key});

  @override
  State<AdminDataDownloadPage> createState() => _AdminDataDownloadPageState();
}

class _AdminDataDownloadPageState extends State<AdminDataDownloadPage> {
  ExportTarget _selectedTarget = ExportTarget.recordsAll;
  ExportFormat _selectedFormat = ExportFormat.xlsx;
  String _selectedSchool = 'all';
  bool _isExporting = false;

  Future<void> _handleDownload() async {
    final adminData = context.read<AdminDataProvider>();
    final schools = adminData.schools;
    final records = adminData.records;
    final fields = adminData.formFields;
    final requests = adminData.deletionRequests;

    final schoolMap = Map.fromEntries(schools.map((s) => MapEntry(s.id, s.name)));

    setState(() => _isExporting = true);

    try {
      final dateTag = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      String filename = 'africanscene_export_$dateTag';
      List<String> headers = [];
      List<List<dynamic>> rows = [];
      dynamic jsonData;

      switch (_selectedTarget) {
        case ExportTarget.schools:
          filename = 'schools_registry_$dateTag';
          headers = ['ID', 'Name', 'Location', 'Type', 'Students', 'Motto', 'Principal', 'Phone', 'Email', 'Established'];
          rows = schools.map((s) => [s.id, s.name, s.location, s.type, s.students, s.motto ?? '', s.principal ?? '', s.phone ?? '', s.email ?? '', s.established]).toList();
          jsonData = schools.map((s) => s.toMap()).toList();
          break;

        case ExportTarget.researchers:
          filename = 'researchers_directory_$dateTag';
          final list = adminData.researchers;
          headers = ['ID', 'Name', 'Email', 'Phone', 'Specialization', 'Assigned School Count', 'Status'];
          rows = list.map((u) => [u.id, u.name, u.email, u.phone ?? '', u.specialization ?? '', u.schoolIds.length, u.status]).toList();
          jsonData = list.map((u) => u.toMap()).toList();
          break;

        case ExportTarget.teachers:
          filename = 'teachers_directory_$dateTag';
          final list = adminData.teachers;
          headers = ['ID', 'Name', 'Email', 'Phone', 'Subject/Grade', 'Assigned School Count', 'Status'];
          rows = list.map((u) => [u.id, u.name, u.email, u.phone ?? '', u.specialization ?? '', u.schoolIds.length, u.status]).toList();
          jsonData = list.map((u) => u.toMap()).toList();
          break;

        case ExportTarget.staff:
          filename = 'staff_directory_$dateTag';
          final list = adminData.staff;
          headers = ['ID', 'Name', 'Email', 'Phone', 'Role', 'Department', 'Status'];
          rows = list.map((u) => [u.id, u.name, u.email, u.phone ?? '', u.role.displayName, u.department ?? '', u.status]).toList();
          jsonData = list.map((u) => u.toMap()).toList();
          break;

        case ExportTarget.formFields:
          filename = 'form_fields_templates_$dateTag';
          headers = ['ID', 'Form Type', 'Order', 'Label', 'Field Type', 'Required', 'Placeholder', 'Options'];
          rows = fields.map((f) => [f.id, f.formType.displayName, f.fieldOrder, f.label, f.fieldType.displayName, f.required, f.placeholder ?? '', f.options.join('|')]).toList();
          jsonData = fields.map((f) => f.toMap()).toList();
          break;

        case ExportTarget.deletionRequests:
          filename = 'deletion_requests_audit_$dateTag';
          headers = ['ID', 'Record ID', 'Requester', 'Reason', 'Status', 'Reviewer', 'Created At'];
          rows = requests.map((r) => [r.id, r.recordId, r.requesterName ?? r.requestedBy, r.reason, r.status.displayName, r.reviewerName ?? r.reviewedBy ?? '', r.createdAt?.toIso8601String() ?? '']).toList();
          jsonData = requests.map((r) => r.toMap()).toList();
          break;

        case ExportTarget.recordsAll:
        case ExportTarget.recordsWeekly:
        case ExportTarget.recordsTermly:
        case ExportTarget.recordsAnnually:
        case ExportTarget.recordsSpecial:
          FormType? filterType;
          if (_selectedTarget == ExportTarget.recordsWeekly) filterType = FormType.weekly;
          if (_selectedTarget == ExportTarget.recordsTermly) filterType = FormType.termly;
          if (_selectedTarget == ExportTarget.recordsAnnually) filterType = FormType.annually;
          if (_selectedTarget == ExportTarget.recordsSpecial) filterType = FormType.special;

          final targetRecords = records.where((r) {
            if (_selectedSchool != 'all' && r.schoolId != _selectedSchool) return false;
            if (filterType != null && r.formType != filterType) return false;
            return true;
          }).toList();

          filename = '${filterType?.displayName.toLowerCase() ?? "all"}_records_$dateTag';

          // Extract all dynamic field keys from records
          final allKeys = <String>{};
          for (var r in targetRecords) {
            allKeys.addAll(r.data.keys);
          }
          final keyList = allKeys.toList();

          headers = ['Record ID', 'School Name', 'Category', 'Submitted By', 'Version', 'Submitted Date', ...keyList];
          rows = targetRecords.map((r) {
            final dateStr = r.createdAt != null ? DateFormat('yyyy-MM-dd HH:mm').format(r.createdAt!) : '';
            return [
              r.id,
              schoolMap[r.schoolId] ?? r.schoolId,
              r.formType.displayName,
              r.submittedBy,
              r.versionNumber,
              dateStr,
              ...keyList.map((k) => r.data[k] ?? ''),
            ];
          }).toList();

          jsonData = targetRecords.map((r) => {
            'id': r.id,
            'school': schoolMap[r.schoolId] ?? r.schoolId,
            'formType': r.formType.displayName,
            'submittedBy': r.submittedBy,
            'versionNumber': r.versionNumber,
            'createdAt': r.createdAt?.toIso8601String(),
            'data': r.data,
          }).toList();
          break;
      }

      if (_selectedFormat == ExportFormat.csv) {
        await ExportService.exportToCsv(filename: filename, headers: headers, rows: rows);
      } else if (_selectedFormat == ExportFormat.xlsx) {
        await ExportService.exportToExcel(filename: filename, sheetName: 'Dataset', headers: headers, rows: rows);
      } else {
        await ExportService.exportToJson(filename: filename, jsonData: jsonData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded $filename.${_selectedFormat.name}!'), backgroundColor: AppTheme.successColor),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e'), backgroundColor: AppTheme.dangerColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminData = context.watch<AdminDataProvider>();
    final schools = adminData.schools;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.cloud_download_outlined, color: AppTheme.accentColor, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Data Export Center', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(
                          'Generate complete institutional backups and research spreadsheets in Excel, CSV, or structured JSON formats.',
                          style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Target Selection Grid
            const Text('1. Select Dataset Category', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildTargetCard(ExportTarget.recordsAll, 'All Submissions', Icons.description_outlined),
                _buildTargetCard(ExportTarget.recordsWeekly, 'Weekly Records', Icons.calendar_today_outlined),
                _buildTargetCard(ExportTarget.recordsTermly, 'Termly Records', Icons.menu_book_outlined),
                _buildTargetCard(ExportTarget.recordsAnnually, 'Annual Records', Icons.school_outlined),
                _buildTargetCard(ExportTarget.recordsSpecial, 'Special Records', Icons.star_outline),
                _buildTargetCard(ExportTarget.schools, 'Institutions Registry', Icons.apartment_outlined),
                _buildTargetCard(ExportTarget.researchers, 'Researchers Directory', Icons.biotech_outlined),
                _buildTargetCard(ExportTarget.teachers, 'Teachers Directory', Icons.person_pin_outlined),
                _buildTargetCard(ExportTarget.staff, 'Staff Members', Icons.badge_outlined),
                _buildTargetCard(ExportTarget.formFields, 'Form Fields Templates', Icons.tune_outlined),
                _buildTargetCard(ExportTarget.deletionRequests, 'Deletion Requests Audit', Icons.delete_sweep_outlined),
              ],
            ),
            const SizedBox(height: 24),

            // Format Selection
            const Text('2. Select File Format', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildFormatCard(ExportFormat.xlsx, 'Excel Spreadsheet (.xlsx)', Icons.table_chart_outlined, AppTheme.successColor),
                _buildFormatCard(ExportFormat.csv, 'CSV Data (.csv)', Icons.grid_on_outlined, AppTheme.accentColor),
                _buildFormatCard(ExportFormat.json, 'Raw JSON (.json)', Icons.code_outlined, AppTheme.primaryColor),
              ],
            ),
            const SizedBox(height: 24),

            // School Filter (for record datasets)
            if (_selectedTarget == ExportTarget.recordsAll ||
                _selectedTarget == ExportTarget.recordsWeekly ||
                _selectedTarget == ExportTarget.recordsTermly ||
                _selectedTarget == ExportTarget.recordsAnnually ||
                _selectedTarget == ExportTarget.recordsSpecial) ...[
              const Text('3. Institution Scope', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: DropdownButton<String>(
                  value: _selectedSchool,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('All Registered Institutions')),
                    ...schools.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                  ],
                  onChanged: (val) => setState(() => _selectedSchool = val ?? 'all'),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Download Trigger Button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isExporting ? null : _handleDownload,
                icon: _isExporting
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.download, size: 20),
                label: Text(
                  _isExporting ? 'Generating Dataset...' : 'Download Selected Dataset',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetCard(ExportTarget target, String title, IconData icon) {
    final isSelected = _selectedTarget == target;
    return InkWell(
      onTap: () => setState(() => _selectedTarget = target),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentColor.withOpacity(0.12) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.accentColor : Theme.of(context).dividerColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: isSelected ? AppTheme.accentColor : Colors.grey),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppTheme.accentColor : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatCard(ExportFormat format, String title, IconData icon, Color color) {
    final isSelected = _selectedFormat == format;
    return InkWell(
      onTap: () => setState(() => _selectedFormat = format),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Theme.of(context).dividerColor,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: isSelected ? color : Colors.grey),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
