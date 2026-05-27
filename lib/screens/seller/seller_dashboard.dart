import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../services/product_service.dart';
import '../../widgets/notifications_bell.dart';
import '../common/chat_list_screen.dart';
import 'add_edit_product_screen.dart';
import 'seller_orders_screen.dart';

class SellerDashboard extends StatelessWidget {
  const SellerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final svc = ProductService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Store'),
        actions: [
          const NotificationsBell(),
          IconButton(
            icon: const Icon(Symbols.chat_bubble),
            tooltip: 'Messages',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ChatListScreen())),
          ),
          IconButton(
            icon: const Icon(Symbols.receipt_long),
            tooltip: 'Incoming orders',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SellerOrdersScreen())),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Symbols.add),
        label: const Text('Add product'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditProductScreen()),
        ),
      ),
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<List<Product>>(
              stream: svc.streamBySeller(user.uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final products = snap.data ?? [];
                if (products.isEmpty) {
                  return const Center(
                      child: Text('No products yet. Tap + to add one.'));
                }
                return ListView.separated(
                  itemCount: products.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = products[i];
                    return ListTile(
                      leading: p.imageUrl != null
                          ? Image.network(p.imageUrl!,
                              width: 56, height: 56, fit: BoxFit.cover)
                          : Container(
                              width: 56,
                              height: 56,
                              color: Colors.grey.shade200,
                              child: const Icon(Symbols.shopping_bag),
                            ),
                      title: Text(p.name),
                      subtitle: Text(
                          '${kwacha.format(p.price)} · ${p.category}${p.available ? '' : ' · Unavailable'}'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) async {
                          if (v == 'edit') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AddEditProductScreen(existing: p),
                              ),
                            );
                          } else if (v == 'delete') {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Delete product?'),
                                content: Text(p.name),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel')),
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Delete')),
                                ],
                              ),
                            );
                            if (ok == true) await svc.delete(p.id);
                          } else if (v == 'toggle') {
                            await svc.update(Product(
                              id: p.id,
                              sellerId: p.sellerId,
                              sellerName: p.sellerName,
                              name: p.name,
                              description: p.description,
                              category: p.category,
                              price: p.price,
                              available: !p.available,
                              imageUrl: p.imageUrl,
                              createdAt: p.createdAt,
                            ));
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                              value: 'edit', child: Text('Edit')),
                          PopupMenuItem(
                              value: 'toggle',
                              child: Text(p.available
                                  ? 'Mark unavailable'
                                  : 'Mark available')),
                          const PopupMenuItem(
                              value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
