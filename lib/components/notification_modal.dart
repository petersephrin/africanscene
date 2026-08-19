import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/school_provider.dart';
import '../theme/app_theme.dart';

class NotificationModal extends StatelessWidget {
  const NotificationModal({super.key});

  @override
  Widget build(BuildContext context) {
    final schoolProvider = context.watch<SchoolProvider>();
    final notifs = schoolProvider.notifications;

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
              Row(
                children: [
                  const Text(
                    'Notifications',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (notifs.where((n) => !n.read).isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${notifs.where((n) => !n.read).length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Flexible(
            child: notifs.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_none_outlined, size: 40, color: Colors.grey),
                          SizedBox(height: 8),
                          Text('No notifications yet'),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: notifs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final n = notifs[index];
                      final dateStr = n.createdAt != null
                          ? DateFormat('MMM d, h:mm a').format(n.createdAt!)
                          : '';

                      return InkWell(
                        onTap: () {
                          if (!n.read) schoolProvider.markNotificationRead(n.id);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: n.read
                                ? Theme.of(context).cardColor
                                : AppTheme.primaryColor.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: n.read
                                  ? Theme.of(context).dividerColor
                                  : AppTheme.primaryColor.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: n.read
                                      ? Colors.grey.withOpacity(0.1)
                                      : AppTheme.primaryColor.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.notifications_outlined,
                                  color: n.read ? Colors.grey : AppTheme.primaryColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          n.title,
                                          style: TextStyle(
                                            fontWeight: n.read ? FontWeight.w500 : FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                        Text(
                                          dateStr,
                                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      n.message,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Theme.of(context).textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                  ],
                                ),
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
