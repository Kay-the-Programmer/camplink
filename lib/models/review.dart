import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String sellerId;
  final String buyerId;
  final String buyerName;
  final String orderId;
  final int rating; // 1..5
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.sellerId,
    required this.buyerId,
    required this.buyerName,
    required this.orderId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Review(
      id: doc.id,
      sellerId: d['sellerId'] ?? '',
      buyerId: d['buyerId'] ?? '',
      buyerName: d['buyerName'] ?? '',
      orderId: d['orderId'] ?? '',
      rating: (d['rating'] as num?)?.toInt() ?? 0,
      comment: d['comment'] ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'sellerId': sellerId,
        'buyerId': buyerId,
        'buyerName': buyerName,
        'orderId': orderId,
        'rating': rating,
        'comment': comment,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class SellerRating {
  final double average;
  final int count;
  const SellerRating(this.average, this.count);
  static const empty = SellerRating(0, 0);
}
