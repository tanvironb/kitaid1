import 'package:flutter/material.dart';
import 'package:kitaid1/utilities/constant/color.dart';
import 'package:kitaid1/utilities/constant/sizes.dart';
import 'models/app_notification.dart';
import 'widgets/notification_item.dart';
import 'notification_controller.dart';

// To creates a stateful page, which means the screen can change over time

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final _controller = NotificationController();
  late Future<List<AppNotification>> _future;

  // search + filter option  

  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _showUnreadOnly = false;

/* - it loads notifications from the controller 
   - It listens to typing in the search box and updates _query so results update instantly
*/

  @override
  void initState() {
    super.initState();
    _future = _controller.load();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim());
    });
  }

// Cleans up memory when leaving the page by disposing the search controller

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

// Reloads the notifications list - refresh function

  Future<void> _refresh() async {
    setState(() {
      _future = _controller.load();
    });
    await _future;
  }


  List<AppNotification> _applyFilters(List<AppNotification> items) {
    Iterable<AppNotification> filtered = items;

    // Filter: unread only (if toggled)
    if (_showUnreadOnly) {
      filtered = filtered.where((n) => !n.read);
    }

    // Filter: search by name/title (case-insensitive) - shows results matching title, body, or category
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      filtered = filtered.where((n) {
        final inTitle = n.title.toLowerCase().contains(q);
        final inBody = (n.body ?? '').toLowerCase().contains(q);
        final inCategory = (n.category ?? '').toLowerCase().contains(q);
        return inTitle || inBody || inCategory;
      });
    }

    return filtered.toList();
  }

// The main build method for the notification page: theme, colors. fonts...
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

// AppBar the top bar with page title
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification'),
      actions: [
        IconButton(
          tooltip: 'Mark all as read',
          icon: const Icon(Icons.done_all_outlined),
          onPressed: () async {
            // Marks all notifications as read
            await _controller.markAllRead();
              if (mounted) _refresh(); // Reloads the list with updated colors
      },
    ),
  ],
),


// Body with refresh indicator and future builder to load notifications
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<AppNotification>>(
          future: _future,
          builder: (context, snapshot) {
            // Shows a spinner while waiting for data, or an error message if loading fails.
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text('Failed to load notifications'));
            }

            // Gets the list of notifications and filters them by search/unread selection
            final allItems = snapshot.data ?? [];
            final items = _applyFilters(allItems);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                // Title 
                Text(
                  'Notification',
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),

                // SEARCH FIELD bar (rounded)
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search',
                  prefixIcon: const Icon(Icons.search, color: mycolors.bordersecondary),
                  filled: true,
                  fillColor: mycolors.bgPrimary, // white background
                  hintStyle: const TextStyle(color: mycolors.textPrimary), // black text
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(mysizes.inputfieldRadius),
                    borderSide: const BorderSide(color: mycolors.borderprimary, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(mysizes.inputfieldRadius),
                    borderSide: const BorderSide(color: mycolors.Primary, width: 2),
                  ),
                ),
                style: const TextStyle(color: mycolors.textPrimary),
              ),

                const SizedBox(height: 12),

                /* 
                  These are your All / Unread toggle chips.
                  They let the user switch views between all notifications or only unread ones 
                */
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: !_showUnreadOnly,
                      onSelected: (v) => setState(() => _showUnreadOnly = !v),
                      // Give "All" a filled look when selected
                      selectedColor: mycolors.Primary,
                      labelStyle: TextStyle(
                        color: !_showUnreadOnly ? theme.colorScheme.onPrimary : null,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('Unread'),
                      selected: _showUnreadOnly,
                      onSelected: (v) => setState(() => _showUnreadOnly = v),
                      selectedColor: mycolors.Primary,
                      labelStyle: TextStyle(
                        color: _showUnreadOnly ? mycolors.textinbox : mycolors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

              // This block shows a friendly message and icon when there are no results (after search/filter)
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 64, color: theme.hintColor),
                        const SizedBox(height: 12),
                        Text('No notifications found', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          _query.isEmpty
                              ? 'You’re all caught up. Pull to refresh.'
                              : 'Try clearing the search or filters.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  // Results - Displays the list of notifications 
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final n = items[index];
                      return NotificationItem(
                        data: n,
                        // darker for unread, lighter for read — handled in the item widget
                        onToggleRead: () async {
                          await _controller.toggle(n.id);
                          if (mounted) _refresh();
                        },
                        onDelete: () async {
                          await _controller.delete(n.id);
                          if (mounted) _refresh();
                        },
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
