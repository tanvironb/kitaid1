import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_notification.dart';

class NotificationService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid {
    final u = _auth.currentUser;
    if (u == null) throw Exception('User not logged in');
    return u.uid;
  }

  CollectionReference<Map<String, dynamic>> _col() {
    return _db.collection('Users').doc(_uid).collection('notifications');
  }

  /// Live stream (best for UI)
  Stream<List<AppNotification>> streamAll() {
    return _col()
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => _fromDoc(d)).toList());
  }

  /// One-time fetch (if you still want Future)
  Future<List<AppNotification>> fetchAll() async {
    final snap = await _col().orderBy('createdAt', descending: true).get();
    return snap.docs.map((d) => _fromDoc(d)).toList();
  }

  Future<void> markAllRead() async {
    final snap = await _col().where('read', isEqualTo: false).get();
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }

  Future<void> toggleRead(String id) async {
    final ref = _col().doc(id);
    await _db.runTransaction((tx) async {
      final doc = await tx.get(ref);
      if (!doc.exists) return;
      final cur = (doc.data()?['read'] as bool?) ?? false;
      tx.update(ref, {'read': !cur});
    });
  }

  Future<void> delete(String id) async {
    await _col().doc(id).delete();
  }

  AppNotification _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final ts = data['createdAt'];
    DateTime createdAt;

    if (ts is Timestamp) {
      createdAt = ts.toDate();
    } else if (ts is String) {
      createdAt = DateTime.tryParse(ts) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return AppNotification(
      id: doc.id,
      title: (data['title'] as String?) ?? '',
      body: data['body'] as String?,
      createdAt: createdAt,
      read: (data['read'] as bool?) ?? false,
      category: data['category'] as String?,
    );
  }
}
