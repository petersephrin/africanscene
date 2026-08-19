import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_data_provider.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

class AdminStaffPage extends StatefulWidget {
  const AdminStaffPage({super.key});

  @override
  State<AdminStaffPage> createState() => _AdminStaffPageState();
}

class _AdminStaffPageState extends State<AdminStaffPage> {
  String _searchQuery = '';

  static const List<DropdownMenuItem<String>> _allRoleDropdownItems = [
    DropdownMenuItem(value: 'super_admin', child: Text('Super Administrator (Full System Access)')),
    DropdownMenuItem(value: 'admin', child: Text('Administrator')),
    DropdownMenuItem(value: 'staff_admin', child: Text('Staff Administrator')),
    DropdownMenuItem(value: 'staff', child: Text('Operations Staff')),
    DropdownMenuItem(value: 'researcher', child: Text('Field Researcher')),
    DropdownMenuItem(value: 'teacher', child: Text('Institutional Teacher')),
  ];

  String _sanitizeRole(String? raw) {
    final role = UserRole.fromString(raw).toDbString();
    return role;
  }

  void _showAddStaffDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final deptCtrl = TextEditingController(text: 'Field Operations');
    final passCtrl = TextEditingController(text: 'Password123!');
    String selectedRole = 'staff';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Staff Member / Admin'),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name *')),
                    const SizedBox(height: 10),
                    TextField(controller: emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email Address *')),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(labelText: 'Role & Permission Level *'),
                      items: _allRoleDropdownItems,
                      onChanged: (val) => setDialogState(() => selectedRole = val ?? 'staff'),
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: deptCtrl, decoration: const InputDecoration(labelText: 'Department')),
                    const SizedBox(height: 10),
                    TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
                    const SizedBox(height: 10),
                    TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Initial Password *', helperText: 'User will use this to sign into the system')),
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
                    await context.read<AdminDataProvider>().addStaff(
                      name: nameCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      role: selectedRole,
                      department: deptCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      password: passCtrl.text,
                    );
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(selectedRole == 'super_admin'
                              ? 'Super Administrator provisioned successfully!'
                              : 'Staff member created!'),
                          backgroundColor: AppTheme.successColor,
                        ),
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
                child: const Text('Create Account'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditStaffDialog(UserModel staffMember) {
    final nameCtrl = TextEditingController(text: staffMember.name);
    final phoneCtrl = TextEditingController(text: staffMember.phone ?? '');
    final deptCtrl = TextEditingController(text: staffMember.department ?? '');
    String selectedRole = _sanitizeRole(staffMember.role.toDbString());

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Staff & Role'),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name *')),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      decoration: const InputDecoration(labelText: 'Role & Permission Level *'),
                      items: _allRoleDropdownItems,
                      onChanged: (val) => setDialogState(() => selectedRole = val ?? selectedRole),
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: deptCtrl, decoration: const InputDecoration(labelText: 'Department')),
                    const SizedBox(height: 10),
                    TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty) return;

                  try {
                    await context.read<AdminDataProvider>().updateStaff(
                      staffMember.id,
                      name: nameCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      department: deptCtrl.text.trim(),
                      role: selectedRole,
                    );
                    if (mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Account updated!'), backgroundColor: AppTheme.successColor),
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
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteDialog(UserModel staffMember) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Staff Account?'),
        content: Text('Are you sure you want to remove ${staffMember.name} (${staffMember.email})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            onPressed: () async {
              await context.read<AdminDataProvider>().deleteUser(staffMember.id);
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff member removed.')));
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
    final staffList = adminData.staff;

    final filtered = staffList.where((s) {
      final q = _searchQuery.toLowerCase().trim();
      return s.name.toLowerCase().contains(q) ||
          s.email.toLowerCase().contains(q) ||
          (s.department?.toLowerCase().contains(q) ?? false);
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
                      hintText: 'Search staff by name, email, or department...',
                      prefixIcon: Icon(Icons.search, size: 20),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _showAddStaffDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Staff / Admin'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No staff members registered or found.', style: TextStyle(color: Colors.grey)))
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final s = filtered[index];
                        final isSuper = s.role == UserRole.superAdmin;

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
                                backgroundColor: isSuper
                                    ? AppTheme.dangerColor.withValues(alpha: 0.12)
                                    : AppTheme.accentColor.withValues(alpha: 0.12),
                                child: Text(
                                  s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S',
                                  style: TextStyle(
                                    color: isSuper ? AppTheme.dangerColor : AppTheme.accentColor,
                                    fontWeight: FontWeight.bold,
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
                                        Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isSuper
                                                ? AppTheme.dangerColor.withValues(alpha: 0.1)
                                                : AppTheme.accentColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            s.role.displayName,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: isSuper ? AppTheme.dangerColor : AppTheme.accentColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${s.email} • ${s.phone ?? "No phone"} • Dept: ${s.department ?? "General Operations"}',
                                      style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                tooltip: 'Edit / Change Role',
                                onPressed: () => _showEditStaffDialog(s),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.dangerColor),
                                tooltip: 'Delete',
                                onPressed: () => _showDeleteDialog(s),
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
