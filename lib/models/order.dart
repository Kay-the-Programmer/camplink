enum OrderStatus { pending, confirmed, delivered, cancelled }
enum DeliveryMethod { delivery, pickup }
enum PaymentMethod { cashOnDelivery, mtnMomo, airtelMoney, zamtelKwacha }
enum PaymentStatus { unpaid, paid }

OrderStatus orderStatusFromString(String? s) {
  switch (s?.toUpperCase()) {
    case 'CONFIRMED': return OrderStatus.confirmed;
    case 'DELIVERED': return OrderStatus.delivered;
    case 'CANCELLED': return OrderStatus.cancelled;
    default:          return OrderStatus.pending;
  }
}

String orderStatusToApi(OrderStatus s) => s.name.toUpperCase();

DeliveryMethod deliveryMethodFromString(String? s) =>
    s?.toUpperCase() == 'PICKUP' ? DeliveryMethod.pickup : DeliveryMethod.delivery;

String deliveryMethodToApi(DeliveryMethod m) => m.name.toUpperCase();

PaymentMethod paymentMethodFromString(String? s) {
  switch (s?.toUpperCase()) {
    case 'MTN_MOMO':       return PaymentMethod.mtnMomo;
    case 'AIRTEL_MONEY':   return PaymentMethod.airtelMoney;
    case 'ZAMTEL_KWACHA':  return PaymentMethod.zamtelKwacha;
    default:               return PaymentMethod.cashOnDelivery;
  }
}

String paymentMethodToApi(PaymentMethod m) {
  switch (m) {
    case PaymentMethod.cashOnDelivery: return 'CASH_ON_DELIVERY';
    case PaymentMethod.mtnMomo:        return 'MTN_MOMO';
    case PaymentMethod.airtelMoney:    return 'AIRTEL_MONEY';
    case PaymentMethod.zamtelKwacha:   return 'ZAMTEL_KWACHA';
  }
}

String paymentMethodLabel(PaymentMethod m) {
  switch (m) {
    case PaymentMethod.cashOnDelivery: return 'Cash on Delivery';
    case PaymentMethod.mtnMomo:        return 'MTN MoMo';
    case PaymentMethod.airtelMoney:    return 'Airtel Money';
    case PaymentMethod.zamtelKwacha:   return 'Zamtel Kwacha';
  }
}

PaymentStatus paymentStatusFromString(String? s) =>
    s?.toUpperCase() == 'PAID' ? PaymentStatus.paid : PaymentStatus.unpaid;

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

  factory OrderLine.fromJson(Map<String, dynamic> j) => OrderLine(
        productId: j['productId'] as String,
        name:      j['productName'] as String,
        price:     (j['price'] as num).toDouble(),
        quantity:  j['quantity'] as int,
        sellerId:  '',
      );

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'name':      name,
        'price':     price,
        'quantity':  quantity,
        'sellerId':  sellerId,
      };
}

class AppOrder {
  final String id;
  final String buyerId;
  final String buyerName;
  final String buyerPhone;
  final String sellerId;
  final String sellerName;
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
    required this.sellerName,
    required this.items,
    required this.total,
    required this.status,
    required this.deliveryMethod,
    required this.deliveryLocation,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.createdAt,
  });

  factory AppOrder.fromJson(Map<String, dynamic> j) => AppOrder(
        id:               j['id'] as String,
        buyerId:          j['buyerId'] as String,
        buyerName:        j['buyerName'] as String,
        buyerPhone:       j['buyerPhone'] as String? ?? '',
        sellerId:         j['sellerId'] as String,
        sellerName:       j['sellerName'] as String? ?? '',
        items:            (j['items'] as List)
            .map((e) => OrderLine.fromJson(e as Map<String, dynamic>))
            .toList(),
        total:            (j['total'] as num).toDouble(),
        status:           orderStatusFromString(j['status'] as String?),
        deliveryMethod:   deliveryMethodFromString(j['deliveryMethod'] as String?),
        deliveryLocation: j['deliveryLocation'] as String? ?? '',
        paymentMethod:    paymentMethodFromString(j['paymentMethod'] as String?),
        paymentStatus:    paymentStatusFromString(j['paymentStatus'] as String?),
        createdAt:        DateTime.parse(j['createdAt'] as String),
      );
}
