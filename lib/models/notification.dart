import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType {
  orderPlaced,
  orderConfirmed,
  orderDelivered,
  orderCancelled,
  paymentConfirmed,
  message,
  other,
}

NotificationType notifTypeFromString(String? s) {
  return NotificationType.values.firstWhere(
    (t) => t.name == s,
    orElse: () => NotificationType.other,
  );
}

class AppNotification {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final String? orderId;
  final bool read;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.orderId,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppNotification(
      id: doc.id,
      userId: d['userId'] ?? '',
      type: notifTypeFromString(d['type']),
      title: d['title'] ?? '',
      body: d['body'] ?? '',
      orderId: d['orderId'],
      read: d['read'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'type': type.name,
        'title': title,
        'body': body,
        'orderId': orderId,
        'read': read,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
