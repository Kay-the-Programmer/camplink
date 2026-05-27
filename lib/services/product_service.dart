import '../models/product.dart';
import 'api_client.dart';

class ProductService {
  Future<List<Product>> fetchAll() async {
    final data = await ApiClient.get('/products') as List;
    return data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Stream<List<Product>> streamAll() => pollingStream(fetchAll);

  Future<List<Product>> fetchBySeller(String sellerId) async {
    final data = await ApiClient.get('/products/seller/$sellerId') as List;
    return data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Stream<List<Product>> streamBySeller(String sellerId) =>
      pollingStream(() => fetchBySeller(sellerId));

  Future<List<Product>> fetchMy() async {
    final data = await ApiClient.get('/products/my') as List;
    return data.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
  }

  Stream<List<Product>> streamMy() => pollingStream(fetchMy);

  Future<Product> create(Product p) async {
    final data = await ApiClient.post('/products', p.toJson()) as Map<String, dynamic>;
    return Product.fromJson(data);
  }

  Future<Product> update(Product p) async {
    final data = await ApiClient.put('/products/${p.id}', p.toJson()) as Map<String, dynamic>;
    return Product.fromJson(data);
  }

  Future<void> delete(String id) async {
    await ApiClient.delete('/products/$id');
  }
}
