import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/review.dart';
import '../../services/review_service.dart';
import '../../widgets/seller_rating_view.dart';

class SellerReviewsScreen extends StatelessWidget {
  final String sellerId;
  final String sellerName;
  const SellerReviewsScreen({
    super.key,
    required this.sellerId,
    required this.sellerName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$sellerName · Reviews')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SellerRatingView(
              sellerId: sellerId,
              iconSize: 24,
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: StreamBuilder<List<Review>>(
              stream: ReviewService().streamForSeller(sellerId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final reviews = snap.data ?? [];
                if (reviews.isEmpty) {
                  return const Center(child: Text('No reviews yet.'));
                }
                return ListView.separated(
                  itemCount: reviews.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = reviews[i];
                    return ListTile(
                      title: Row(
                        children: [
                          ...List.generate(
                            5,
                            (k) => Icon(
                              k < r.rating
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(r.buyerName,
                              style: const TextStyle(fontSize: 13)),
                        ],
                      ),
                      subtitle: r.comment.isEmpty
                          ? null
                          : Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(r.comment),
                            ),
                      trailing: Text(
                        DateFormat.MMMd().format(r.createdAt),
                        style: const TextStyle(fontSize: 11),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
