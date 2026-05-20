import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/notification.dart';
import '../models/order.dart';
import 'notification_service.dart';

final _kwacha = NumberFormat.currency(locale: 'en_ZM', symbol: 'K', decimalDigits: 2);

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notif = NotificationService();

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('orders');

  Future<String> place(AppOrder order) async {
    final ref = await _col.add(order.toMap());
    // Notify seller
    await _notif.push(
      userId: order.sellerId,
      type: NotificationType.orderPlaced,
      title: 'New order from ${order.buyerName}',
      body: '${order.items.length} item(s) · ${_kwacha.format(order.total)}',
      orderId: ref.id,
    );
    return ref.id;
  }

  Stream<List<AppOrder>> streamForBuyer(String buyerId) => _col
      .where('buyerId', isEqualTo: buyerId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(AppOrder.fromDoc).toList());

  Stream<List<AppOrder>> streamForSeller(String sellerId) => _col
      .where('sellerId', isEqualTo: sellerId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(AppOrder.fromDoc).toList());

  Stream<List<AppOrder>> streamAll() => _col
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(AppOrder.fromDoc).toList());

  Future<void> updateStatus(String orderId, OrderStatus status) async {
    await _col.doc(orderId).update({'status': status.name});
    // Notify buyer
    final snap = await _col.doc(orderId).get();
    if (!snap.exists) return;
    final order = AppOrder.fromDoc(snap);
    NotificationType type;
    String title;
    switch (status) {
      case OrderStatus.confirmed:
        type = NotificationType.orderConfirmed;
        title = 'Order confirmed';
        break;
      case OrderStatus.delivered:
        type = NotificationType.orderDelivered;
        title = 'Order delivered';
        break;
      case OrderStatus.cancelled:
        type = NotificationType.orderCancelled;
        title = 'Order cancelled';
        break;
      case OrderStatus.pending:
        return;
    }
    await _notif.push(
      userId: order.buyerId,
      type: type,
      title: title,
      body: '${order.items.length} item(s) · ${_kwacha.format(order.total)}',
      orderId: orderId,
    );
  }

  Future<void> markPaid(String orderId) async {
    await _col.doc(orderId).update({'paymentStatus': PaymentStatus.paid.name});
    final snap = await _col.doc(orderId).get();
    if (!snap.exists) return;
    final order = AppOrder.fromDoc(snap);
    await _notif.push(
      userId: order.buyerId,
      type: NotificationType.paymentConfirmed,
      title: 'Payment confirmed',
      body: 'Your payment of ${_kwacha.format(order.total)} was confirmed.',
      orderId: orderId,
    );
  }
}
