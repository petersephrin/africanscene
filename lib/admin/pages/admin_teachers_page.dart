import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_data_provider.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

class AdminTeachersPage extends StatefulWidget {
  const AdminTeachersPage({super.key});

  @override
  State<AdminTeachersPage> createState() => _AdminTeachersPageState();
}

class _AdminTeachersPageState extends State<AdminTeachersPage> {
  String _searchQuery = '';
  String _schoolFilter = 'all';

  void _showAddTeacherDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final specCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: 'Password123!');
    final selectedSchoolIds = <String>[];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final schools = context.read<AdminDataProvider>().schools;

          return AlertDialog(
            title: const Text('Add Institutional Teacher'),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Teacher Name *')),
                    const SizedBox(height: 10),
                    TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email Address *')),
                    const SizedBox(height: 10),
                    TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
                    const SizedBox(height: 10),
                    TextField(controller: specCtrl, decoration: const InputDecoration(labelText: 'Subject / Grade Specialization')),
                    const SizedBox(height: 10),
                    TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Initial Password *')),
                    const SizedBox(height: 14),
                    const Text('Assign School:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 140),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        children: schools.map((s) {
                          final isAssigned = selectedSchoolIds.contains(s.id);
                          return CheckboxListTile(
                            dense: true,
                            title: Text(s.name, style: const TextStyle(fontSize: 12)),
                            value: isAssigned,
                            activeColor: AppTheme.accentColor,
                            onChanged: (val) {
                              setDialogState(() {
                                if (val == true) {
                                  selectedSchoolIds.add(s.id);
                                } else {
                                  selectedSchoolIds.remove(s.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty || emailCtrl.text.trim().isEmpty || passCtrl.text.isEmpty) return;

                  try {
                    await context.read<AdminDataProvider>().addTeacher(
                      name: nameCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      specialization: specCtrl.text.trim(),
                      schoolIds: selectedSchoolIds,
                      password: passCtrl.text,
                    );
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Teacher registered successfully!'), backgroundColor: AppTheme.successColor),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.dangerColor),
                      );
                    }
                  }
                },
                child: const Text('Register Teacher'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditTeacherDialog(UserModel teacher) {
    final nameCtrl = TextEditingController(text: teacher.name);
    final phoneCtrl = TextEditingController(text: teacher.phone ?? '');
    final specCtrl = TextEditingController(text: teacher.specialization ?? '');
    final selectedSchoolIds = List<String>.from(teacher.schoolIds);
    String selectedRole = teacher.role.toDbString();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final schools = context.read<AdminDataProvider>().schools;

          return AlertDialog(
            title: const Text('Edit Teacher Profile & Role'),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name *')),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: UserRole.fromString(selectedRole).toDbString(),
                      decoration: const InputDecoration(labelText: 'Role Permission Level *'),
                      items: const [
                        DropdownMenuItem(value: 'super_admin', child: Text('Super Administrator (Full System Access)')),
                        DropdownMenuItem(value: 'admin', child: Text('Administrator')),
                        DropdownMenuItem(value: 'staff_admin', child: Text('Staff Administrator')),
                        DropdownMenuItem(value: 'staff', child: Text('Operations Staff')),
                        DropdownMenuItem(value: 'researcher', child: Text('Field Researcher')),
                        DropdownMenuItem(value: 'teacher', child: Text('Institutional Teacher')),
                      ],
                      onChanged: (val) => setDialogState(() => selectedRole = val ?? selectedRole),
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
                    const SizedBox(height: 10),
                    TextField(controller: specCtrl, decoration: const InputDecoration(labelText: 'Subject / Grade Specialization')),
                    const SizedBox(height: 14),
                    const Text('Assigned School Institutions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 140),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        children: schools.map((s) {
                          final isAssigned = selectedSchoolIds.contains(s.id);
                          return CheckboxListTile(
                            dense: true,
                            title: Text(s.name, style: const TextStyle(fontSize: 12)),
                            value: isAssigned,
                            activeColor: AppTheme.accentColor,
                            onChanged: (val) {
                              setDialogState(() {
                                if (val == true) {
                                  selectedSchoolIds.add(s.id);
                                } else {
                                  selectedSchoolIds.remove(s.id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  await context.read<AdminDataProvider>().updateTeacher(
                    teacher.id,
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim(),
                    specialization: specCtrl.text.trim(),
                    schoolIds: selectedSchoolIds,
                    role: selectedRole,
                  );
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Teacher updated!'), backgroundColor: AppTheme.successColor),
                    );
                  }
                },
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteDialog(UserModel teacher) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Teacher?'),
        content: Text('Are you sure you want to remove ${teacher.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            onPressed: () async {
              await context.read<AdminDataProvider>().deleteUser(teacher.id);
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Teacher removed.')));
              }
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
    final teachers = adminData.teachers;
    final schools = adminData.schools;

    final filtered = teachers.where((t) {
      final q = _searchQuery.toLowerCase().trim();
      final matchesQ = t.name.toLowerCase().contains(q) ||
          t.email.toLowerCase().contains(q) ||
          (t.specialization?.toLowerCase().contains(q) ?? false);
      if (!matchesQ) return false;
      if (_schoolFilter != 'all' && !t.schoolIds.contains(_schoolFilter)) return false;
      return true;
    }).toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search teachers by name, subject, or email...',
                      prefixIcon: Icon(Icons.search, size: 20),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _schoolFilter,
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('All Assigned Institutions')),
                    ...schools.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                  ],
                  onChanged: (val) => setState(() => _schoolFilter = val ?? 'all'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _showAddTeacherDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Teacher'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No teachers registered or found.', style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final t = filtered[index];

                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.12),
                                child: Text(
                                  t.name.isNotEmpty ? t.name[0].toUpperCase() : 'T',
                                  style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    const SizedBox(height: 2),
                                    Text('${t.email} • ${t.phone ?? "No phone"} • ${t.specialization ?? "General Teacher"}', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${t.schoolIds.length} assigned institution(s)',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.accentColor, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                tooltip: 'Edit / Change Role',
                                onPressed: () => _showEditTeacherDialog(t),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.dangerColor),
                                tooltip: 'Delete',
                                onPressed: () => _showDeleteDialog(t),
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
}
