
import 'dart:async';
import '../models/app_notification.dart';

class NotificationService {
  // Creates some fake notifications to display (in a real app, this would come from Firebase)
  final List<AppNotification> _seed = List.generate(
    10,
    (i) => AppNotification(
      id: 'n$i',
      title: i == 0 ? 'Welcome to KitaID' : 'Update #$i',
      body: i == 0 ? 'Thanks for joining. Your account is ready.' : 'Some details about update #$i.',
      createdAt: DateTime.now().subtract(Duration(minutes: i * 13)),
      read: i % 3 == 0,
      category: i == 0 ? 'system' : 'updates',
    ),
  );

  // Simulates loading all notifications (with a short delay) and sorts them by newest first
  Future<List<AppNotification>> fetchAll() async {
    await Future.delayed(const Duration(milliseconds: 300));
    final list = [..._seed]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }
  
  // Marks all notification as read
  Future<void> markAllRead() async {
    await Future.delayed(const Duration(milliseconds: 150));
    for (var i = 0; i < _seed.length; i++) {
      _seed[i] = _seed[i].copyWith(read: true);
    }
  }

  // Finds one item by ID and toggles its read status (from true → false or vice versa)
  Future<void> toggleRead(String id) async {
    await Future.delayed(const Duration(milliseconds: 120));
    final idx = _seed.indexWhere((e) => e.id == id);
    if (idx != -1) {
      final cur = _seed[idx];
      _seed[idx] = cur.copyWith(read: !cur.read);
    }
  }

  // Removes a notification from the list by its ID
  Future<void> delete(String id) async {
    await Future.delayed(const Duration(milliseconds: 120));
    _seed.removeWhere((e) => e.id == id);
  }
}
