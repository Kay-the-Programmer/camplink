import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('products');

  Stream<List<Product>> streamAll() => _col
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Product.fromDoc).toList());

  Stream<List<Product>> streamBySeller(String sellerId) => _col
      .where('sellerId', isEqualTo: sellerId)
      .snapshots()
      .map((s) => s.docs.map(Product.fromDoc).toList());

  Future<String> create(Product p) async {
    final ref = await _col.add(p.toMap());
    return ref.id;
  }

  Future<void> update(Product p) async {
    await _col.doc(p.id).update(p.toMap());
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }
}
