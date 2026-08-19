import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/school_provider.dart';
import '../theme/app_theme.dart';

class SchoolSwitcherModal extends StatefulWidget {
  const SchoolSwitcherModal({super.key});

  @override
  State<SchoolSwitcherModal> createState() => _SchoolSwitcherModalState();
}

class _SchoolSwitcherModalState extends State<SchoolSwitcherModal> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final schoolProvider = context.watch<SchoolProvider>();
    final schools = schoolProvider.schools;
    final activeSchool = schoolProvider.activeSchool;

    final filtered = schools.where((s) {
      final query = _searchQuery.toLowerCase().trim();
      return s.name.toLowerCase().contains(query) ||
          s.location.toLowerCase().contains(query);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Switch Active School',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Search schools by name or location...',
              prefixIcon: Icon(Icons.search, size: 20),
            ),
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: filtered.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('No schools found matching your search.'),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final school = filtered[index];
                      final isSelected = activeSchool?.id == school.id;

                      return InkWell(
                        onTap: () {
                          schoolProvider.setActiveSchool(school);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor.withOpacity(0.08)
                                : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Theme.of(context).dividerColor,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : AppTheme.accentColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.school_outlined,
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.accentColor,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      school.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: isSelected
                                            ? AppTheme.primaryColor
                                            : null,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${school.location} • ${school.students} Students',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.color,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: AppTheme.primaryColor,
                                  size: 22,
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
