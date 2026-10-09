import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/school_model.dart';
import '../models/user_model.dart';
import '../providers/school_provider.dart';
import '../theme/app_theme.dart';

class ManageSchoolModal extends StatefulWidget {
  final SchoolModel school;

  const ManageSchoolModal({
    super.key,
    required this.school,
  });

  @override
  State<ManageSchoolModal> createState() => _ManageSchoolModalState();
}

class _ManageSchoolModalState extends State<ManageSchoolModal> {
  int _activeTab = 0; // 0 = Profile, 1 = Teachers
  final _profileFormKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _principalController;
  late TextEditingController _studentsController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _mottoController;
  late TextEditingController _descController;
  bool _isSavingProfile = false;

  List<UserModel> _teachers = [];
  bool _isLoadingTeachers = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.school.name);
    _locationController = TextEditingController(text: widget.school.location);
    _principalController = TextEditingController(text: widget.school.principal ?? '');
    _studentsController = TextEditingController(
      text: widget.school.students > 0 ? widget.school.students.toString() : '',
    );
    _phoneController = TextEditingController(text: widget.school.phone ?? '');
    _emailController = TextEditingController(text: widget.school.email ?? '');
    _mottoController = TextEditingController(text: widget.school.motto ?? '');
    _descController = TextEditingController(text: widget.school.description ?? '');

    _loadTeachers();
  }

  Future<void> _loadTeachers() async {
    setState(() => _isLoadingTeachers = true);
    final schoolProvider = context.read<SchoolProvider>();
    final teachers = await schoolProvider.fetchTeachersForSchool(widget.school.id);
    if (mounted) {
      setState(() {
        _teachers = teachers;
        _isLoadingTeachers = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _principalController.dispose();
    _studentsController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _mottoController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;

    setState(() => _isSavingProfile = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final updates = <String, dynamic>{
        'name': _nameController.text.trim(),
        'location': _locationController.text.trim(),
        'principal': _principalController.text.trim(),
        'students': int.tryParse(_studentsController.text.trim()) ?? widget.school.students,
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'motto': _mottoController.text.trim(),
        'description': _descController.text.trim(),
      };

      await context.read<SchoolProvider>().updateSchoolDetails(
            schoolId: widget.school.id,
            updates: updates,
          );

      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('School profile updated successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to update school: $e'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  void _showAddTeacherDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: 'Password123!');
    final phoneCtrl = TextEditingController();
    final specCtrl = TextEditingController();
    bool isAdding = false;

    showDialog(
      context: context,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (context, setDlgState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person_add_outlined, color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Add Teacher',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assign a teacher directly to ${widget.school.name}',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                      ),
                      const SizedBox(height: 16),

                      // Name
                      _buildTextField(
                        label: 'Full Name *',
                        controller: nameCtrl,
                        icon: Icons.person_outline,
                        hint: 'e.g. Mary Atieno',
                        validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 12),

                      // Email
                      _buildTextField(
                        label: 'Email Address *',
                        controller: emailCtrl,
                        icon: Icons.mail_outline,
                        hint: 'e.g. teacher@school.ac.ke',
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Email is required';
                          if (!v.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Password
                      _buildTextField(
                        label: 'Initial Password *',
                        controller: passCtrl,
                        icon: Icons.lock_outline,
                        hint: 'Min 6 characters',
                        validator: (v) => v == null || v.length < 6 ? 'Min 6 characters required' : null,
                      ),
                      const SizedBox(height: 12),

                      // Specialization
                      _buildTextField(
                        label: 'Subject / Specialization',
                        controller: specCtrl,
                        icon: Icons.menu_book_outlined,
                        hint: 'e.g. Biology & Chemistry',
                      ),
                      const SizedBox(height: 12),

                      // Phone
                      _buildTextField(
                        label: 'Phone Number',
                        controller: phoneCtrl,
                        icon: Icons.phone_outlined,
                        hint: 'e.g. +254 712 345 678',
                        keyboardType: TextInputType.phone,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isAdding ? null : () => Navigator.pop(dlgCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isAdding
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        setDlgState(() => isAdding = true);
                        final messenger = ScaffoldMessenger.of(context);

                        try {
                          final newTeacher = await context.read<SchoolProvider>().addTeacherToSchool(
                                schoolId: widget.school.id,
                                name: nameCtrl.text.trim(),
                                email: emailCtrl.text.trim(),
                                password: passCtrl.text.trim(),
                                phone: phoneCtrl.text.trim(),
                                specialization: specCtrl.text.trim(),
                              );

                          if (mounted) {
                            setState(() {
                              _teachers = [newTeacher, ..._teachers];
                            });
                          }
                          if (dlgCtx.mounted) {
                            Navigator.pop(dlgCtx);
                          }
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Teacher ${newTeacher.name} successfully registered!'),
                              backgroundColor: AppTheme.successColor,
                            ),
                          );
                        } catch (e) {
                          setDlgState(() => isAdding = false);
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Error adding teacher: $e'),
                              backgroundColor: AppTheme.dangerColor,
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isAdding
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Register Teacher'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grab Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.school.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Institutional Administration Hub',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tab Selector (School Profile vs Teachers)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      index: 0,
                      title: 'School Profile',
                      icon: Icons.edit_note,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildTabButton(
                      index: 1,
                      title: 'Teachers (${_teachers.length})',
                      icon: Icons.school_outlined,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Content Area
            Flexible(
              child: _activeTab == 0 ? _buildProfileTab() : _buildTeachersTab(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required String title,
    required IconData icon,
  }) {
    final isSelected = _activeTab == index;
    return InkWell(
      onTap: () => setState(() => _activeTab = index),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Theme.of(context).textTheme.bodySmall?.color,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return Form(
      key: _profileFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // School Name
                  _buildTextField(
                    label: 'School Name *',
                    controller: _nameController,
                    icon: Icons.apartment,
                    validator: (v) => v == null || v.trim().isEmpty ? 'School name is required' : null,
                  ),
                  const SizedBox(height: 12),

                  // Location & Students
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: 'Location *',
                          controller: _locationController,
                          icon: Icons.location_on_outlined,
                          validator: (v) => v == null || v.trim().isEmpty ? 'Location is required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          label: 'Student Count',
                          controller: _studentsController,
                          icon: Icons.people_outline,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Principal Name
                  _buildTextField(
                    label: 'Principal / Headteacher Name',
                    controller: _principalController,
                    hint: 'e.g. Mrs. Jane Mwangi',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 12),

                  // Phone & Email
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          label: 'Official Phone',
                          controller: _phoneController,
                          hint: '+254 700 000 000',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          label: 'Official Email',
                          controller: _emailController,
                          hint: 'school@edu.ke',
                          icon: Icons.mail_outline,
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // School Motto
                  _buildTextField(
                    label: 'School Motto',
                    controller: _mottoController,
                    hint: 'e.g. In Pursuit of Excellence',
                    icon: Icons.lightbulb_outline,
                  ),
                  const SizedBox(height: 12),

                  // Description
                  _buildTextField(
                    label: 'School Overview / Description',
                    controller: _descController,
                    hint: 'Describe institutional focus, community energy projects, etc.',
                    icon: Icons.notes,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isSavingProfile ? null : () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSavingProfile ? null : _handleSaveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: _isSavingProfile
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Save School Data',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeachersTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Action Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Teaching Staff',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Teachers registered for this school',
                  style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _showAddTeacherDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              icon: const Icon(Icons.person_add_outlined, size: 16),
              label: const Text('Add Teacher', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // List or Empty View
        Expanded(
          child: _isLoadingTeachers
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _teachers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.school_outlined, size: 36, color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No teachers registered yet',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add teachers so they can sign in and record attendance & term logs.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _showAddTeacherDialog,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Register First Teacher'),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _teachers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final teacher = _teachers[index];
                        final initial = teacher.name.isNotEmpty
                            ? teacher.name[0].toUpperCase()
                            : (teacher.firstName.isNotEmpty ? teacher.firstName[0].toUpperCase() : 'T');

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      teacher.name.isNotEmpty ? teacher.name : '${teacher.firstName} ${teacher.lastName}'.trim(),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      teacher.email,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Theme.of(context).textTheme.bodySmall?.color,
                                      ),
                                    ),
                                    if (teacher.specialization != null && teacher.specialization!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        teacher.specialization!,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (teacher.phone != null && teacher.phone!.isNotEmpty)
                                Text(
                                  teacher.phone!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
