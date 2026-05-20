import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/review.dart';

class ReviewService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col => _db.collection('reviews');

  Future<void> create(Review r) async {
    await _col.add(r.toMap());
  }

  Stream<List<Review>> streamForSeller(String sellerId) => _col
      .where('sellerId', isEqualTo: sellerId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Review.fromDoc).toList());

  Future<bool> orderAlreadyReviewed(String orderId) async {
    final snap = await _col.where('orderId', isEqualTo: orderId).limit(1).get();
    return snap.docs.isNotEmpty;
  }

  Stream<SellerRating> ratingFor(String sellerId) => _col
      .where('sellerId', isEqualTo: sellerId)
      .snapshots()
      .map((s) {
        if (s.docs.isEmpty) return SellerRating.empty;
        final total =
            s.docs.fold<int>(0, (n, d) => n + ((d.data()['rating'] as num?)?.toInt() ?? 0));
        return SellerRating(total / s.docs.length, s.docs.length);
      });
}
