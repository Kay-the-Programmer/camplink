import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notification.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('notifications');

  Future<void> push({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    String? orderId,
  }) async {
    await _col.add(AppNotification(
      id: '',
      userId: userId,
      type: type,
      title: title,
      body: body,
      orderId: orderId,
      read: false,
      createdAt: DateTime.now(),
    ).toMap());
  }

  Stream<List<AppNotification>> streamForUser(String userId) => _col
      .where('userId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(AppNotification.fromDoc).toList());

  Stream<int> unreadCount(String userId) => _col
      .where('userId', isEqualTo: userId)
      .where('read', isEqualTo: false)
      .snapshots()
      .map((s) => s.docs.length);

  Future<void> markRead(String id) async {
    await _col.doc(id).update({'read': true});
  }

  Future<void> markAllRead(String userId) async {
    final batch = _db.batch();
    final snap = await _col
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();
    for (final d in snap.docs) {
      batch.update(d.reference, {'read': true});
    }
    await batch.commit();
  }
}
