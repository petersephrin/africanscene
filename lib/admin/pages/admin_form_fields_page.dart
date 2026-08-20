import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/admin_data_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/form_field_model.dart';
import '../../theme/app_theme.dart';

class AdminFormFieldsPage extends StatefulWidget {
  const AdminFormFieldsPage({super.key});

  @override
  State<AdminFormFieldsPage> createState() => _AdminFormFieldsPageState();
}

class _AdminFormFieldsPageState extends State<AdminFormFieldsPage> {
  FormType _activeTab = FormType.weekly;
  final List<FormType> _formTypes = [
    FormType.weekly,
    FormType.termly,
    FormType.annually,
    FormType.special,
  ];

  final List<CustomFieldType> _fieldTypes = [
    CustomFieldType.text,
    CustomFieldType.number,
    CustomFieldType.percentage,
    CustomFieldType.textarea,
    CustomFieldType.select,
    CustomFieldType.boolean,
  ];

  bool _reordering = false;

  // ==========================================
  // MOVE FIELD UP / DOWN
  // ==========================================
  Future<void> _moveField(List<FormFieldModel> fields, int index, String direction) async {
    if (_reordering) return;

    final newIndex = direction == 'up' ? index - 1 : index + 1;
    if (newIndex < 0 || newIndex >= fields.length) return;

    setState(() => _reordering = true);

    final updated = List<FormFieldModel>.from(fields);
    final temp = updated[index];
    updated[index] = updated[newIndex];
    updated[newIndex] = temp;

    final orderedIds = updated.map((f) => f.id).toList();
    await context.read<AdminDataProvider>().reorderFormFields(_activeTab, orderedIds);

    if (mounted) {
      setState(() => _reordering = false);
    }
  }

  // ==========================================
  // ADD / EDIT FORM FIELD MODAL
  // ==========================================
  void _showAddEditFieldDialog([FormFieldModel? existingField]) {
    final isEdit = existingField != null;
    final labelCtrl = TextEditingController(text: existingField?.label ?? '');
    final placeholderCtrl = TextEditingController(text: existingField?.placeholder ?? '');
    final optionsCtrl = TextEditingController(text: existingField?.options.join(', ') ?? '');
    final minCtrl = TextEditingController(text: existingField?.minValue?.toString() ?? '');
    final maxCtrl = TextEditingController(text: existingField?.maxValue?.toString() ?? '');
    CustomFieldType selectedType = existingField?.fieldType ?? CustomFieldType.text;
    bool isRequired = existingField?.required ?? false;

    final themeProvider = context.read<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isNumeric = selectedType == CustomFieldType.number || selectedType == CustomFieldType.percentage;

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Theme.of(context).cardColor,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEdit ? 'Edit Field' : 'Add Field',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_activeTab.displayName.toLowerCase()} form',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
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

                      const SizedBox(height: 16),
                      Divider(color: Theme.of(context).dividerColor),
                      const SizedBox(height: 16),

                      // Field Label
                      _buildFormField(
                        label: 'Field Label *',
                        controller: labelCtrl,
                        hint: 'e.g. Number of Students Present',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),

                      // Field Type Dropdown
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Field Type',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppTheme.textLight : AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.mutedDark : const Color(0xFFF7F5F3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? AppTheme.borderDark : const Color(0xFFEBE6E2),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<CustomFieldType>(
                                value: selectedType,
                                isExpanded: true,
                                icon: const Icon(Icons.arrow_drop_down_rounded),
                                dropdownColor: Theme.of(context).cardColor,
                                items: _fieldTypes.map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(
                                    t.toDbString(),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                    ),
                                  ),
                                )).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setDialogState(() => selectedType = val);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Placeholder Text
                      _buildFormField(
                        label: 'Placeholder text',
                        controller: placeholderCtrl,
                        hint: 'Optional helper text…',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),

                      // Options (if select)
                      if (selectedType == CustomFieldType.select) ...[
                        _buildFormField(
                          label: 'Options (comma-separated)',
                          controller: optionsCtrl,
                          hint: 'Option A, Option B, Option C',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Min & Max Values (if number / percentage)
                      if (isNumeric) ...[
                        Row(
                          children: [
                            Expanded(
                              child: _buildFormField(
                                label: 'Min value',
                                controller: minCtrl,
                                hint: selectedType == CustomFieldType.percentage ? '0' : 'e.g. 0',
                                keyboardType: TextInputType.number,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildFormField(
                                label: 'Max value',
                                controller: maxCtrl,
                                hint: selectedType == CustomFieldType.percentage ? '100' : 'e.g. 5',
                                keyboardType: TextInputType.number,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Required Checkbox
                      InkWell(
                        onTap: () => setDialogState(() => isRequired = !isRequired),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: isRequired,
                                  activeColor: AppTheme.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  onChanged: (val) => setDialogState(() => isRequired = val ?? false),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Required field',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Dialog Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(ctx),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: isDark ? AppTheme.borderDark : const Color(0xFFEBE6E2),
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                final label = labelCtrl.text.trim();
                                if (label.isEmpty) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter a field label.'),
                                      backgroundColor: AppTheme.dangerColor,
                                    ),
                                  );
                                  return;
                                }

                                final adminData = context.read<AdminDataProvider>();
                                final options = optionsCtrl.text
                                    .split(',')
                                    .map((e) => e.trim())
                                    .where((e) => e.isNotEmpty)
                                    .toList();
                                final minVal = num.tryParse(minCtrl.text.trim());
                                final maxVal = num.tryParse(maxCtrl.text.trim());

                                try {
                                  if (isEdit) {
                                    await adminData.updateFormField(existingField.id, {
                                      'label': label,
                                      'field_type': selectedType.toDbString(),
                                      'placeholder': placeholderCtrl.text.trim(),
                                      'required': isRequired,
                                      'options': options,
                                      'min_value': minVal,
                                      'max_value': maxVal,
                                    });
                                  } else {
                                    final currentFields = adminData.getFieldsByType(_activeTab);
                                    final newField = FormFieldModel(
                                      id: '',
                                      formType: _activeTab,
                                      label: label,
                                      fieldType: selectedType,
                                      placeholder: placeholderCtrl.text.trim(),
                                      required: isRequired,
                                      options: options,
                                      fieldOrder: currentFields.length + 1,
                                      minValue: minVal,
                                      maxValue: maxVal,
                                    );
                                    await adminData.addFormField(newField);
                                  }

                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                  }
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(isEdit
                                          ? 'Field updated successfully!'
                                          : 'Custom field added to ${_activeTab.displayName} form!'),
                                      backgroundColor: AppTheme.successColor,
                                    ),
                                  );
                                } catch (e) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: AppTheme.dangerColor,
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                isEdit ? 'Update' : 'Add Field',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.textLight : AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.mutedDark : const Color(0xFFF7F5F3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppTheme.borderDark : const Color(0xFFEBE6E2),
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTheme.textLight : AppTheme.textDark,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // DELETE CONFIRMATION DIALOG
  // ==========================================
  void _showDeleteConfirmation(FormFieldModel field) {
    final themeProvider = context.read<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        backgroundColor: Theme.of(context).cardColor,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.dangerColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline_rounded, color: AppTheme.dangerColor, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              'Delete Form Field?',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${field.label}" from ${_activeTab.displayName} records?',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await context.read<AdminDataProvider>().deleteFormField(field.id, _activeTab);
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              messenger.showSnackBar(
                SnackBar(
                  content: Text('${field.label} removed.'),
                  backgroundColor: AppTheme.dangerColor,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
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
    final fields = adminData.getFieldsByType(_activeTab);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Section: Title, Subtitle, Online Badge, and "Add Field" Button
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 620;
                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Form Fields',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.textLight : AppTheme.textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manage fields for each record type',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Online Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF38251E) : const Color(0xFFFDEEE7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.wifi_rounded, size: 13, color: AppTheme.primaryColor),
                                SizedBox(width: 5),
                                Text(
                                  'Online',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Add Field Button
                          ElevatedButton.icon(
                            onPressed: () => _showAddEditFieldDialog(),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text(
                              'Add Field',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
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
                            'Form Fields',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppTheme.textLight : AppTheme.textDark,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Manage fields for each record type',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Online Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF38251E) : const Color(0xFFFDEEE7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.wifi_rounded, size: 13, color: AppTheme.primaryColor),
                              SizedBox(width: 5),
                              Text(
                                'Online',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Add Field Button
                        ElevatedButton.icon(
                          onPressed: () => _showAddEditFieldDialog(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text(
                            'Add Field',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // 2. Tabs Segmented Control
            Align(
              alignment: Alignment.centerLeft,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.mutedDark : const Color(0xFFF0ECE9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: _formTypes.map((type) {
                      final isActive = _activeTab == type;
                      final count = adminData.getFieldsByType(type).length;

                      return InkWell(
                        onTap: () => setState(() => _activeTab = type),
                        borderRadius: BorderRadius.circular(8),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isActive ? Theme.of(context).cardColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 1),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                type.displayName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                                  color: isActive
                                      ? (isDark ? AppTheme.textLight : AppTheme.textDark)
                                      : (isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? (isDark ? const Color(0xFF38251E) : const Color(0xFFFDEEE7))
                                      : (isDark ? const Color(0xFF231E1B) : const Color(0xFFE8E2DE)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isActive
                                        ? AppTheme.primaryColor
                                        : (isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 3. Form Fields List
            if (fields.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 64),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppTheme.borderDark : const Color(0xFFEBE6E2),
                  ),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 44,
                      color: (isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight)
                          .withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No fields for ${_activeTab.displayName.toLowerCase()} records',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Click "Add Field" to create the first one',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                      ),
                    ),
                  ],
                ),
              )
            else
              Column(
                children: fields.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final f = entry.value;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppTheme.borderDark : const Color(0xFFEBE6E2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Up/Down Chevron Reorder Buttons
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 24, minHeight: 18),
                              icon: Icon(
                                Icons.keyboard_arrow_up_rounded,
                                size: 18,
                                color: (idx == 0 || _reordering)
                                    ? (isDark ? AppTheme.borderDark : const Color(0xFFE0DBD7))
                                    : (isDark ? AppTheme.textMutedDark : const Color(0xFF85746E)),
                              ),
                              tooltip: 'Move up',
                              onPressed: (idx == 0 || _reordering) ? null : () => _moveField(fields, idx, 'up'),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 24, minHeight: 18),
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: (idx == fields.length - 1 || _reordering)
                                    ? (isDark ? AppTheme.borderDark : const Color(0xFFE0DBD7))
                                    : (isDark ? AppTheme.textMutedDark : const Color(0xFF85746E)),
                              ),
                              tooltip: 'Move down',
                              onPressed: (idx == fields.length - 1 || _reordering) ? null : () => _moveField(fields, idx, 'down'),
                            ),
                          ],
                        ),

                        const SizedBox(width: 12),

                        // Field Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    f.label,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                    ),
                                  ),
                                  if (f.required) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'Required',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFDC2626),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 5),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  // Field Type Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF3B332E) : const Color(0xFFF3ECE6),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      f.fieldType.toDbString(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                      ),
                                    ),
                                  ),

                                  // Min / Max Badge
                                  if (f.minValue != null || f.maxValue != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF38251E) : const Color(0xFFFDEEE7),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${f.minValue != null ? "min ${f.minValue}" : ""}${f.minValue != null && f.maxValue != null ? " · " : ""}${f.maxValue != null ? "max ${f.maxValue}" : ""}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ),

                                  // Placeholder
                                  if (f.placeholder?.isNotEmpty == true)
                                    Text(
                                      '"${f.placeholder}"',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontStyle: FontStyle.italic,
                                        color: isDark ? AppTheme.textMutedDark : const Color(0xFF85746E),
                                      ),
                                    ),

                                  // Options
                                  if (f.options.isNotEmpty)
                                    Text(
                                      f.options.join(', '),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? AppTheme.textMutedDark : const Color(0xFF85746E),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Order Number (#1, #2, etc.)
                        Text(
                          '#${f.fieldOrder}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppTheme.textMutedDark : const Color(0xFF85746E),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Action Buttons: Edit & Delete
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          icon: Icon(
                            Icons.edit_outlined,
                            size: 17,
                            color: isDark ? AppTheme.textMutedDark : const Color(0xFF85746E),
                          ),
                          tooltip: 'Edit',
                          onPressed: () => _showAddEditFieldDialog(f),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 17,
                            color: Color(0xFFDC2626),
                          ),
                          tooltip: 'Delete',
                          onPressed: () => _showDeleteConfirmation(f),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
