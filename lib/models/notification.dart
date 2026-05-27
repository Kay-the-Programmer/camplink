enum NotificationType {
  orderPlaced,
  orderConfirmed,
  orderDelivered,
  orderCancelled,
  paymentConfirmed,
  message,
  requestAccepted,
  requestFulfilled,
  other,
}

NotificationType notifTypeFromString(String? s) {
  switch (s?.toUpperCase()) {
    case 'ORDER_PLACED':       return NotificationType.orderPlaced;
    case 'ORDER_CONFIRMED':    return NotificationType.orderConfirmed;
    case 'ORDER_DELIVERED':    return NotificationType.orderDelivered;
    case 'ORDER_CANCELLED':    return NotificationType.orderCancelled;
    case 'PAYMENT_CONFIRMED':  return NotificationType.paymentConfirmed;
    case 'MESSAGE':            return NotificationType.message;
    case 'REQUEST_ACCEPTED':   return NotificationType.requestAccepted;
    case 'REQUEST_FULFILLED':  return NotificationType.requestFulfilled;
    default:                   return NotificationType.other;
  }
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String? orderId;
  final bool read;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.orderId,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id:        j['id'] as String,
        type:      notifTypeFromString(j['type'] as String?),
        title:     j['title'] as String,
        body:      j['body'] as String? ?? '',
        orderId:   j['orderId'] as String?,
        read:      j['read'] as bool? ?? false,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}
