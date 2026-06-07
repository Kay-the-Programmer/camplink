import '../models/service_listing.dart';
import 'api_client.dart';

class ServiceListingService {
  Future<List<ServiceListing>> fetchAll() async {
    final data = await ApiClient.get('/services') as List;
    return data
        .map((e) => ServiceListing.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ServiceListing>> fetchMine() async {
    final data = await ApiClient.get('/services/mine') as List;
    return data
        .map((e) => ServiceListing.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Stream<List<ServiceListing>> streamAll() =>
      pollingStream(() => fetchAll(), interval: const Duration(seconds: 30));

  Stream<List<ServiceListing>> streamMine() =>
      pollingStream(() => fetchMine(), interval: const Duration(seconds: 30));

  Future<ServiceListing> create({
    required String title,
    required String description,
    required ServiceCategory category,
    double? price,
    String? priceNote,
  }) async {
    final body = <String, dynamic>{
      'title':       title,
      'description': description,
      'category':    category.name,
      'price':       price,
      'priceNote':   priceNote,
      'available':   true,
    };
    final data =
        await ApiClient.post('/services', body) as Map<String, dynamic>;
    return ServiceListing.fromJson(data);
  }

  Future<void> toggleAvailability(String id, bool available) =>
      ApiClient.patch('/services/$id', {'available': available});

  Future<void> delete(String id) => ApiClient.delete('/services/$id');
}
