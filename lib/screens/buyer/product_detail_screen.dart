import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../app_colors.dart';

import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/api_client.dart';
import '../../widgets/seller_rating_view.dart';
import '../common/chat_screen.dart';
import '../../widgets/auth_prompt.dart';
import 'cart_screen.dart';
import 'seller_reviews_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().user;
    final isGuest = me == null;
    final canMessage = me != null && me.uid != product.sellerId;
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          if (canMessage)
            IconButton(
              icon: const Icon(Symbols.chat_bubble),
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
          // Guest sees an inquiry button that prompts login.
          if (isGuest)
            IconButton(
              icon: const Icon(Symbols.chat_bubble),
              tooltip: 'Enquire about delivery',
              onPressed: () => showAuthPrompt(context),
            ),
        ],
      ),
      body: ListView(
        children: [
          _ProductGallery(images: product.imageUrls),
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
                        fontSize: 20, color: kOrange)),
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
                          style: TextStyle(color: kOrange, fontSize: 12)),
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
            icon: const Icon(Symbols.add_shopping_cart),
            label: const Text('Add to cart'),
            onPressed: !product.available
                ? null
                : () {
                    if (isGuest) {
                      showAuthPrompt(context);
                      return;
                    }
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

/// A swipable image gallery with page dots. Falls back to a placeholder when
/// the product has no images, and shows a single static image (no dots) when
/// there is exactly one.
class _ProductGallery extends StatefulWidget {
  final List<String> images;
  const _ProductGallery({required this.images});

  @override
  State<_ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<_ProductGallery> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    if (images.isEmpty) {
      return AspectRatio(
        aspectRatio: 1,
        child: Container(
          color: Colors.grey.shade200,
          child: const Icon(Symbols.shopping_bag, size: 96, color: Colors.grey),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) => CachedNetworkImage(
              imageUrl: ApiClient.fileUrl(images[i]),
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (_, _) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (_, _, _) =>
                  const Icon(Symbols.broken_image, size: 64),
            ),
          ),
          if (images.length > 1)
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (i) {
                  final active = i == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: active ? 18 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: active ? kOrange : Colors.white70,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 2),
                      ],
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
