import 'package:flutter/material.dart';

import '../models/review.dart';
import '../services/review_service.dart';

class SellerRatingView extends StatelessWidget {
  final String sellerId;
  final double iconSize;
  final TextStyle? textStyle;
  const SellerRatingView({
    super.key,
    required this.sellerId,
    this.iconSize = 16,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SellerRating>(
      stream: ReviewService().ratingFor(sellerId),
      builder: (context, snap) {
        final r = snap.data ?? SellerRating.empty;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, color: Colors.amber, size: iconSize),
            const SizedBox(width: 2),
            Text(
              r.count == 0
                  ? 'No ratings'
                  : '${r.average.toStringAsFixed(1)} (${r.count})',
              style: textStyle ?? const TextStyle(fontSize: 12),
            ),
          ],
        );
      },
    );
  }
}
