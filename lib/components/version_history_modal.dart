import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/record_model.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class VersionHistoryModal extends StatefulWidget {
  final String recordId;

  const VersionHistoryModal({super.key, required this.recordId});

  @override
  State<VersionHistoryModal> createState() => _VersionHistoryModalState();
}

class _VersionHistoryModalState extends State<VersionHistoryModal> {
  final FirestoreService _firestoreService = FirestoreService();
  List<RecordVersionModel> _versions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVersions();
  }

  Future<void> _loadVersions() async {
    try {
      final list = await _firestoreService.fetchRecordVersions(widget.recordId);
      setState(() {
        _versions = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                'Version History & Audit Log',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Flexible(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _versions.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 36),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.history, size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('No historical revisions recorded for this record.'),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _versions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final ver = _versions[index];
                          final dateStr = ver.createdAt != null
                              ? DateFormat('MMM d, y • h:mm a').format(ver.createdAt!)
                              : '';

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Theme.of(context).dividerColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppTheme.accentColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Version ${ver.versionNumber}',
                                        style: const TextStyle(
                                          color: AppTheme.accentColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      dateStr,
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Reason: ${ver.editReason}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Edited by: ${ver.editedBy}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Divider(),
                                const SizedBox(height: 4),
                                ...ver.data.entries.map((entry) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      children: [
                                        Text(
                                          '${entry.key}: ',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          entry.value.toString(),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
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
