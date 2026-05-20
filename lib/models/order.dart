import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus { pending, confirmed, delivered, cancelled }

OrderStatus orderStatusFromString(String? s) {
  switch (s) {
    case 'confirmed':
      return OrderStatus.confirmed;
    case 'delivered':
      return OrderStatus.delivered;
    case 'cancelled':
      return OrderStatus.cancelled;
    default:
      return OrderStatus.pending;
  }
}

enum DeliveryMethod { delivery, pickup }

enum PaymentMethod { cashOnDelivery, mtnMomo, airtelMoney, zamtelKwacha }

enum PaymentStatus { unpaid, paid }

String paymentMethodLabel(PaymentMethod m) {
  switch (m) {
    case PaymentMethod.cashOnDelivery:
      return 'Cash on Delivery';
    case PaymentMethod.mtnMomo:
      return 'MTN MoMo';
    case PaymentMethod.airtelMoney:
      return 'Airtel Money';
    case PaymentMethod.zamtelKwacha:
      return 'Zamtel Kwacha';
  }
}

class OrderLine {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String sellerId;

  OrderLine({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.sellerId,
  });

  factory OrderLine.fromMap(Map<String, dynamic> m) => OrderLine(
        productId: m['productId'] ?? '',
        name: m['name'] ?? '',
        price: (m['price'] as num?)?.toDouble() ?? 0,
        quantity: (m['quantity'] as num?)?.toInt() ?? 1,
        sellerId: m['sellerId'] ?? '',
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name': name,
        'price': price,
        'quantity': quantity,
        'sellerId': sellerId,
      };
}

class AppOrder {
  final String id;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final String sellerId;
  final List<OrderLine> items;
  final double total;
  final OrderStatus status;
  final DeliveryMethod deliveryMethod;
  final String deliveryLocation;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final DateTime createdAt;

  AppOrder({
    required this.id,
    required this.buyerId,
    required this.buyerName,
    required this.buyerPhone,
    required this.sellerId,
    required this.items,
    required this.total,
    required this.status,
    required this.deliveryMethod,
    required this.deliveryLocation,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
  });

  factory AppOrder.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppOrder(
      id: doc.id,
      buyerId: d['buyerId'] ?? '',
      buyerName: d['buyerName'] ?? '',
      buyerPhone: d['buyerPhone'] ?? '',
      sellerId: d['sellerId'] ?? '',
      items: ((d['items'] as List?) ?? [])
          .map((e) => OrderLine.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      total: (d['total'] as num?)?.toDouble() ?? 0,
      status: orderStatusFromString(d['status']),
      deliveryMethod: d['deliveryMethod'] == 'pickup'
          ? DeliveryMethod.pickup
          : DeliveryMethod.delivery,
      deliveryLocation: d['deliveryLocation'] ?? '',
      paymentMethod: PaymentMethod.values.firstWhere(
        (m) => m.name == d['paymentMethod'],
        orElse: () => PaymentMethod.cashOnDelivery,
      ),
      paymentStatus:
          d['paymentStatus'] == 'paid' ? PaymentStatus.paid : PaymentStatus.unpaid,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'buyerId': buyerId,
        'buyerName': buyerName,
        'buyerPhone': buyerPhone,
        'sellerId': sellerId,
        'items': items.map((e) => e.toMap()).toList(),
        'total': total,
        'status': status.name,
        'deliveryMethod': deliveryMethod.name,
        'deliveryLocation': deliveryLocation,
        'paymentMethod': paymentMethod.name,
        'paymentStatus': paymentStatus.name,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
