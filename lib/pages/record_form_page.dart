import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';
import '../providers/school_provider.dart';
import '../models/user_model.dart';
import '../models/school_model.dart';
import '../models/form_field_model.dart';
import '../models/record_model.dart';
import '../models/deletion_request_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../components/record_preview_modal.dart';

class RecordFormPage extends StatefulWidget {
  final FormType initialFormType;

  const RecordFormPage({
    super.key,
    this.initialFormType = FormType.weekly,
  });

  @override
  State<RecordFormPage> createState() => _RecordFormPageState();
}

class _RecordFormPageState extends State<RecordFormPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();

  late FormType _currentFormType;
  bool _isFormView = false;
  bool _isSaving = false;

  RecordModel? _editingRecord;
  final _editReasonController = TextEditingController();
  final Map<String, dynamic> _formValues = {};

  @override
  void initState() {
    super.initState();
    _currentFormType = widget.initialFormType;
  }

  @override
  void dispose() {
    _editReasonController.dispose();
    super.dispose();
  }

  void _startAddRecord() {
    final fields = context.read<SchoolProvider>().getFieldsByType(_currentFormType);
    _formValues.clear();
    for (var f in fields) {
      _formValues[f.label] = f.fieldType == CustomFieldType.boolean ? false : '';
    }
    setState(() {
      _editingRecord = null;
      _editReasonController.clear();
      _isFormView = true;
    });
  }

  void _startEditRecord(RecordModel record) {
    final fields = context.read<SchoolProvider>().getFieldsByType(_currentFormType);
    _formValues.clear();
    for (var f in fields) {
      _formValues[f.label] = record.data[f.label] ?? (f.fieldType == CustomFieldType.boolean ? false : '');
    }
    setState(() {
      _editingRecord = record;
      _editReasonController.clear();
      _isFormView = true;
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final auth = context.read<AuthProvider>();
    final school = context.read<SchoolProvider>();
    final user = auth.user;
    final activeSchool = school.activeSchool;

    if (user == null || activeSchool == null) return;

    if (_editingRecord != null && _editReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a reason for this edit.'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final fields = school.getFieldsByType(_currentFormType);
      final fieldsSnapshot = fields.map((f) => f.toMap()).toList();

      final now = DateTime.now();
      final timeStr = DateFormat('h:mm a').format(now);
      final completeData = {
        ..._formValues,
        'submittedBy': user.name,
        'time': timeStr,
      };

      if (_editingRecord != null) {
        final version = RecordVersionModel(
          id: '',
          recordId: _editingRecord!.id,
          schoolId: activeSchool.id,
          formType: _currentFormType,
          versionNumber: _editingRecord!.versionNumber,
          data: _editingRecord!.data,
          editedBy: user.name,
          editReason: _editReasonController.text.trim(),
          createdAt: DateTime.now(),
        );

        final updatedRecord = _editingRecord!.copyWith(
          data: completeData,
          versionNumber: _editingRecord!.versionNumber + 1,
          updatedAt: DateTime.now(),
          formFieldsSnapshot: fieldsSnapshot,
        );

        await school.updateRecord(updatedRecord, version);
      } else {
        await school.addRecord(
          formType: _currentFormType,
          data: completeData,
          user: user,
        );
      }

      if (mounted) {
        setState(() {
          _isFormView = false;
          _editingRecord = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              school.isOnline
                  ? 'Record saved and synced to database!'
                  : 'Record saved locally — will sync when online.',
            ),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving record: $e'),
            backgroundColor: AppTheme.dangerColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showDeletionModal(RecordModel record) {
    final reasonCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Record Deletion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Field researchers can request deletions for records. An administrator will review your request.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Reason for deletion *',
                hintText: 'e.g. Duplicate entry submitted by mistake',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            onPressed: () async {
              final reason = reasonCtrl.text.trim();
              if (reason.isEmpty) return;

              final user = context.read<AuthProvider>().user;
              if (user != null) {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(ctx);

                final req = DeletionRequestModel(
                  id: '',
                  recordId: record.id,
                  requestedBy: user.id,
                  requesterName: user.name,
                  reason: reason,
                );
                await _firestoreService.createDeletionRequest(req);
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Deletion request submitted for administrative review.'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            },
            child: const Text('Submit Request'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final school = context.watch<SchoolProvider>();
    final user = auth.user;
    final activeSchool = school.activeSchool;
    final currentFields = school.getFieldsByType(_currentFormType);
    final allRecords = school.getRecordsByType(_currentFormType);

    final drift = school.recordTypeChanges.where((c) => c.formType == _currentFormType).firstOrNull;
    final now = DateTime.now();
    final dateStr = DateFormat('EEE, d MMM yyyy').format(now);
    final timeStr = DateFormat('h:mm a').format(now);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Hero Header with Curved Bottom
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                    // Back button / Category Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: () {
                            if (_isFormView) {
                              setState(() {
                                _isFormView = false;
                                _editingRecord = null;
                              });
                            } else {
                              // Cycle record types
                              final types = FormType.values;
                              final nextIdx = (types.indexOf(_currentFormType) + 1) % types.length;
                              setState(() => _currentFormType = types[nextIdx]);
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.arrow_back, size: 16, color: Colors.white70),
                                const SizedBox(width: 6),
                                Text(
                                  _isFormView ? 'Back to list' : 'Switch Category',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Form Type Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _currentFormType.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Text(
                      _isFormView
                          ? (_editingRecord != null ? 'Edit ${_currentFormType.displayName} Record' : 'New ${_currentFormType.displayName} Record')
                          : '${_currentFormType.displayName} Records',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activeSchool?.name ?? 'Assigned School',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Schema Drift Alert Banner (if any)
          if (drift != null) ...[
            const SizedBox(height: 14),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 512),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.dangerColor.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: AppTheme.dangerColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              '${_currentFormType.displayName} record fields have changed',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppTheme.dangerColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Administrative template updates were made. Please inspect your records to ensure data integrity.',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.dangerColor.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.dangerColor,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              onPressed: () => school.acknowledgeRecordTypeChange(_currentFormType),
                              child: const Text('Dismiss Warning', style: TextStyle(fontSize: 11)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],

          // 3. Main Content (List View vs Form View)
          const SizedBox(height: 16),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 512),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _isFormView ? _buildFormView(user, activeSchool, currentFields, dateStr, timeStr) : _buildListView(allRecords),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<RecordModel> records) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // + Add Record Button (btn-primary)
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: _startAddRecord,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            child: Text(
              '+ Add ${_currentFormType.displayName} Record',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 18),

        if (records.isEmpty)
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
                  Icon(Icons.assignment_outlined, size: 40, color: Colors.grey.withValues(alpha: 0.4)),
                  const SizedBox(height: 10),
                  Text(
                    'No ${_currentFormType.displayName.toLowerCase()} records yet',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap the button above to log your first entry.',
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
            itemCount: records.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final rec = records[index];
              final isSynced = rec.synced;
              final dateFormatted = rec.createdAt != null
                  ? DateFormat('d MMM yyyy').format(rec.createdAt!)
                  : '';
              final timeSub = rec.data['time'] ?? '';
              final submitter = rec.submittedBy;

              return InkWell(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => RecordPreviewModal(
                      record: rec,
                      onEdit: () => _startEditRecord(rec),
                      onDeleteRequest: () => _showDeletionModal(rec),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isSynced ? AppTheme.primaryColor : AppTheme.dangerColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateFormatted,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${timeSub.isNotEmpty ? "$timeSub · " : ""}$submitter',
                              style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.remove_red_eye_outlined, size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildFormView(UserModel? user, SchoolModel? activeSchool, List<FormFieldModel> fields, String dateStr, String timeStr) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Edit Reason Header if editing
          if (_editingRecord != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Editing existing record',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Reason for edit *',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _editReasonController,
                    decoration: const InputDecoration(
                      hintText: 'Why are you editing this record?',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Edit reason is required' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Auto-filled Information Card (bg-primary/5 border border-primary/15 rounded-2xl)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Auto-filled Information',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor),
                ),
                const SizedBox(height: 10),
                _buildAutoInfoRow('Name', user?.name ?? 'User'),
                const SizedBox(height: 6),
                _buildAutoInfoRow('School', activeSchool?.name ?? 'School'),
                const SizedBox(height: 6),
                _buildAutoInfoRow('Date', dateStr),
                const SizedBox(height: 6),
                _buildAutoInfoRow('Time', timeStr),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Numbered Dynamic Input Fields
          if (fields.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: const Center(
                child: Text('No dynamic fields configured for this form type by administrator yet.'),
              ),
            )
          else
            ...fields.asMap().entries.map((entry) {
              final idx = entry.key;
              final field = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildDynamicFieldWidget(idx + 1, field),
              );
            }),

          const SizedBox(height: 12),

          // Save / Submit Button (w-full btn-primary)
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _handleSave,
              icon: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save_outlined, size: 18),
              label: Text(
                _isSaving ? 'Saving Record...' : (_editingRecord != null ? 'Save Changes' : 'Save Record'),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAutoInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildDynamicFieldWidget(int number, FormFieldModel field) {
    final initialVal = _formValues[field.label]?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            children: [
              TextSpan(text: '$number. ${field.label}'),
              if (field.required)
                const TextSpan(text: ' *', style: TextStyle(color: AppTheme.dangerColor)),
            ],
          ),
        ),
        const SizedBox(height: 6),

        if (field.fieldType == CustomFieldType.select) ...[
          DropdownButtonFormField<String>(
            initialValue: field.options.contains(initialVal) ? initialVal : null,
            decoration: InputDecoration(
              hintText: field.placeholder ?? 'Select an option',
            ),
            items: field.options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
            validator: (v) => field.required && (v == null || v.isEmpty) ? 'Please select an option' : null,
            onChanged: (val) => _formValues[field.label] = val,
            onSaved: (val) => _formValues[field.label] = val ?? '',
          ),
        ] else if (field.fieldType == CustomFieldType.boolean) ...[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(field.placeholder ?? 'Enable / Disable', style: const TextStyle(fontSize: 12)),
            value: _formValues[field.label] == true,
            activeThumbColor: AppTheme.primaryColor,
            onChanged: (val) => setState(() => _formValues[field.label] = val),
          ),
        ] else if (field.fieldType == CustomFieldType.textarea) ...[
          TextFormField(
            initialValue: initialVal,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: field.placeholder ?? 'Enter notes...',
            ),
            validator: (v) => field.required && (v == null || v.trim().isEmpty) ? 'This field is required' : null,
            onSaved: (val) => _formValues[field.label] = val?.trim() ?? '',
          ),
        ] else ...[
          TextFormField(
            initialValue: initialVal,
            keyboardType: (field.fieldType == CustomFieldType.number || field.fieldType == CustomFieldType.percentage)
                ? TextInputType.number
                : TextInputType.text,
            decoration: InputDecoration(
              hintText: field.placeholder ?? (field.fieldType == CustomFieldType.percentage ? 'e.g. 85' : 'Enter value'),
              suffixText: field.fieldType == CustomFieldType.percentage ? '%' : null,
            ),
            validator: (v) {
              if (field.required && (v == null || v.trim().isEmpty)) return 'This field is required';
              if (field.fieldType == CustomFieldType.number || field.fieldType == CustomFieldType.percentage) {
                if (v != null && v.isNotEmpty) {
                  final n = num.tryParse(v);
                  if (n == null) return 'Please enter a valid number';
                  if (field.minValue != null && n < field.minValue!) return 'Must be >= ${field.minValue}';
                  if (field.maxValue != null && n > field.maxValue!) return 'Must be <= ${field.maxValue}';
                }
              }
              return null;
            },
            onSaved: (val) => _formValues[field.label] = val?.trim() ?? '',
          ),
        ],
      ],
    );
  }
}
