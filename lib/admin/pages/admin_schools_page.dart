import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/admin_data_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/school_model.dart';
import '../../theme/app_theme.dart';

class AdminSchoolsPage extends StatefulWidget {
  const AdminSchoolsPage({super.key});

  @override
  State<AdminSchoolsPage> createState() => _AdminSchoolsPageState();
}

class _AdminSchoolsPageState extends State<AdminSchoolsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSchoolDetailsDialog(SchoolModel school) {
    final themeProvider = context.read<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).cardColor,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF38251E) : const Color(0xFFFDEEE7),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        school.name.trim().isNotEmpty ? school.name.trim()[0].toUpperCase() : 'S',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            school.name,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppTheme.textLight : AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                school.location,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                Divider(color: Theme.of(context).dividerColor),
                const SizedBox(height: 16),

                // Key Info Chips
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildDetailChip(
                      icon: Icons.school_outlined,
                      label: 'Type',
                      value: school.type,
                      isDark: isDark,
                    ),
                    _buildDetailChip(
                      icon: Icons.people_outline_rounded,
                      label: 'Students',
                      value: '${school.students} Registered',
                      isDark: isDark,
                    ),
                    if (school.established > 0)
                      _buildDetailChip(
                        icon: Icons.calendar_today_outlined,
                        label: 'Established',
                        value: '${school.established}',
                        isDark: isDark,
                      ),
                    if (school.principal != null && school.principal!.isNotEmpty)
                      _buildDetailChip(
                        icon: Icons.person_outline_rounded,
                        label: 'Principal',
                        value: school.principal!,
                        isDark: isDark,
                      ),
                    if (school.phone != null && school.phone!.isNotEmpty)
                      _buildDetailChip(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: school.phone!,
                        isDark: isDark,
                      ),
                    if (school.email != null && school.email!.isNotEmpty)
                      _buildDetailChip(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: school.email!,
                        isDark: isDark,
                      ),
                  ],
                ),

                if (school.motto != null && school.motto!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2D2420) : const Color(0xFFFAF5F0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? AppTheme.borderDark : const Color(0xFFEBE6E2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.format_quote_rounded, size: 18, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            school.motto!,
                            style: TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: isDark ? AppTheme.textLight : AppTheme.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (school.description != null && school.description!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'About Institution',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.textLight : AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    school.description!,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showDeleteConfirmation(school);
                      },
                      icon: const Icon(Icons.delete_outline_rounded, size: 16, color: AppTheme.dangerColor),
                      label: const Text('Delete', style: TextStyle(color: AppTheme.dangerColor)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.dangerColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showAddEditSchoolDialog(school);
                      },
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit School'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
  }

  Widget _buildDetailChip({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.mutedDark : const Color(0xFFF7F5F3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppTheme.borderDark : const Color(0xFFEBE6E2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.textLight : AppTheme.textDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddEditSchoolDialog([SchoolModel? existingSchool]) {
    final isEdit = existingSchool != null;
    final nameCtrl = TextEditingController(text: existingSchool?.name ?? '');
    final locCtrl = TextEditingController(text: existingSchool?.location ?? '');
    final studentsCtrl = TextEditingController(text: existingSchool != null ? '${existingSchool.students}' : '');
    final mottoCtrl = TextEditingController(text: existingSchool?.motto ?? '');
    final principalCtrl = TextEditingController(text: existingSchool?.principal ?? '');
    final phoneCtrl = TextEditingController(text: existingSchool?.phone ?? '');
    final emailCtrl = TextEditingController(text: existingSchool?.email ?? '');
    final estCtrl = TextEditingController(text: existingSchool?.established.toString() ?? '${DateTime.now().year}');
    final descCtrl = TextEditingController(text: existingSchool?.description ?? '');

    String selectedType = existingSchool?.type ?? 'Secondary';
    final schoolTypes = ['Secondary', 'Primary & Secondary', 'Primary', 'TVET / College', 'International School'];
    if (!schoolTypes.contains(selectedType)) {
      schoolTypes.add(selectedType);
    }

    final themeProvider = context.read<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Theme.of(context).cardColor,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
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
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF38251E) : const Color(0xFFFDEEE7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.school_outlined,
                                color: AppTheme.primaryColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEdit ? 'Edit School Institution' : 'Register New School',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isEdit ? 'Update school information and details' : 'Enter details to add a new learning institution',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                  ),
                                ),
                              ],
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

                    const SizedBox(height: 20),
                    Divider(color: Theme.of(context).dividerColor),
                    const SizedBox(height: 16),

                    // School Name
                    _buildFormField(
                      label: 'School Name *',
                      controller: nameCtrl,
                      hint: 'e.g. Alliance High School',
                      icon: Icons.business_outlined,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 14),

                    // Location & Type Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            label: 'Location (City, Country) *',
                            controller: locCtrl,
                            hint: 'e.g. Kikuyu, Kenya',
                            icon: Icons.location_on_outlined,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'School Type *',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  color: isDark ? AppTheme.mutedDark : const Color(0xFFF7F5F3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isDark ? AppTheme.borderDark : const Color(0xFFEBE6E2),
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: selectedType,
                                    isExpanded: true,
                                    icon: const Icon(Icons.arrow_drop_down_rounded),
                                    dropdownColor: Theme.of(context).cardColor,
                                    items: schoolTypes.map((t) => DropdownMenuItem(
                                      value: t,
                                      child: Text(t, style: const TextStyle(fontSize: 13)),
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
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Students Count & Established Year
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            label: 'Student Count',
                            controller: studentsCtrl,
                            hint: 'e.g. 1450',
                            icon: Icons.people_outline_rounded,
                            keyboardType: TextInputType.number,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildFormField(
                            label: 'Established Year',
                            controller: estCtrl,
                            hint: 'e.g. 1926',
                            icon: Icons.calendar_today_outlined,
                            keyboardType: TextInputType.number,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Principal / Headteacher
                    _buildFormField(
                      label: 'Principal / Headteacher',
                      controller: principalCtrl,
                      hint: 'e.g. Dr. David Mwangi',
                      icon: Icons.person_outline_rounded,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 14),

                    // Phone & Email Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildFormField(
                            label: 'Phone Number',
                            controller: phoneCtrl,
                            hint: 'e.g. +254 722 100 200',
                            icon: Icons.phone_outlined,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildFormField(
                            label: 'Email Address',
                            controller: emailCtrl,
                            hint: 'e.g. info@alliancehigh.ac.ke',
                            icon: Icons.email_outlined,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Motto
                    _buildFormField(
                      label: 'Motto / Slogan',
                      controller: mottoCtrl,
                      hint: 'e.g. Strong to Serve',
                      icon: Icons.format_quote_rounded,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 14),

                    // Description / Notes
                    _buildFormField(
                      label: 'Description / Notes',
                      controller: descCtrl,
                      hint: 'Brief description about the school, curriculum, or background...',
                      icon: Icons.notes_rounded,
                      maxLines: 3,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 24),

                    // Dialog Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: isDark ? AppTheme.borderDark : const Color(0xFFEBE6E2),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: isDark ? AppTheme.textLight : AppTheme.textDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            if (nameCtrl.text.trim().isEmpty) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Please provide a school name.'),
                                  backgroundColor: AppTheme.dangerColor,
                                ),
                              );
                              return;
                            }

                            final adminData = context.read<AdminDataProvider>();
                            final studentCount = int.tryParse(studentsCtrl.text.trim()) ?? 0;
                            final estYear = int.tryParse(estCtrl.text.trim()) ?? DateTime.now().year;

                            if (isEdit) {
                              await adminData.updateSchool(existingSchool.id, {
                                'name': nameCtrl.text.trim(),
                                'location': locCtrl.text.trim(),
                                'type': selectedType,
                                'students': studentCount,
                                'motto': mottoCtrl.text.trim(),
                                'principal': principalCtrl.text.trim(),
                                'phone': phoneCtrl.text.trim(),
                                'email': emailCtrl.text.trim(),
                                'established': estYear,
                                'description': descCtrl.text.trim(),
                              });
                            } else {
                              final newSchool = SchoolModel(
                                id: '',
                                name: nameCtrl.text.trim(),
                                location: locCtrl.text.trim(),
                                type: selectedType,
                                students: studentCount,
                                motto: mottoCtrl.text.trim(),
                                principal: principalCtrl.text.trim(),
                                phone: phoneCtrl.text.trim(),
                                email: emailCtrl.text.trim(),
                                established: estYear,
                                description: descCtrl.text.trim(),
                              );
                              await adminData.addSchool(newSchool);
                            }

                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                            }
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(isEdit ? 'School updated successfully!' : 'School registered successfully!'),
                                backgroundColor: AppTheme.successColor,
                              ),
                            );
                          },
                          icon: Icon(isEdit ? Icons.check_rounded : Icons.add_rounded, size: 18),
                          label: Text(isEdit ? 'Save Changes' : 'Register School'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
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
            maxLines: maxLines,
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
              prefixIcon: Icon(icon, size: 18, color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: maxLines > 1 ? 12 : 10),
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(SchoolModel school) {
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
              'Delete School?',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${school.name}"? This action will remove its data from the directory.',
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
              await context.read<AdminDataProvider>().deleteSchool(school.id);
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              messenger.showSnackBar(
                SnackBar(
                  content: Text('${school.name} deleted.'),
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

  @override
  Widget build(BuildContext context) {
    final adminData = context.watch<AdminDataProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final schools = adminData.schools;

    final filtered = schools.where((s) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase().trim();
      final matchesQuery = s.name.toLowerCase().contains(q) ||
          s.location.toLowerCase().contains(q) ||
          s.type.toLowerCase().contains(q) ||
          (s.principal?.toLowerCase().contains(q) ?? false);
      return matchesQuery;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Section: Title, Subtitle, and "+ Add School" Button
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 620;
                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Schools',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.textLight : AppTheme.textDark,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${schools.length} school${schools.length == 1 ? '' : 's'} registered',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showAddEditSchoolDialog(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text(
                          'Add School',
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
                            'Schools',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppTheme.textLight : AppTheme.textDark,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${schools.length} school${schools.length == 1 ? '' : 's'} registered',
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
                      onPressed: () => _showAddEditSchoolDialog(),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(
                        'Add School',
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
                );
              },
            ),

            const SizedBox(height: 20),

            // 2. Search Bar
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF231E1B) : const Color(0xFFF7F5F3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppTheme.borderDark : const Color(0xFFEBE6E2),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: isDark ? AppTheme.textMutedDark : const Color(0xFF85746E),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppTheme.textLight : AppTheme.textDark,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search schools by name or location...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppTheme.textMutedDark : const Color(0xFF85746E),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      color: isDark ? AppTheme.textMutedDark : const Color(0xFF85746E),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. Schools Grid / Cards Section
            if (filtered.isEmpty)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 60),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.mutedDark : const Color(0xFFF7F5F3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.school_outlined,
                        size: 40,
                        color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'No schools matching "$_searchQuery"'
                          : 'No schools registered yet',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppTheme.textLight : AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _searchQuery.isNotEmpty
                          ? 'Try adjusting your search keywords'
                          : 'Click "+ Add School" to register your first institution',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                      ),
                    ),
                    if (_searchQuery.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: const Text('Clear Search'),
                      ),
                    ],
                  ],
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  int columns = 1;
                  if (width >= 1050) {
                    columns = 3;
                  } else if (width >= 650) {
                    columns = 2;
                  }

                  const double spacing = 16.0;
                  final double cardWidth = (width - (spacing * (columns - 1))) / columns;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: filtered.map((school) {
                      return SizedBox(
                        width: cardWidth,
                        child: _buildSchoolCard(school, isDark),
                      );
                    }).toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchoolCard(SchoolModel school, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showSchoolDetailsDialog(school),
        borderRadius: BorderRadius.circular(16),
        child: Container(
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Row: Initial Avatar & Action Buttons (Edit / Delete)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Initial Avatar Circle
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF38251E) : const Color(0xFFFDEEE7),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      school.name.trim().isNotEmpty ? school.name.trim()[0].toUpperCase() : 'S',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),

                  // Action Buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: isDark ? AppTheme.textMutedDark : const Color(0xFF85746E),
                        ),
                        tooltip: 'Edit School',
                        onPressed: () => _showAddEditSchoolDialog(school),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: Color(0xFFDC2626),
                        ),
                        tooltip: 'Delete School',
                        onPressed: () => _showDeleteConfirmation(school),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // School Name
              Text(
                school.name,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppTheme.textLight : AppTheme.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 6),

              // Location Row with Pin Icon
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 15,
                    color: isDark ? AppTheme.textMutedDark : const Color(0xFF85746E),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      school.location,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppTheme.textMutedDark : const Color(0xFF85746E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Bottom Row: Type Tag & Student Count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Type Tag Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF382922) : const Color(0xFFF7EBE4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      school.type,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),

                  // Student Count
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people_outline_rounded,
                        size: 16,
                        color: isDark ? AppTheme.textMutedDark : const Color(0xFF85746E),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${school.students}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppTheme.textMutedDark : const Color(0xFF85746E),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
