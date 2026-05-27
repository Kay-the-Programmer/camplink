import '../models/shopping_request.dart';
import 'api_client.dart';

class ShoppingRequestService {
  Future<List<ShoppingRequest>> fetchOpen() async {
    final data = await ApiClient.get('/requests') as List;
    return data.map((e) => ShoppingRequest.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ShoppingRequest>> fetchMine() async {
    final data = await ApiClient.get('/requests/mine') as List;
    return data.map((e) => ShoppingRequest.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ShoppingRequest>> fetchRunning() async {
    final data = await ApiClient.get('/requests/running') as List;
    return data.map((e) => ShoppingRequest.fromJson(e as Map<String, dynamic>)).toList();
  }

  Stream<List<ShoppingRequest>> streamOpen() =>
      pollingStream(() => fetchOpen(), interval: const Duration(seconds: 20));

  Stream<List<ShoppingRequest>> streamMine() =>
      pollingStream(() => fetchMine(), interval: const Duration(seconds: 20));

  Stream<List<ShoppingRequest>> streamRunning() =>
      pollingStream(() => fetchRunning(), interval: const Duration(seconds: 20));

  Future<ShoppingRequest> create({
    required String title,
    required List<ShoppingRequestItem> items,
    required String deliveryHostel,
    String? deliveryRoom,
    double? budget,
    String? note,
    double? runnerFee,
  }) async {
    final body = {
      'title': title,
      'items': items.map((i) => i.toJson()).toList(),
      'deliveryHostel': deliveryHostel,
      'deliveryRoom': ?deliveryRoom,
      'budget':       ?budget,
      'note':         ?note,
      'runnerFee':    ?runnerFee,
    };
    final data = await ApiClient.post('/requests', body) as Map<String, dynamic>;
    return ShoppingRequest.fromJson(data);
  }

  Future<ShoppingRequest> accept(String requestId) async {
    final data = await ApiClient.post('/requests/$requestId/accept') as Map<String, dynamic>;
    return ShoppingRequest.fromJson(data);
  }

  Future<ShoppingRequest> fulfill(String requestId) async {
    final data = await ApiClient.post('/requests/$requestId/fulfill') as Map<String, dynamic>;
    return ShoppingRequest.fromJson(data);
  }

  Future<void> cancel(String requestId) => ApiClient.delete('/requests/$requestId');
}
