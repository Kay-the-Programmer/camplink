class Review {
  final String id;
  final String sellerId;
  final String buyerId;
  final String buyerName;
  final String? orderId;
  final int rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.sellerId,
    required this.buyerId,
    required this.buyerName,
    this.orderId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> j) => Review(
        id:        j['id'] as String,
        sellerId:  j['sellerId'] as String,
        buyerId:   j['buyerId'] as String,
        buyerName: j['buyerName'] as String,
        orderId:   j['orderId'] as String?,
        rating:    j['rating'] as int,
        comment:   j['comment'] as String? ?? '',
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

class SellerRating {
  final double average;
  final int count;
  const SellerRating(this.average, this.count);
  static const empty = SellerRating(0, 0);

  factory SellerRating.fromJson(Map<String, dynamic> j) => SellerRating(
        (j['average'] as num).toDouble(),
        (j['count'] as num).toInt(),
      );
}
