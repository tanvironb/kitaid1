import 'package:flutter/material.dart';
import 'package:kitaid1/common/widgets/nav/kita_bottom_nav.dart';
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

  @override
  void initState() {
    super.initState();
    _future = _controller.load();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim());
    });
  }

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

    // Filter: search by name/title (case-insensitive)
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // ===== APP BAR (same style as Settings header) =====
      appBar: AppBar(
        backgroundColor: mycolors.Primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
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
                // === SEARCH FIELD (rounded) ===
                TextField(
  controller: _searchCtrl,
  style: const TextStyle(
    color: mycolors.textPrimary,
    fontSize: 13, // ✅ smaller typed text
  ),
  decoration: InputDecoration(
    hintText: 'Search',
    hintStyle: const TextStyle(
      fontSize: 12, // ✅ smaller hint text
      color: mycolors.textSecondary, // ✅ change hint color
    ),
    prefixIcon: const Icon(
      Icons.search,
      size: 18, // ✅ smaller icon
      color: mycolors.textSecondary,
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 8, // ✅ reduces height
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20), // slightly smaller radius
      borderSide: const BorderSide(
        color: mycolors.borderprimary,
        width: 1.2,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(
        color: mycolors.Primary,
        width: 1.5,
      ),
    ),
  ),
),


                const SizedBox(height: 12),

                // All / Unread toggle chips
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('All',
                      style: TextStyle(
                          fontSize: 12,
                        ),),
                      selected: !_showUnreadOnly,
                      onSelected: (v) => setState(() => _showUnreadOnly = !v),
                      selectedColor: mycolors.Primary,
                      labelStyle: TextStyle(
                        color: !_showUnreadOnly
                            ? theme.colorScheme.onPrimary
                            : null,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text(
                        'Unread',
                        style: TextStyle(
                          fontSize: 12,
                        ),
                        ),
                      selected: _showUnreadOnly,
                      onSelected: (v) => setState(() => _showUnreadOnly = v),
                      selectedColor: mycolors.Primary,
                      labelStyle: TextStyle(
                        color: _showUnreadOnly
                            ? mycolors.textinbox
                            : mycolors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Empty state
                if (items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 64,
                          color: theme.hintColor,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No notifications found',
                          style: theme.textTheme.bodyMedium?.copyWith(
                                    fontSize: 13, // 🔽 smaller
                                    fontWeight: FontWeight.w600,
                                  ),
                          
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _query.isEmpty
                              ? 'You’re all caught up. Pull to refresh.'
                              : 'Try clearing the search or filters.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  // Results list
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final n = items[index];
                      return NotificationItem(
                        data: n,
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

      // ===== OFFICIAL KITAID NAVBAR =====
      bottomNavigationBar: KitaBottomNav(
        currentIndex: 3, // <-- change this per page
        onTap: (index) {
          if (index == 3) return; // already on this page

          switch (index) {
            case 0: // HOME
              Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
              break;

            case 1: // CHATBOT
              Navigator.pushNamedAndRemoveUntil(context, '/chatbot', (_) => false);
              break;

            case 2: // SERVICES
              Navigator.pushNamedAndRemoveUntil(context, '/services', (_) => false);
              break;

            case 3: // NOTIFICATIONS
              Navigator.pushNamedAndRemoveUntil(context, '/notifications', (_) => false);
              break;

            case 4: // PROFILE
              Navigator.pushNamedAndRemoveUntil(context, '/profile', (_) => false);
              break;
          }
        },
      ),
    );
  }
}
