import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_data_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

class AdminTeachersPage extends StatefulWidget {
  const AdminTeachersPage({super.key});

  @override
  State<AdminTeachersPage> createState() => _AdminTeachersPageState();
}

class _AdminTeachersPageState extends State<AdminTeachersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatJoinedDate(DateTime? date) {
    if (date == null) return '—';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // ==========================================
  // VIEW TEACHER DETAILS MODAL
  // ==========================================
  void _showViewTeacherDialog(UserModel teacher) {
    final themeProvider = context.read<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final schools = context.read<AdminDataProvider>().schools;

    final assignedSchools = schools
        .where((s) => teacher.schoolIds.contains(s.id))
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).cardColor,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
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
                    Text(
                      'Teacher Details',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.textLight : AppTheme.textDark,
                      ),
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

                // Details Content
                _buildDetailRow(
                  label: 'Name',
                  value: teacher.name.isNotEmpty
                      ? teacher.name
                      : '${teacher.firstName} ${teacher.lastName}'.trim(),
                  isDark: isDark,
                ),
                const SizedBox(height: 14),

                _buildDetailRow(
                  label: 'Email',
                  value: teacher.email,
                  isDark: isDark,
                ),
                const SizedBox(height: 14),

                _buildDetailRow(
                  label: 'Phone',
                  value: teacher.phone?.isNotEmpty == true ? teacher.phone! : '—',
                  isDark: isDark,
                ),
                const SizedBox(height: 14),

                _buildDetailRow(
                  label: 'Subject / Specialization',
                  value: teacher.specialization?.isNotEmpty == true ? teacher.specialization! : '—',
                  isDark: isDark,
                ),
                const SizedBox(height: 14),

                _buildDetailRow(
                  label: 'Joined',
                  value: _formatJoinedDate(teacher.createdAt),
                  isDark: isDark,
                ),
                const SizedBox(height: 14),

                // Assigned Schools
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assigned Schools',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (assignedSchools.isEmpty)
                      Text(
                        'None',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                        ),
                      )
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: assignedSchools.map((s) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark ? AppTheme.secondaryDark : AppTheme.secondaryLight,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              s.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppTheme.textLight : AppTheme.textDark,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showAddEditTeacherDialog(teacher);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(width: 10),
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
                          'Close',
                          style: TextStyle(
                            color: isDark ? AppTheme.textLight : AppTheme.textDark,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
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
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? AppTheme.textLight : AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // ADD / EDIT TEACHER MODAL
  // ==========================================
  void _showAddEditTeacherDialog([UserModel? existingTeacher]) {
    final isEdit = existingTeacher != null;
    final nameCtrl = TextEditingController(text: existingTeacher?.name ?? '');
    final emailCtrl = TextEditingController(text: existingTeacher?.email ?? '');
    final specCtrl = TextEditingController(text: existingTeacher?.specialization ?? '');
    final phoneCtrl = TextEditingController(text: existingTeacher?.phone ?? '');
    final passCtrl = TextEditingController(text: isEdit ? '' : 'Password123!');
    final selectedSchoolIds = List<String>.from(existingTeacher?.schoolIds ?? []);

    final themeProvider = context.read<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final schools = context.read<AdminDataProvider>().schools;

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
                          Text(
                            isEdit ? 'Edit Teacher' : 'Add Teacher',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppTheme.textLight : AppTheme.textDark,
                            ),
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

                      // Full Name
                      _buildFormField(
                        label: 'Full Name',
                        controller: nameCtrl,
                        hint: 'e.g. Jane Mwangi',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),

                      // Email
                      if (!isEdit) ...[
                        _buildFormField(
                          label: 'Email',
                          controller: emailCtrl,
                          hint: 'e.g. teacher@africanscene.org',
                          keyboardType: TextInputType.emailAddress,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Subject / Specialization
                      _buildFormField(
                        label: 'Subject / Specialization',
                        controller: specCtrl,
                        hint: 'e.g. Primary Mathematics',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),

                      // Phone
                      _buildFormField(
                        label: 'Phone',
                        controller: phoneCtrl,
                        hint: 'e.g. +254 712 345 678',
                        keyboardType: TextInputType.phone,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),

                      // Password (if Add)
                      if (!isEdit) ...[
                        _buildFormField(
                          label: 'Initial Password',
                          controller: passCtrl,
                          hint: 'Min 6 characters',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Assigned Schools Checkboxes
                      Text(
                        'Assigned Schools',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppTheme.textLight : AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        constraints: const BoxConstraints(maxHeight: 160),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.mutedDark : const Color(0xFFF7F5F3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? AppTheme.borderDark : const Color(0xFFEBE6E2),
                          ),
                        ),
                        child: schools.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'No schools registered yet',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                itemCount: schools.length,
                                itemBuilder: (context, index) {
                                  final s = schools[index];
                                  final isChecked = selectedSchoolIds.contains(s.id);
                                  return InkWell(
                                    onTap: () {
                                      setDialogState(() {
                                        if (isChecked) {
                                          selectedSchoolIds.remove(s.id);
                                        } else {
                                          selectedSchoolIds.add(s.id);
                                        }
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      child: Row(
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: Checkbox(
                                              value: isChecked,
                                              activeColor: AppTheme.primaryColor,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              onChanged: (val) {
                                                setDialogState(() {
                                                  if (val == true) {
                                                    selectedSchoolIds.add(s.id);
                                                  } else {
                                                    selectedSchoolIds.remove(s.id);
                                                  }
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              s.name,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: isDark ? AppTheme.textLight : AppTheme.textDark,
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

                      const SizedBox(height: 24),

                      // Dialog Buttons
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
                                final name = nameCtrl.text.trim();
                                final email = emailCtrl.text.trim();
                                final phone = phoneCtrl.text.trim();
                                final spec = specCtrl.text.trim();
                                final pass = passCtrl.text;

                                if (name.isEmpty) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter teacher name.'),
                                      backgroundColor: AppTheme.dangerColor,
                                    ),
                                  );
                                  return;
                                }

                                if (!isEdit && (email.isEmpty || pass.isEmpty)) {
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      content: Text('Email and password are required.'),
                                      backgroundColor: AppTheme.dangerColor,
                                    ),
                                  );
                                  return;
                                }

                                final adminData = context.read<AdminDataProvider>();

                                try {
                                  if (isEdit) {
                                    await adminData.updateTeacher(
                                      existingTeacher.id,
                                      name: name,
                                      phone: phone,
                                      specialization: spec,
                                      schoolIds: selectedSchoolIds,
                                    );
                                  } else {
                                    await adminData.addTeacher(
                                      name: name,
                                      email: email,
                                      phone: phone,
                                      specialization: spec,
                                      schoolIds: selectedSchoolIds,
                                      password: pass,
                                    );
                                  }

                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                  }
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(isEdit
                                          ? 'Teacher updated successfully!'
                                          : 'Teacher registered successfully!'),
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
                                isEdit ? 'Save Changes' : 'Add Teacher',
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
  void _showDeleteConfirmation(UserModel teacher) {
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
              'Delete Teacher Account?',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${teacher.name}" (${teacher.email})? This action cannot be undone.',
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
              await context.read<AdminDataProvider>().deleteUser(teacher.id);
              if (ctx.mounted) {
                Navigator.pop(ctx);
              }
              messenger.showSnackBar(
                SnackBar(
                  content: Text('${teacher.name} deleted.'),
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
    final teachers = adminData.teachers;
    final schools = adminData.schools;

    final filtered = teachers.where((t) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase().trim();
      final matchesName = t.name.toLowerCase().contains(q) ||
          t.firstName.toLowerCase().contains(q) ||
          t.lastName.toLowerCase().contains(q);
      final matchesEmail = t.email.toLowerCase().contains(q);
      return matchesName || matchesEmail;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Section: Title, Subtitle, and "Add Teacher" Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Teachers',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppTheme.textLight : AppTheme.textDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${teachers.length} teacher${teachers.length == 1 ? '' : 's'} registered',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditTeacherDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text(
                    'Add Teacher',
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
                        hintText: 'Search teachers…',
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

            // 3. Teachers Table Card
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
                            Icons.school_outlined,
                            size: 44,
                            color: (isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight)
                                .withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _searchQuery.isNotEmpty
                                ? 'No teachers matching "$_searchQuery"'
                                : 'No teachers yet',
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
                                setState(() => _searchQuery = '');
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
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 800),
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
                                      'NAME',
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
                                      'CONTACT',
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
                                      'SCHOOLS',
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
                                      'JOINED',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.6,
                                        color: isDark ? AppTheme.textMutedDark : AppTheme.textMutedLight,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 110,
                                    child: Text(
                                      'ACTIONS',
                                      textAlign: TextAlign.right,
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
                            ...filtered.asMap().entries.map((entry) {
                              final index = entry.key;
                              final t = entry.value;
                              final isLast = index == filtered.length - 1;
                              final teacherName = t.name.isNotEmpty
                                  ? t.name
                                  : '${t.firstName} ${t.lastName}'.trim();
                              final initialLetter = teacherName.isNotEmpty
                                  ? teacherName[0].toUpperCase()
                                  : 'T';

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
                                    // 1. Name Column with Avatar Initial
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 30,
                                            height: 30,
                                            decoration: BoxDecoration(
                                              color: isDark
                                                  ? const Color(0xFF38251E)
                                                  : const Color(0xFFFDEEE7),
                                              shape: BoxShape.circle,
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              initialLetter,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              teacherName,
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

                                    // 2. Contact Column (Email + Phone)
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.mail_outline_rounded,
                                                size: 13,
                                                color: isDark ? AppTheme.textMutedDark : const Color(0xFF85746E),
                                              ),
                                              const SizedBox(width: 5),
                                              Expanded(
                                                child: Text(
                                                  t.email,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isDark ? AppTheme.textMutedDark : const Color(0xFF85746E),
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (t.phone?.isNotEmpty == true) ...[
                                            const SizedBox(height: 3),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.phone_outlined,
                                                  size: 13,
                                                  color: isDark ? AppTheme.textMutedDark : const Color(0xFF85746E),
                                                ),
                                                const SizedBox(width: 5),
                                                Expanded(
                                                  child: Text(
                                                    t.phone!,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: isDark ? AppTheme.textMutedDark : const Color(0xFF85746E),
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),

                                    // 3. Schools Column (Badges)
                                    Expanded(
                                      flex: 3,
                                      child: t.schoolIds.isEmpty
                                          ? Text(
                                              '—',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: isDark ? AppTheme.textMutedDark : const Color(0xFF85746E),
                                              ),
                                            )
                                          : Wrap(
                                              spacing: 5,
                                              runSpacing: 4,
                                              children: t.schoolIds.map((sid) {
                                                final s = schools.where((sc) => sc.id == sid).firstOrNull;
                                                final shortName = s != null ? s.name.split(' ').first : sid;
                                                return Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: isDark ? const Color(0xFF3B332E) : const Color(0xFFF3ECE6),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    shortName,
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w500,
                                                      color: isDark ? AppTheme.textLight : AppTheme.textDark,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                    ),

                                    // 4. Joined Column
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        _formatJoinedDate(t.createdAt),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? AppTheme.textMutedDark : const Color(0xFF85746E),
                                        ),
                                      ),
                                    ),

                                    // 5. Actions Column (View, Edit, Delete)
                                    SizedBox(
                                      width: 110,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          // View Button
                                          IconButton(
                                            visualDensity: VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                            icon: Icon(
                                              Icons.visibility_outlined,
                                              size: 17,
                                              color: isDark ? AppTheme.textMutedDark : const Color(0xFF85746E),
                                            ),
                                            tooltip: 'View',
                                            onPressed: () => _showViewTeacherDialog(t),
                                          ),
                                          const SizedBox(width: 2),

                                          // Edit Button
                                          IconButton(
                                            visualDensity: VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                              size: 17,
                                              color: AppTheme.primaryColor,
                                            ),
                                            tooltip: 'Edit',
                                            onPressed: () => _showAddEditTeacherDialog(t),
                                          ),
                                          const SizedBox(width: 2),

                                          // Delete Button
                                          IconButton(
                                            visualDensity: VisualDensity.compact,
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                            icon: const Icon(
                                              Icons.delete_outline_rounded,
                                              size: 17,
                                              color: Color(0xFFDC2626),
                                            ),
                                            tooltip: 'Delete',
                                            onPressed: () => _showDeleteConfirmation(t),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
