import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_data_provider.dart';
import '../../models/school_model.dart';
import '../../theme/app_theme.dart';

class AdminSchoolsPage extends StatefulWidget {
  const AdminSchoolsPage({super.key});

  @override
  State<AdminSchoolsPage> createState() => _AdminSchoolsPageState();
}

class _AdminSchoolsPageState extends State<AdminSchoolsPage> {
  String _searchQuery = '';
  String _typeFilter = 'all';

  void _showAddEditSchoolDialog([SchoolModel? existingSchool]) {
    final isEdit = existingSchool != null;
    final nameCtrl = TextEditingController(text: existingSchool?.name ?? '');
    final locCtrl = TextEditingController(text: existingSchool?.location ?? '');
    final typeCtrl = TextEditingController(text: existingSchool?.type ?? 'Secondary');
    final studentsCtrl = TextEditingController(text: existingSchool?.students.toString() ?? '0');
    final mottoCtrl = TextEditingController(text: existingSchool?.motto ?? '');
    final principalCtrl = TextEditingController(text: existingSchool?.principal ?? '');
    final phoneCtrl = TextEditingController(text: existingSchool?.phone ?? '');
    final emailCtrl = TextEditingController(text: existingSchool?.email ?? '');
    final estCtrl = TextEditingController(text: existingSchool?.established.toString() ?? '2024');
    final descCtrl = TextEditingController(text: existingSchool?.description ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit School Institution' : 'Register New Institution'),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'School Name *')),
                const SizedBox(height: 10),
                TextField(controller: locCtrl, decoration: const InputDecoration(labelText: 'Location / County *')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Type (e.g. Secondary)'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: studentsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Student Count'))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: mottoCtrl, decoration: const InputDecoration(labelText: 'Motto / Slogan')),
                const SizedBox(height: 10),
                TextField(controller: principalCtrl, decoration: const InputDecoration(labelText: 'Principal / Headteacher')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address'))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: estCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Established Year')),
                const SizedBox(height: 10),
                TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description / Notes')),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;

              final adminData = context.read<AdminDataProvider>();
              if (isEdit) {
                await adminData.updateSchool(existingSchool.id, {
                  'name': nameCtrl.text.trim(),
                  'location': locCtrl.text.trim(),
                  'type': typeCtrl.text.trim(),
                  'students': int.tryParse(studentsCtrl.text) ?? 0,
                  'motto': mottoCtrl.text.trim(),
                  'principal': principalCtrl.text.trim(),
                  'phone': phoneCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                  'established': int.tryParse(estCtrl.text) ?? 2024,
                  'description': descCtrl.text.trim(),
                });
              } else {
                final newSchool = SchoolModel(
                  id: '',
                  name: nameCtrl.text.trim(),
                  location: locCtrl.text.trim(),
                  type: typeCtrl.text.trim().isNotEmpty ? typeCtrl.text.trim() : 'Secondary',
                  students: int.tryParse(studentsCtrl.text) ?? 0,
                  motto: mottoCtrl.text.trim(),
                  principal: principalCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  established: int.tryParse(estCtrl.text) ?? 2024,
                  description: descCtrl.text.trim(),
                );
                await adminData.addSchool(newSchool);
              }

              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isEdit ? 'School updated!' : 'School registered successfully!'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
            },
            child: Text(isEdit ? 'Save Changes' : 'Create School'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(SchoolModel school) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete School?'),
        content: Text('Are you sure you want to remove ${school.name}? This will affect records and assignments associated with this institution.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            onPressed: () async {
              await context.read<AdminDataProvider>().deleteSchool(school.id);
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('School deleted.')),
                );
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
    final schools = adminData.schools;

    final filtered = schools.where((s) {
      final q = _searchQuery.toLowerCase().trim();
      final matchesQuery = s.name.toLowerCase().contains(q) ||
          s.location.toLowerCase().contains(q) ||
          (s.principal?.toLowerCase().contains(q) ?? false);
      if (!matchesQuery) return false;
      if (_typeFilter != 'all' && s.type.toLowerCase() != _typeFilter.toLowerCase()) return false;
      return true;
    }).toList();

    final allTypes = schools.map((s) => s.type).toSet().toList();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Controls
            Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by school name, location, or principal...',
                      prefixIcon: Icon(Icons.search, size: 20),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _typeFilter,
                  items: [
                    const DropdownMenuItem(value: 'all', child: Text('All Types')),
                    ...allTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))),
                  ],
                  onChanged: (val) => setState(() => _typeFilter = val ?? 'all'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showAddEditSchoolDialog(),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add School'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Schools Grid / List
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text('No schools registered or found matching query.', style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.separated(
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final s = filtered[index];

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
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.school, color: AppTheme.accentColor, size: 22),
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
                                            color: AppTheme.primaryColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            s.type,
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${s.location} • ${s.students} Students • Principal: ${s.principal ?? "N/A"} • Est. ${s.established}',
                                      style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                                    ),
                                    if (s.motto != null && s.motto!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          '"${s.motto}"',
                                          style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                tooltip: 'Edit',
                                onPressed: () => _showAddEditSchoolDialog(s),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.dangerColor),
                                tooltip: 'Delete',
                                onPressed: () => _showDeleteConfirmation(s),
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
