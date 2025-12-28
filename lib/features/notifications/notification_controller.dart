import 'package:kitaid1/features/notifications/models/app_notification.dart';
import 'package:kitaid1/features/notifications/services/notification_service.dart';

class NotificationController {
  final NotificationService _service = NotificationService();

  Stream<List<AppNotification>> stream() => _service.streamAll();

  Future<List<AppNotification>> load() => _service.fetchAll();

  Future<void> markAllRead() => _service.markAllRead();

  Future<void> toggle(String id) => _service.toggleRead(id);

  Future<void> delete(String id) => _service.delete(id);
}
