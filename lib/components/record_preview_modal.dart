import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/record_model.dart';
import '../theme/app_theme.dart';

class RecordPreviewModal extends StatelessWidget {
  final RecordModel record;
  final String? schoolName;
  final VoidCallback? onEdit;
  final VoidCallback? onDeleteRequest;

  const RecordPreviewModal({
    super.key,
    required this.record,
    this.schoolName,
    this.onEdit,
    this.onDeleteRequest,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = record.createdAt != null
        ? DateFormat('EEEE, MMMM d, y • h:mm a').format(record.createdAt!)
        : 'Date unavailable';

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          record.formType.displayName.toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: record.synced
                              ? AppTheme.successColor.withValues(alpha: 0.12)
                              : AppTheme.warningColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              record.synced ? Icons.cloud_done : Icons.cloud_off,
                              size: 12,
                              color: record.synced ? AppTheme.successColor : AppTheme.warningColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              record.synced ? 'Synced' : 'Offline Cache',
                              style: TextStyle(
                                color: record.synced ? AppTheme.successColor : AppTheme.warningColor,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    schoolName ?? 'School Record',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    dateStr,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Submitted Data Values',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...record.data.entries.map((entry) {
                    final key = entry.key;
                    final val = entry.value;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 4,
                            child: Text(
                              key,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 5,
                            child: _renderFieldValue(val),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (onEdit != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      onEdit!();
                    },
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit Record'),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              if (onDeleteRequest != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.dangerColor,
                      side: const BorderSide(color: AppTheme.dangerColor),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      onDeleteRequest!();
                    },
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Request Deletion'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _renderFieldValue(dynamic val) {
    if (val == null) return const Text('—', style: TextStyle(color: Colors.grey));
    if (val is bool) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: val ? AppTheme.successColor.withOpacity(0.15) : Colors.grey.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          val ? 'Yes' : 'No',
          style: TextStyle(
            color: val ? AppTheme.successColor : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }
    return Text(
      val.toString(),
      style: const TextStyle(fontSize: 13),
    );
  }
}
