enum NotificationType {
  orderPlaced,
  orderConfirmed,
  orderDelivered,
  orderCancelled,
  paymentConfirmed,
  message,
  requestAccepted,
  requestFulfilled,
  rideAccepted,
  rideCompleted,
  rideCancelled,
  accountApproved,
  accountRejected,
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
    case 'RIDE_ACCEPTED':      return NotificationType.rideAccepted;
    case 'RIDE_COMPLETED':     return NotificationType.rideCompleted;
    case 'RIDE_CANCELLED':     return NotificationType.rideCancelled;
    case 'ACCOUNT_APPROVED':   return NotificationType.accountApproved;
    case 'ACCOUNT_REJECTED':   return NotificationType.accountRejected;
    default:                   return NotificationType.other;
  }
}

/// Whether tapping this notification should open an order's detail screen.
bool notifOpensOrder(NotificationType t) {
  switch (t) {
    case NotificationType.orderPlaced:
    case NotificationType.orderConfirmed:
    case NotificationType.orderDelivered:
    case NotificationType.orderCancelled:
    case NotificationType.paymentConfirmed:
      return true;
    default:
      return false;
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
