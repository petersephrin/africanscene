import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_data_provider.dart';
import '../../models/form_field_model.dart';
import '../../theme/app_theme.dart';

class AdminFormFieldsPage extends StatefulWidget {
  const AdminFormFieldsPage({super.key});

  @override
  State<AdminFormFieldsPage> createState() => _AdminFormFieldsPageState();
}

class _AdminFormFieldsPageState extends State<AdminFormFieldsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<FormType> _types = [
    FormType.weekly,
    FormType.termly,
    FormType.annually,
    FormType.special,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _types.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  FormType get _activeType => _types[_tabController.index];

  void _showAddEditFieldDialog([FormFieldModel? existingField]) {
    final isEdit = existingField != null;
    final labelCtrl = TextEditingController(text: existingField?.label ?? '');
    final placeholderCtrl = TextEditingController(text: existingField?.placeholder ?? '');
    final optionsCtrl = TextEditingController(text: existingField?.options.join(', ') ?? '');
    final minCtrl = TextEditingController(text: existingField?.minValue?.toString() ?? '');
    final maxCtrl = TextEditingController(text: existingField?.maxValue?.toString() ?? '');
    CustomFieldType selectedType = existingField?.fieldType ?? CustomFieldType.text;
    bool isRequired = existingField?.required ?? false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEdit ? 'Edit Form Field' : 'Add Custom Field to ${_activeType.displayName} Form'),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(controller: labelCtrl, decoration: const InputDecoration(labelText: 'Field Label *', hintText: 'e.g. Student Attendance Headcount')),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<CustomFieldType>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'Field Input Type'),
                      items: CustomFieldType.values.map((t) {
                        return DropdownMenuItem(value: t, child: Text(t.displayName));
                      }).toList(),
                      onChanged: (val) => setDialogState(() => selectedType = val ?? CustomFieldType.text),
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: placeholderCtrl, decoration: const InputDecoration(labelText: 'Placeholder / Helper Text')),
                    const SizedBox(height: 10),
                    if (selectedType == CustomFieldType.select) ...[
                      TextField(
                        controller: optionsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Select Options (comma separated) *',
                          hintText: 'Ahead of Schedule, On Schedule, Delayed',
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (selectedType == CustomFieldType.number) ...[
                      Row(
                        children: [
                          Expanded(child: TextField(controller: minCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Min Value'))),
                          const SizedBox(width: 10),
                          Expanded(child: TextField(controller: maxCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max Value'))),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Mandatory Required Field', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      value: isRequired,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (val) => setDialogState(() => isRequired = val ?? false),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (labelCtrl.text.trim().isEmpty) return;

                  final adminData = context.read<AdminDataProvider>();
                  final options = optionsCtrl.text
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList();

                  if (isEdit) {
                    await adminData.updateFormField(existingField.id, {
                      'label': labelCtrl.text.trim(),
                      'field_type': selectedType.toDbString(),
                      'placeholder': placeholderCtrl.text.trim(),
                      'required': isRequired,
                      'options': options,
                      'min_value': num.tryParse(minCtrl.text),
                      'max_value': num.tryParse(maxCtrl.text),
                    });
                  } else {
                    final newField = FormFieldModel(
                      id: '',
                      formType: _activeType,
                      label: labelCtrl.text.trim(),
                      fieldType: selectedType,
                      placeholder: placeholderCtrl.text.trim(),
                      required: isRequired,
                      options: options,
                      fieldOrder: 0, // Auto-computed by firestoreService
                      minValue: num.tryParse(minCtrl.text),
                      maxValue: num.tryParse(maxCtrl.text),
                    );
                    await adminData.addFormField(newField);
                  }

                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(isEdit ? 'Field updated!' : 'Custom field added to ${_activeType.displayName} form!'), backgroundColor: AppTheme.successColor),
                    );
                  }
                },
                child: Text(isEdit ? 'Save Changes' : 'Add Field'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _moveField(List<FormFieldModel> fields, int currentIndex, int targetIndex) async {
    if (targetIndex < 0 || targetIndex >= fields.length) return;
    final item = fields.removeAt(currentIndex);
    fields.insert(targetIndex, item);
    final orderedIds = fields.map((f) => f.id).toList();

    await context.read<AdminDataProvider>().reorderFormFields(_activeType, orderedIds);
  }

  @override
  Widget build(BuildContext context) {
    final adminData = context.watch<AdminDataProvider>();

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: Theme.of(context).cardColor,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppTheme.primaryColor,
            indicatorColor: AppTheme.primaryColor,
            tabs: _types.map((t) => Tab(text: '${t.displayName} Form')).toList(),
            onTap: (_) => setState(() {}),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditFieldDialog(),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add Field to ${_activeType.displayName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Builder(builder: (context) {
        final fields = adminData.getFieldsByType(_activeType);

        if (fields.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.tune, size: 52, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('No fields configured for ${_activeType.displayName} forms yet.', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  const Text('Click the button below to define dynamic input fields for field researchers.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 88),
          itemCount: fields.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final f = fields[index];

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
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${f.fieldOrder}',
                        style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(f.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(width: 8),
                            if (f.required)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.dangerColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text('Required', style: TextStyle(color: AppTheme.dangerColor, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Type: ${f.fieldType.displayName}${f.options.isNotEmpty ? " • Options: ${f.options.join(", ")}" : ""}',
                          style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                        ),
                      ],
                    ),
                  ),
                  // Move Up / Move Down
                  IconButton(
                    icon: const Icon(Icons.arrow_upward, size: 18),
                    tooltip: 'Move Up',
                    onPressed: index > 0 ? () => _moveField(List.from(fields), index, index - 1) : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_downward, size: 18),
                    tooltip: 'Move Down',
                    onPressed: index < fields.length - 1 ? () => _moveField(List.from(fields), index, index + 1) : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    tooltip: 'Edit',
                    onPressed: () => _showAddEditFieldDialog(f),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.dangerColor),
                    tooltip: 'Delete',
                    onPressed: () async {
                      await adminData.deleteFormField(f.id, _activeType);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Field removed and remaining reindexed.')));
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
