enum RequestStatus { open, accepted, fulfilled, cancelled }

RequestStatus requestStatusFromString(String? s) {
  switch (s?.toUpperCase()) {
    case 'ACCEPTED':  return RequestStatus.accepted;
    case 'FULFILLED': return RequestStatus.fulfilled;
    case 'CANCELLED': return RequestStatus.cancelled;
    default:          return RequestStatus.open;
  }
}

class ShoppingRequestItem {
  final String name;
  final int quantity;
  final double? estimatedPrice;
  final String? notes;

  ShoppingRequestItem({
    required this.name,
    required this.quantity,
    this.estimatedPrice,
    this.notes,
  });

  factory ShoppingRequestItem.fromJson(Map<String, dynamic> j) =>
      ShoppingRequestItem(
        name:           j['name'] as String,
        quantity:       j['quantity'] as int,
        estimatedPrice: (j['estimatedPrice'] as num?)?.toDouble(),
        notes:          j['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        if (estimatedPrice != null) 'estimatedPrice': estimatedPrice,
        if (notes != null) 'notes': notes,
      };
}

class ShoppingRequest {
  final String id;
  final String requesterId;
  final String requesterName;
  final String title;
  final List<ShoppingRequestItem> items;
  final String deliveryHostel;
  final String? deliveryRoom;
  final double? budget;
  final String? note;
  final RequestStatus status;
  final String? runnerId;
  final String? runnerName;
  final double? runnerFee;
  final DateTime createdAt;

  ShoppingRequest({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.title,
    required this.items,
    required this.deliveryHostel,
    this.deliveryRoom,
    this.budget,
    this.note,
    required this.status,
    this.runnerId,
    this.runnerName,
    this.runnerFee,
    required this.createdAt,
  });

  factory ShoppingRequest.fromJson(Map<String, dynamic> j) => ShoppingRequest(
        id:            j['id'] as String,
        requesterId:   j['requesterId'] as String,
        requesterName: j['requesterName'] as String,
        title:         j['title'] as String,
        items:         (j['items'] as List)
            .map((e) => ShoppingRequestItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        deliveryHostel: j['deliveryHostel'] as String,
        deliveryRoom:   j['deliveryRoom'] as String?,
        budget:         (j['budget'] as num?)?.toDouble(),
        note:           j['note'] as String?,
        status:         requestStatusFromString(j['status'] as String?),
        runnerId:       j['runnerId'] as String?,
        runnerName:     j['runnerName'] as String?,
        runnerFee:      (j['runnerFee'] as num?)?.toDouble(),
        createdAt:      DateTime.parse(j['createdAt'] as String),
      );

  double get estimatedTotal => items.fold(0.0, (sum, i) {
        final unit = i.estimatedPrice ?? 0.0;
        return sum + unit * i.quantity;
      });
}
