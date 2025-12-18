import 'package:flutter/material.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';
import '../models/app_notification.dart';

/* 
  Creates a reusable widget that displays one notification card.
  It takes three parameters:

  - data → notification info (title, body, etc.)

  - onToggleRead → what happens when the user taps it

  - onDelete → what happens when the user chooses delete
*/
class NotificationItem extends StatelessWidget {
  const NotificationItem({
    super.key,
    required this.data,
    required this.onToggleRead,
    required this.onDelete,
  });

// Defines the inputs for this widget 
  final AppNotification data;
  final VoidCallback onToggleRead;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // COLOR RULE:
    // - Unread  -> darker box  (use secondaryContainer or a deeper grey)
    // - Read    -> lighter box (use surfaceVariant)
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
      /* 
        Material + InkWell = ripple touch effect.
        When tapped → triggers the onToggleRead function (to mark read/unread)
      */
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: data.read ? null : onToggleRead,
          borderRadius: BorderRadius.circular(16),
          // Adds spacing and places everything in a horizontal row
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // create the leading icon with a person icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_2_outlined, size: 22),
                ),
                const SizedBox(width: 12),

                // Texts
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title 
                      Text(data.title, style: titleStyle, maxLines: 1, overflow: TextOverflow.ellipsis),

                      const SizedBox(height: 4),

                      // Body
                      if (data.body != null && data.body!.isNotEmpty)
                        Text(
                          data.body!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: mysizes.fontSm,
                                  fontWeight: FontWeight.w400)
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // The three-dot menu on the right: Options to mark as read/unread or delete the notification
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
