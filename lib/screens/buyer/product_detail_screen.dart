import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/seller_rating_view.dart';
import '../common/chat_screen.dart';
import 'cart_screen.dart';
import 'seller_reviews_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().user;
    final canMessage = me != null && me.uid != product.sellerId;
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          if (canMessage)
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              tooltip: 'Message seller',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    otherUid: product.sellerId,
                    otherName: product.sellerName,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: product.imageUrl != null
                ? CachedNetworkImage(imageUrl: product.imageUrl!, fit: BoxFit.cover)
                : Container(
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.shopping_bag, size: 96, color: Colors.grey),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(kwacha.format(product.price),
                    style: const TextStyle(
                        fontSize: 20, color: Colors.deepPurple)),
                const SizedBox(height: 8),
                Chip(label: Text(product.category)),
                const SizedBox(height: 12),
                Text(product.description),
                const Divider(height: 32),
                const Text('Seller',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(product.sellerName),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SellerReviewsScreen(
                        sellerId: product.sellerId,
                        sellerName: product.sellerName,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      SellerRatingView(sellerId: product.sellerId, iconSize: 18),
                      const SizedBox(width: 6),
                      const Text('See reviews',
                          style: TextStyle(color: Colors.deepPurple, fontSize: 12)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (!product.available)
                  const Text('Currently unavailable',
                      style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton.icon(
            icon: const Icon(Icons.add_shopping_cart),
            label: const Text('Add to cart'),
            onPressed: !product.available
                ? null
                : () {
                    context.read<CartProvider>().add(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.name} added to cart'),
                        action: SnackBarAction(
                          label: 'View cart',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CartScreen()),
                          ),
                        ),
                      ),
                    );
                  },
          ),
        ),
      ),
    );
  }
}
