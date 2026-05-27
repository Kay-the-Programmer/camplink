import '../models/review.dart';
import 'api_client.dart';

class ReviewService {
  Future<void> create({
    required String sellerId,
    required String orderId,
    required int rating,
    required String comment,
  }) async {
    await ApiClient.post('/reviews', {
      'sellerId': sellerId,
      'orderId':  orderId,
      'rating':   rating,
      'comment':  comment,
    });
  }

  Future<List<Review>> fetchForSeller(String sellerId) async {
    final data = await ApiClient.get('/reviews/seller/$sellerId') as List;
    return data.map((e) => Review.fromJson(e as Map<String, dynamic>)).toList();
  }

  Stream<List<Review>> streamForSeller(String sellerId) =>
      pollingStream(() => fetchForSeller(sellerId));

  Future<bool> orderAlreadyReviewed(String orderId) async {
    final data = await ApiClient.get('/reviews/order/$orderId/exists')
        as Map<String, dynamic>;
    return data['reviewed'] as bool;
  }

  Future<SellerRating> ratingFor(String sellerId) async {
    final data = await ApiClient.get('/reviews/seller/$sellerId/rating')
        as Map<String, dynamic>;
    return SellerRating.fromJson(data);
  }

  Stream<SellerRating> streamRatingFor(String sellerId) =>
      pollingStream(() => ratingFor(sellerId));
}
