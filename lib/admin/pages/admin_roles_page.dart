import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_data_provider.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

class AdminRolesPage extends StatelessWidget {
  const AdminRolesPage({super.key});

  void _showAssignRoleDialog(BuildContext context, UserModel user, [UserRole? defaultTargetRole]) {
    String selectedRole = defaultTargetRole != null ? defaultTargetRole.toDbString() : user.role.toDbString();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Change Role: ${user.name}'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
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
                    initialValue: UserRole.fromString(selectedRole).toDbString(),
                    decoration: const InputDecoration(labelText: 'Assigned System Role *'),
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

    UserModel selectedUser = allUsers.first;
    String targetRole = preselectedTargetRole != null ? preselectedTargetRole.toDbString() : 'super_admin';

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
                    decoration: const InputDecoration(),
                    items: allUsers.map((u) {
                      return DropdownMenuItem(
                        value: u,
                        child: Text('${u.name} (${u.email}) - [${u.role.displayName}]', style: const TextStyle(fontSize: 13)),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedUser = val ?? selectedUser),
                  ),
                  const SizedBox(height: 16),
                  const Text('Assign To Role:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: targetRole,
                    decoration: const InputDecoration(),
                    items: const [
                      DropdownMenuItem(value: 'super_admin', child: Text('Super Administrator (Full System Access)')),
                      DropdownMenuItem(value: 'admin', child: Text('Administrator')),
                      DropdownMenuItem(value: 'staff_admin', child: Text('Staff Administrator')),
                      DropdownMenuItem(value: 'staff', child: Text('Operations Staff')),
                      DropdownMenuItem(value: 'researcher', child: Text('Field Researcher')),
                      DropdownMenuItem(value: 'teacher', child: Text('Institutional Teacher')),
                    ],
                    onChanged: (val) => setDialogState(() => targetRole = val ?? targetRole),
                  ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Role Permissions & Assignments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Manage global permissions and promote accounts across the platform', style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showGlobalUserRolePicker(context, users),
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  label: const Text('Change User Role'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Role Cards List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: roles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
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
                              children: [
                                Icon(Icons.check_circle, size: 14, color: color),
                                const SizedBox(width: 6),
                                Text(p, style: const TextStyle(fontSize: 12)),
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
