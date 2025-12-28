import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> setupPushNotifications() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final messaging = FirebaseMessaging.instance;

  // iOS permission (Android 13+ will also ask)
  await messaging.requestPermission(alert: true, badge: true, sound: true);

  // Get token
  final token = await messaging.getToken();
  if (token != null) {
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }

  // Keep token updated
  FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
    await FirebaseFirestore.instance
        .collection('Users')
        .doc(user.uid)
        .set({'fcmToken': newToken}, SetOptions(merge: true));
  });
}
