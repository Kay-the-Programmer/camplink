import 'product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => product.price * quantity;

  Map<String, dynamic> toOrderLine() => {
        'productId': product.id,
        'name': product.name,
        'price': product.price,
        'quantity': quantity,
        'sellerId': product.sellerId,
      };
}
