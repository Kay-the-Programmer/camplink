import '../models/order.dart';
import '../models/cart_item.dart';
import 'api_client.dart';

class OrderService {
  Future<AppOrder> place({
    required List<CartItem> items,
    required DeliveryMethod deliveryMethod,
    required String deliveryLocation,
    required PaymentMethod paymentMethod,
  }) async {
    final body = {
      'items': items
          .map((c) => {'productId': c.product.id, 'quantity': c.quantity})
          .toList(),
      'deliveryMethod':  deliveryMethodToApi(deliveryMethod),
      'deliveryLocation': deliveryLocation,
      'paymentMethod':   paymentMethodToApi(paymentMethod),
    };
    final data = await ApiClient.post('/orders', body) as Map<String, dynamic>;
    return AppOrder.fromJson(data);
  }

  Future<List<AppOrder>> fetchForBuyer() async {
    final data = await ApiClient.get('/orders/buyer') as List;
    return data.map((e) => AppOrder.fromJson(e as Map<String, dynamic>)).toList();
  }

  Stream<List<AppOrder>> streamForBuyer(String buyerId) =>
      pollingStream(fetchForBuyer);

  Future<List<AppOrder>> fetchForSeller() async {
    final data = await ApiClient.get('/orders/seller') as List;
    return data.map((e) => AppOrder.fromJson(e as Map<String, dynamic>)).toList();
  }

  Stream<List<AppOrder>> streamForSeller(String sellerId) =>
      pollingStream(fetchForSeller);

  Future<List<AppOrder>> fetchAll() async {
    final data = await ApiClient.get('/orders') as List;
    return data.map((e) => AppOrder.fromJson(e as Map<String, dynamic>)).toList();
  }

  Stream<List<AppOrder>> streamAll() => pollingStream(fetchAll);

  Future<AppOrder> updateStatus(String orderId, OrderStatus status) async {
    final data = await ApiClient.patch(
      '/orders/$orderId/status',
      {'status': orderStatusToApi(status)},
    ) as Map<String, dynamic>;
    return AppOrder.fromJson(data);
  }

  Future<AppOrder> markPaid(String orderId) async {
    final data =
        await ApiClient.patch('/orders/$orderId/paid') as Map<String, dynamic>;
    return AppOrder.fromJson(data);
  }
}
