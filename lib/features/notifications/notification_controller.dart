
import 'package:kitaid1/features/notifications/models/app_notification.dart';
import 'package:kitaid1/features/notifications/services/notification_service.dart';


class NotificationController {
  final NotificationService _service = NotificationService();

  // Loads all notifications from the service
  Future<List<AppNotification>> load() => _service.fetchAll();
  // Marks every notification as read (called when user taps “Mark all as read”)
  Future<void> markAllRead() => _service.markAllRead();
  // Flips a single notification’s read/unread state
  Future<void> toggle(String id) => _service.toggleRead(id);
  // Deletes a notification
  Future<void> delete(String id) => _service.delete(id);
}
