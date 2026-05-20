import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';
import '../../widgets/product_card.dart';
import '../common/profile_screen.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Console'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Users', icon: Icon(Icons.people)),
            Tab(text: 'Products', icon: Icon(Icons.inventory_2)),
            Tab(text: 'Orders', icon: Icon(Icons.receipt_long)),
          ]),
          actions: [
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen())),
            ),
          ],
        ),
        body: const TabBarView(children: [
          _UsersTab(),
          _ProductsTab(),
          _OrdersTab(),
        ]),
      ),
    );
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    final svc = AdminService();
    final me = context.read<AuthProvider>().user;
    return StreamBuilder<List<AppUser>>(
      stream: svc.streamUsers(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = snap.data ?? [];
        if (users.isEmpty) return const Center(child: Text('No users.'));
        return ListView.separated(
          itemCount: users.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final u = users[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    u.suspended ? Colors.red.shade100 : Colors.deepPurple.shade100,
                child: Icon(
                  u.suspended ? Icons.block : Icons.person,
                  color: u.suspended ? Colors.red : Colors.deepPurple,
                ),
              ),
              title: Text(u.fullName.isEmpty ? u.email : u.fullName),
              subtitle: Text(
                  '${u.email} · ${u.role.name}${u.suspended ? ' · SUSPENDED' : ''}'),
              trailing: u.uid == me?.uid
                  ? const Text('You', style: TextStyle(color: Colors.grey))
                  : PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'suspend') {
                          await svc.setSuspended(u.uid, !u.suspended);
                        } else if (v.startsWith('role:')) {
                          await svc.setRole(u.uid,
                              roleFromString(v.substring('role:'.length)));
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                            value: 'suspend',
                            child:
                                Text(u.suspended ? 'Unsuspend' : 'Suspend')),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                            value: 'role:buyer', child: Text('Set role: Buyer')),
                        const PopupMenuItem(
                            value: 'role:seller',
                            child: Text('Set role: Seller')),
                        const PopupMenuItem(
                            value: 'role:admin', child: Text('Set role: Admin')),
                      ],
                    ),
            );
          },
        );
      },
    );
  }
}

class _ProductsTab extends StatelessWidget {
  const _ProductsTab();

  @override
  Widget build(BuildContext context) {
    final svc = ProductService();
    return StreamBuilder<List<Product>>(
      stream: svc.streamAll(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final products = snap.data ?? [];
        if (products.isEmpty) return const Center(child: Text('No products.'));
        return ListView.separated(
          itemCount: products.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final p = products[i];
            return ListTile(
              leading: p.imageUrl != null
                  ? Image.network(p.imageUrl!,
                      width: 48, height: 48, fit: BoxFit.cover)
                  : const Icon(Icons.shopping_bag, size: 32),
              title: Text(p.name),
              subtitle: Text(
                  '${kwacha.format(p.price)} · ${p.category} · ${p.sellerName}'),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Remove product?'),
                      content: Text('${p.name} (${p.sellerName})'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel')),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Remove')),
                      ],
                    ),
                  );
                  if (ok == true) await svc.delete(p.id);
                },
              ),
            );
          },
        );
      },
    );
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context) {
    final svc = OrderService();
    return StreamBuilder<List<AppOrder>>(
      stream: svc.streamAll(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snap.data ?? [];
        if (orders.isEmpty) return const Center(child: Text('No orders.'));
        return ListView.separated(
          itemCount: orders.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final o = orders[i];
            return ListTile(
              title: Text(
                  '${o.buyerName} → ${o.items.length} item(s) · ${kwacha.format(o.total)}'),
              subtitle: Text(
                  '${DateFormat.yMMMd().add_jm().format(o.createdAt)} · ${o.status.name} · ${o.paymentStatus.name}'),
            );
          },
        );
      },
    );
  }
}
