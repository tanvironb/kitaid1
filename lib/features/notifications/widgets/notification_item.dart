import 'package:flutter/material.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';
import '../models/app_notification.dart';

class NotificationItem extends StatelessWidget {
  const NotificationItem({
    super.key,
    required this.data,
    required this.onToggleRead,
    required this.onDelete,
  });

  final AppNotification data;
  final VoidCallback onToggleRead;
  final VoidCallback onDelete;

  // ✅ Icon depends on category (only change for icons)
  IconData _iconForCategory(String? category) {
    final c = (category ?? '').toLowerCase();
    if (c.contains('immigration')) return Icons.badge_outlined;
    if (c.contains('security')) return Icons.security_outlined;
    if (c.contains('service')) return Icons.miscellaneous_services_outlined;
    if (c.contains('system')) return Icons.info_outline;
    return Icons.notifications_none_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // ✅ KEEP your original color rule EXACTLY
    final Color bg = data.read
        ? const Color.fromARGB(255, 240, 240, 240)  // lighter gray for read
        : const Color.fromARGB(255, 197, 197, 197); // darker gray for unread

    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontSize: mysizes.fontMd,
      fontWeight: data.read ? FontWeight.w600 : FontWeight.w800,
    );

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: data.read ? null : onToggleRead, // ✅ keep same behavior
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ✅ leading icon (same circle style, icon depends on category)
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_iconForCategory(data.category), size: 22),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title (unchanged: still 1 line)
                      Text(
                        data.title,
                        style: titleStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      const SizedBox(height: 4),

                      // ✅ Body: FULL message (same page)
                      if (data.body != null && data.body!.isNotEmpty)
                        Text(
                          data.body!,
                          softWrap: true,
                          // ❌ removed maxLines/ellipsis to show full text
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: mysizes.fontSm,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'toggle') onToggleRead();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle',
                      child: Text(data.read ? 'Mark as unread' : 'Mark as read'),
                    ),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
