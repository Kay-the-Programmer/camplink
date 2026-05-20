import 'package:flutter/foundation.dart';

import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();
  int get count => _items.values.fold(0, (n, i) => n + i.quantity);
  double get total => _items.values.fold(0, (s, i) => s + i.subtotal);
  bool get isEmpty => _items.isEmpty;

  /// All items must share a seller to checkout; returns the sellerId if so.
  String? get singleSellerId {
    if (_items.isEmpty) return null;
    final ids = _items.values.map((e) => e.product.sellerId).toSet();
    return ids.length == 1 ? ids.first : null;
  }

  void add(Product p) {
    final existing = _items[p.id];
    if (existing != null) {
      existing.quantity += 1;
    } else {
      _items[p.id] = CartItem(product: p);
    }
    notifyListeners();
  }

  void remove(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void setQuantity(String productId, int qty) {
    final item = _items[productId];
    if (item == null) return;
    if (qty <= 0) {
      _items.remove(productId);
    } else {
      item.quantity = qty;
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
