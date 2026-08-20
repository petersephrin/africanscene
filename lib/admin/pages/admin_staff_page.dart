import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_data_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';

class AdminStaffPage extends StatefulWidget {
  const AdminStaffPage({super.key});

  @override
  State<AdminStaffPage> createState() => _AdminStaffPageState();
}

class _AdminStaffPageState extends State<AdminStaffPage> {
  String _searchQuery = '';

  void _showViewModal(BuildContext context, UserModel s, bool canEdit) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(ctx).cardColor,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Staff Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () => Navigator.pop(ctx),
                        splashRadius: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(ctx, 'Name', s.name),
                  const SizedBox(height: 12),
                  _buildDetailRow(ctx, 'Email', s.email),
                  const SizedBox(height: 12),
                  _buildDetailRow(ctx, 'Phone', s.phone?.isNotEmpty == true ? s.phone! : '—'),
                  const SizedBox(height: 12),
                  _buildDetailRow(ctx, 'Department', s.department?.isNotEmpty == true ? s.department! : '—'),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    ctx,
                    'Role',
                    s.role == UserRole.superAdmin || s.role == UserRole.admin ? 'Super Admin' : 'Staff Admin',
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow(ctx, 'Status', s.status),
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    ctx,
                    'Joined',
                    s.createdAt != null ? DateFormat('d MMM yyyy').format(s.createdAt!) : '—',
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      if (canEdit) ...[
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showAddEditModal(context, s);
                            },
                            child: const Text('Edit'),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Close'),
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
    );
  }

  void _showAddEditModal(BuildContext context, [UserModel? editingStaff]) {
    final nameCtrl = TextEditingController(text: editingStaff?.name ?? '');
    final emailCtrl = TextEditingController(text: editingStaff?.email ?? '');
    final deptCtrl = TextEditingController(text: editingStaff?.department ?? '');
    final phoneCtrl = TextEditingController(text: editingStaff?.phone ?? '');
    final passCtrl = TextEditingController(text: editingStaff == null ? 'Password123!' : '');
    String selectedRole = editingStaff != null
        ? (editingStaff.role == UserRole.superAdmin || editingStaff.role == UserRole.admin ? 'admin' : 'staff_admin')
        : 'staff_admin';

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: Theme.of(context).cardColor,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            editingStaff != null ? 'Edit Staff Member' : 'Add Staff Member',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => Navigator.pop(ctx),
                            splashRadius: 18,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Full Name
                      const Text('Full Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'Jane Doe')),
                      const SizedBox(height: 12),

                      // Email (Add only)
                      if (editingStaff == null) ...[
                        const Text('Email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(hintText: 'jane@example.com'),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Department
                      const Text('Department', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(controller: deptCtrl, decoration: const InputDecoration(hintText: 'Field Operations')),
                      const SizedBox(height: 12),

                      // Phone
                      const Text('Phone', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(controller: phoneCtrl, decoration: const InputDecoration(hintText: '+254...')),
                      const SizedBox(height: 12),

                      // Role Dropdown
                      const Text('Role', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        key: ValueKey(selectedRole),
                        initialValue: selectedRole,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(value: 'staff_admin', child: Text('Staff Admin', overflow: TextOverflow.ellipsis)),
                          DropdownMenuItem(value: 'admin', child: Text('Super Admin', overflow: TextOverflow.ellipsis)),
                        ],
                        onChanged: (val) => setDialogState(() => selectedRole = val ?? 'staff_admin'),
                      ),
                      const SizedBox(height: 12),

                      // Password (Add only)
                      if (editingStaff == null) ...[
                        const Text('Initial Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(controller: passCtrl, decoration: const InputDecoration(hintText: '••••••••')),
                        const SizedBox(height: 12),
                      ],

                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () async {
                                if (nameCtrl.text.trim().isEmpty) return;
                                final adminData = context.read<AdminDataProvider>();
                                final dbRole = selectedRole == 'admin' ? 'super_admin' : 'staff_admin';

                                try {
                                  if (editingStaff != null) {
                                    await adminData.updateStaff(
                                      editingStaff.id,
                                      name: nameCtrl.text.trim(),
                                      phone: phoneCtrl.text.trim(),
                                      department: deptCtrl.text.trim(),
                                      role: dbRole,
                                    );
                                  } else {
                                    if (emailCtrl.text.trim().isEmpty || passCtrl.text.isEmpty) return;
                                    await adminData.addStaff(
                                      name: nameCtrl.text.trim(),
                                      email: emailCtrl.text.trim(),
                                      role: dbRole,
                                      department: deptCtrl.text.trim(),
                                      phone: phoneCtrl.text.trim(),
                                      password: passCtrl.text,
                                    );
                                  }
                                  if (context.mounted) {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(editingStaff != null ? 'Staff member updated!' : 'Staff member created!'),
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
                              child: Text(editingStaff != null ? 'Save Changes' : 'Add Staff'),
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

  void _showDeleteDialog(BuildContext context, UserModel staffMember) {
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
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Staff member removed.')),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext ctx, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Theme.of(ctx).textTheme.bodySmall?.color),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final adminData = context.watch<AdminDataProvider>();
    final auth = context.watch<AuthProvider>();
    final canEdit = auth.isAdmin;
    final staffList = adminData.staff;

    final filtered = staffList.where((s) {
      final q = _searchQuery.toLowerCase().trim();
      return s.name.toLowerCase().contains(q) ||
          s.email.toLowerCase().contains(q) ||
          (s.department?.toLowerCase().contains(q) ?? false);
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header (Staff Members & Add Button)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Staff Members',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${staffList.length} staff members',
                    style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                ],
              ),
              if (canEdit)
                ElevatedButton.icon(
                  onPressed: () => _showAddEditModal(context),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Staff'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),

          // 2. Search Bar
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search staff…',
              prefixIcon: Icon(Icons.search, size: 18),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          const SizedBox(height: 16),

          // 3. Table Container (bg-card border border-border rounded-2xl overflow-hidden)
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 64),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline, size: 40, color: Colors.grey.withValues(alpha: 0.3)),
                          const SizedBox(height: 8),
                          const Text('No staff members yet', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final double tableWidth = constraints.maxWidth > 780 ? constraints.maxWidth : 780;
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: tableWidth,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Table Header Row (bg-muted/40)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).brightness == Brightness.dark
                                      ? AppTheme.mutedDark.withValues(alpha: 0.5)
                                      : AppTheme.mutedLight.withValues(alpha: 0.5),
                                  border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
                                ),
                                child: const Row(
                                  children: [
                                    Expanded(flex: 3, child: Text('NAME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8))),
                                    Expanded(flex: 2, child: Text('DEPARTMENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8))),
                                    Expanded(flex: 2, child: Text('ROLE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8))),
                                    Expanded(flex: 2, child: Text('CONTACT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8))),
                                    Expanded(flex: 1, child: Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8))),
                                    SizedBox(width: 120, child: Text('ACTIONS', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8))),
                                  ],
                                ),
                              ),

                              // Table Body Rows
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => Divider(height: 1, color: Theme.of(context).dividerColor),
                                itemBuilder: (context, index) {
                                  final s = filtered[index];
                                  final isSuper = s.role == UserRole.superAdmin || s.role == UserRole.admin;
                                  final isActive = s.status == 'active';

                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    child: Row(
                                      children: [
                                        // 1. Name & Email + Avatar
                                        Expanded(
                                          flex: 3,
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 14,
                                                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                                                child: Text(
                                                  s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S',
                                                  style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 11),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis),
                                                    Text(s.email, style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color), overflow: TextOverflow.ellipsis),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // 2. Department
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            s.department?.isNotEmpty == true ? s.department! : '—',
                                            style: TextStyle(fontSize: 13, color: Theme.of(context).textTheme.bodySmall?.color),
                                          ),
                                        ),

                                        // 3. Role Pill Badge
                                        Expanded(
                                          flex: 2,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(
                                                color: isSuper
                                                    ? AppTheme.primaryColor.withValues(alpha: 0.12)
                                                    : AppTheme.accentColor.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    isSuper ? Icons.verified_user : Icons.shield_outlined,
                                                    size: 11,
                                                    color: isSuper ? AppTheme.primaryColor : AppTheme.accentColor,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    isSuper ? 'Super Admin' : 'Staff Admin',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: isSuper ? AppTheme.primaryColor : AppTheme.accentColor,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),

                                        // 4. Contact
                                        Expanded(
                                          flex: 2,
                                          child: Row(
                                            children: [
                                              Icon(Icons.phone_outlined, size: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                                              const SizedBox(width: 4),
                                              Text(
                                                s.phone?.isNotEmpty == true ? s.phone! : '—',
                                                style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // 5. Status
                                        Expanded(
                                          flex: 1,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isActive
                                                    ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                                    : Colors.grey.withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                s.status,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: isActive ? const Color(0xFF059669) : Colors.grey,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                        // 6. Actions
                                        SizedBox(
                                          width: 120,
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove_red_eye_outlined, size: 16),
                                                tooltip: 'View',
                                                splashRadius: 16,
                                                padding: const EdgeInsets.all(6),
                                                constraints: const BoxConstraints(),
                                                onPressed: () => _showViewModal(context, s, canEdit),
                                              ),
                                              if (canEdit) ...[
                                                const SizedBox(width: 4),
                                                IconButton(
                                                  icon: const Icon(Icons.edit_outlined, size: 16),
                                                  tooltip: 'Edit',
                                                  splashRadius: 16,
                                                  padding: const EdgeInsets.all(6),
                                                  constraints: const BoxConstraints(),
                                                  onPressed: () => _showAddEditModal(context, s),
                                                ),
                                                const SizedBox(width: 4),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.dangerColor),
                                                  tooltip: 'Delete',
                                                  splashRadius: 16,
                                                  padding: const EdgeInsets.all(6),
                                                  constraints: const BoxConstraints(),
                                                  onPressed: () => _showDeleteDialog(context, s),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
