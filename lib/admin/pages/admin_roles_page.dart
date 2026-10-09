import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_data_provider.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

class AdminRolesPage extends StatelessWidget {
  const AdminRolesPage({super.key});

  void _showAssignRoleDialog(BuildContext context, UserModel user, [UserRole? defaultTargetRole]) {
    String selectedRole = defaultTargetRole != null ? defaultTargetRole.toDbString() : user.role.toDbString();
    final adminData = context.read<AdminDataProvider>();
    final schools = adminData.schools;
    String? chosenSchoolId = user.schoolIds.firstOrNull ?? (schools.isNotEmpty ? schools.first.id : null);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Change Role: ${user.name}'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Email: ${user.email}',
                    style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Assigned System Role *'),
                    items: const [
                      DropdownMenuItem(value: 'super_admin', child: Text('Super Administrator (Full System Access)', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'admin', child: Text('Administrator', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'staff_admin', child: Text('Staff Administrator', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'school_admin', child: Text('School Administrator (Headteacher / Institutional Lead)', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'staff', child: Text('Operations Staff', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'researcher', child: Text('Field Researcher', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'teacher', child: Text('Institutional Teacher', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (val) => setDialogState(() => selectedRole = val ?? selectedRole),
                  ),
                  if (selectedRole == 'school_admin') ...[
                    const SizedBox(height: 14),
                    const Text('Assign To School:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    if (schools.isEmpty)
                      const Text('No schools available. Register a school first.', style: TextStyle(fontSize: 12, color: Colors.orange))
                    else
                      DropdownButtonFormField<String>(
                        value: chosenSchoolId,
                        isExpanded: true,
                        decoration: const InputDecoration(),
                        items: schools.map((s) {
                          return DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis));
                        }).toList(),
                        onChanged: (val) => setDialogState(() => chosenSchoolId = val),
                      ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await context.read<AdminDataProvider>().updateUserRole(
                          user.id,
                          selectedRole,
                          schoolIds: selectedRole == 'school_admin' && chosenSchoolId != null ? [chosenSchoolId!] : null,
                        );
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Updated ${user.name} to ${UserRole.fromString(selectedRole).displayName}!'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.dangerColor),
                      );
                    }
                  }
                },
                child: const Text('Save Role'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showGlobalUserRolePicker(BuildContext context, List<UserModel> allUsers, [UserRole? preselectedTargetRole]) {
    if (allUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No users found to assign.')),
      );
      return;
    }

    final adminData = context.read<AdminDataProvider>();
    final schools = adminData.schools;
    UserModel selectedUser = allUsers.first;
    String targetRole = preselectedTargetRole != null ? preselectedTargetRole.toDbString() : 'super_admin';
    String? chosenSchoolId = selectedUser.schoolIds.firstOrNull ?? (schools.isNotEmpty ? schools.first.id : null);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Assign User Role'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select User:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<UserModel>(
                    value: selectedUser,
                    isExpanded: true,
                    decoration: const InputDecoration(),
                    items: allUsers.map((u) {
                      return DropdownMenuItem(
                        value: u,
                        child: Text(
                          '${u.name.isNotEmpty ? u.name : "User"} (${u.email}) - [${u.role.displayName}]',
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() {
                        selectedUser = val ?? selectedUser;
                        chosenSchoolId = selectedUser.schoolIds.firstOrNull ?? (schools.isNotEmpty ? schools.first.id : null);
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Assign To Role:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: targetRole,
                    isExpanded: true,
                    decoration: const InputDecoration(),
                    items: const [
                      DropdownMenuItem(value: 'super_admin', child: Text('Super Administrator (Full System Access)', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'admin', child: Text('Administrator', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'staff_admin', child: Text('Staff Administrator', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'school_admin', child: Text('School Administrator (Headteacher / Institutional Lead)', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'staff', child: Text('Operations Staff', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'researcher', child: Text('Field Researcher', overflow: TextOverflow.ellipsis)),
                      DropdownMenuItem(value: 'teacher', child: Text('Institutional Teacher', overflow: TextOverflow.ellipsis)),
                    ],
                    onChanged: (val) => setDialogState(() => targetRole = val ?? targetRole),
                  ),
                  if (targetRole == 'school_admin') ...[
                    const SizedBox(height: 14),
                    const Text('Assign To School:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    if (schools.isEmpty)
                      const Text('No schools available. Register a school first.', style: TextStyle(fontSize: 12, color: Colors.orange))
                    else
                      DropdownButtonFormField<String>(
                        value: chosenSchoolId,
                        isExpanded: true,
                        decoration: const InputDecoration(),
                        items: schools.map((s) {
                          return DropdownMenuItem(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis));
                        }).toList(),
                        onChanged: (val) => setDialogState(() => chosenSchoolId = val),
                      ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await context.read<AdminDataProvider>().updateUserRole(
                          selectedUser.id,
                          targetRole,
                          schoolIds: targetRole == 'school_admin' && chosenSchoolId != null ? [chosenSchoolId!] : null,
                        );
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Assigned ${selectedUser.name} to ${UserRole.fromString(targetRole).displayName}!'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.dangerColor),
                      );
                    }
                  }
                },
                child: const Text('Apply Role'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddSchoolAdminDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: 'Password123!');
    final adminData = context.read<AdminDataProvider>();
    final schools = adminData.schools;
    String? selectedSchoolId = schools.isNotEmpty ? schools.first.id : null;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.school_outlined, color: Color(0xFF0EA5E9), size: 24),
                SizedBox(width: 10),
                Text('Add School Administrator', style: TextStyle(fontSize: 18)),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Register a new headteacher or institutional lead and assign them to a school.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Full Name *', hintText: 'Principal K. Juma'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(labelText: 'Email Address *', hintText: 'headteacher@school.org'),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) => (v == null || !v.contains('@')) ? 'Valid email required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: phoneCtrl,
                        decoration: const InputDecoration(labelText: 'Phone Number', hintText: '+254...'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passCtrl,
                        decoration: const InputDecoration(labelText: 'Initial Password *', hintText: '••••••••'),
                        validator: (v) => (v == null || v.length < 6) ? 'Min 6 characters' : null,
                      ),
                      const SizedBox(height: 14),
                      const Text('Assigned School *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      if (schools.isEmpty)
                        const Text('No schools available. Register a school first.', style: TextStyle(color: Colors.orange, fontSize: 12))
                      else
                        DropdownButtonFormField<String>(
                          value: selectedSchoolId,
                          isExpanded: true,
                          decoration: const InputDecoration(),
                          items: schools.map((s) {
                            return DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (val) => setDialogState(() => selectedSchoolId = val),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0EA5E9),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  if (selectedSchoolId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select an assigned school.'), backgroundColor: AppTheme.dangerColor),
                    );
                    return;
                  }
                  try {
                    await adminData.addSchoolAdmin(
                      name: nameCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      phone: phoneCtrl.text.trim(),
                      schoolIds: [selectedSchoolId!],
                      password: passCtrl.text.trim(),
                    );
                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('School Administrator ${nameCtrl.text.trim()} created successfully!'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error creating School Admin: $e'), backgroundColor: AppTheme.dangerColor),
                      );
                    }
                  }
                },
                child: const Text('Create School Admin'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminData = context.watch<AdminDataProvider>();
    final users = adminData.users;

    final roles = [
      {
        'role': UserRole.superAdmin,
        'title': 'Super Administrator',
        'desc': 'Unrestricted global access, database initialization, security policies, and administrative provisioning.',
        'color': AppTheme.dangerColor,
        'icon': Icons.security,
        'permissions': ['Manage all users and roles', 'Configure form field templates', 'Delete records directly', 'Approve/Reject deletion requests', 'Seed and export data'],
      },
      {
        'role': UserRole.staffAdmin,
        'title': 'Staff Administrator',
        'desc': 'Field team management, school registration, and institutional moderation.',
        'color': AppTheme.accentColor,
        'icon': Icons.admin_panel_settings_outlined,
        'permissions': ['Add and assign researchers', 'Register new institutions', 'Review deletion requests', 'Download analytics reports'],
      },
      {
        'role': UserRole.staff,
        'title': 'Operations Staff',
        'desc': 'Administrative operations, reporting support, and institutional oversight.',
        'color': const Color(0xFF8B5CF6),
        'icon': Icons.badge_outlined,
        'permissions': ['View school registry', 'Inspect records repository', 'Export institutional data'],
      },
      {
        'role': UserRole.researcher,
        'title': 'Field Researcher',
        'desc': 'Field data collection across assigned institutions, offline synchronization, and dynamic form submissions.',
        'color': AppTheme.primaryColor,
        'icon': Icons.biotech_outlined,
        'permissions': ['Submit weekly, termly, and annual records', 'Save offline data with drift validation', 'Edit records with version reason', 'Request record deletions'],
      },
      {
        'role': UserRole.schoolAdmin,
        'title': 'School Administrator',
        'desc': 'Headteacher or institutional lead managing local school profile, student count, and record verifications directly in the mobile/staff app.',
        'color': const Color(0xFF0284C7),
        'icon': Icons.account_balance_outlined,
        'permissions': [
          'Update school profile, contacts, motto, and student count',
          'Register and manage teachers assigned to this school',
          'Inspect institutional records in staff app',
          'Submit record deletion requests for administrative review',
        ],
      },
      {
        'role': UserRole.teacher,
        'title': 'Institutional Teacher',
        'desc': 'School-level data entry, attendance tracking, and term summaries.',
        'color': const Color(0xFF10B981),
        'icon': Icons.person_pin_outlined,
        'permissions': ['Submit attendance records', 'Enter term scores and curriculum status', 'Review school activity'],
      },
    ];

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Bar with Quick Action
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 620;
                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Role Permissions & Assignments',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Manage global permissions and promote accounts across the platform',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => _showAddSchoolAdminDialog(context),
                            icon: const Icon(Icons.school_outlined, size: 16),
                            label: const Text('Add School Admin'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0EA5E9),
                              side: const BorderSide(color: Color(0xFF0EA5E9)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _showGlobalUserRolePicker(context, users),
                            icon: const Icon(Icons.person_add_alt_1, size: 18),
                            label: const Text('Change User Role'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                          const Text(
                            'Role Permissions & Assignments',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Manage global permissions and promote accounts across the platform',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _showAddSchoolAdminDialog(context),
                          icon: const Icon(Icons.school_outlined, size: 16),
                          label: const Text('Add School Admin'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF0EA5E9),
                            side: const BorderSide(color: Color(0xFF0EA5E9)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () => _showGlobalUserRolePicker(context, users),
                          icon: const Icon(Icons.person_add_alt_1, size: 18),
                          label: const Text('Change User Role'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),

            // Role Cards List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: roles.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final r = roles[index];
                final roleEnum = r['role'] as UserRole;
                final assignedUsers = users.where((u) => u.role == roleEnum).toList();
                final userCount = assignedUsers.length;
                final color = r['color'] as Color;
                final permissions = r['permissions'] as List<String>;

                return Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(r['icon'] as IconData, color: color, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 2),
                                  Text('$userCount assigned account(s)', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _showGlobalUserRolePicker(context, users, roleEnum),
                                icon: const Icon(Icons.add, size: 14),
                                label: const Text('Assign User', style: TextStyle(fontSize: 11)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: color,
                                  side: BorderSide(color: color.withValues(alpha: 0.4)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                              if (roleEnum == UserRole.schoolAdmin) ...[
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () => _showAddSchoolAdminDialog(context),
                                  icon: const Icon(Icons.person_add_alt_1, size: 13),
                                  label: const Text('+ Add New', style: TextStyle(fontSize: 11)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: color,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        r['desc'] as String,
                        style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8)),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),

                      // Assigned Accounts List
                      if (assignedUsers.isNotEmpty) ...[
                        Row(
                          children: [
                            const Text('Assigned Users:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 6),
                            Text('(click user to edit/reassign)', style: TextStyle(fontSize: 10, color: Theme.of(context).textTheme.bodySmall?.color)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: assignedUsers.map((u) {
                            return InkWell(
                              onTap: () => _showAssignRoleDialog(context, u),
                              borderRadius: BorderRadius.circular(999),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: color.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      u.name.isNotEmpty ? u.name : u.email,
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.edit_outlined, size: 13, color: color),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                      ],

                      const Text('Permissions & Capabilities:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      ...permissions.map((p) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Icon(Icons.check_circle, size: 14, color: color),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(p, style: const TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
