import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final _local = FlutterLocalNotificationsPlugin();

Future<void> initLocalNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const settings = InitializationSettings(android: android);
  await _local.initialize(settings);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    final title = message.notification?.title ?? 'KitaID';
    final body = message.notification?.body ?? '';

    const androidDetails = AndroidNotificationDetails(
      'kitaid_channel',
      'KitaID Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );

    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  });
}
