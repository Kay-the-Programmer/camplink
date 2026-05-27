import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../app_colors.dart';
import '../../models/app_user.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../models/shopping_request.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';
import '../../services/shopping_request_service.dart';
import '../../services/storage_service.dart';
import '../../widgets/notifications_bell.dart';
import '../common/chat_list_screen.dart';
import '../seller/add_edit_product_screen.dart';

// ── Tab indices ───────────────────────────────────────────────────────────────
const _kDashboard = 0;
const _kServices  = 1;
const _kOrders    = 2;
const _kProfile   = 3;

// ═════════════════════════════════════════════════════════════════════════════
// PROVIDER SHELL
// ═════════════════════════════════════════════════════════════════════════════

class ProviderShell extends StatefulWidget {
  const ProviderShell({super.key});

  @override
  State<ProviderShell> createState() => _ProviderShellState();
}

class _ProviderShellState extends State<ProviderShell> {
  int _tab = _kDashboard;

  // ── Helpers ────────────────────────────────────────────────────────────────

  String _appBarTitle(AppUser u) {
    switch (_tab) {
      case _kDashboard: return 'Dashboard';
      case _kServices:
        if (u.role == UserRole.seller) return 'My Products';
        if (u.role == UserRole.rider)  return 'My Rides';
        return 'My Deliveries';
      case _kOrders:   return 'Incoming';
      case _kProfile:  return 'Profile';
      default:         return 'CampLink';
    }
  }

  Widget? _fab(BuildContext ctx, AppUser u) {
    if (_tab == _kServices) {
      switch (u.role) {
        case UserRole.seller:
          return FloatingActionButton.extended(
            heroTag: 'provider_fab',
            icon: const Icon(Symbols.add),
            label: const Text('Add product'),
            onPressed: () => Navigator.push(ctx,
                MaterialPageRoute(builder: (_) => const AddEditProductScreen())),
          );
        case UserRole.rider:
          return FloatingActionButton.extended(
            heroTag: 'provider_fab',
            icon: const Icon(Symbols.add),
            label: const Text('Post ride'),
            onPressed: () {/* TODO: ride creation screen */},
          );
        default:
          return null;
      }
    }
    return null;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;

    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle(user)),
        actions: [
          const NotificationsBell(),
          IconButton(
            icon: const Icon(Symbols.chat_bubble),
            tooltip: 'Messages',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ChatListScreen())),
          ),
        ],
      ),
      floatingActionButton: _fab(context, user),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Symbols.dashboard),
            selectedIcon: Icon(Symbols.dashboard, fill: 1),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Symbols.inventory_2),
            selectedIcon: Icon(Symbols.inventory_2, fill: 1),
            label: 'Services',
          ),
          NavigationDestination(
            icon: Icon(Symbols.receipt_long),
            selectedIcon: Icon(Symbols.receipt_long, fill: 1),
            label: 'Incoming',
          ),
          NavigationDestination(
            icon: Icon(Symbols.person),
            selectedIcon: Icon(Symbols.person, fill: 1),
            label: 'Profile',
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _DashboardTab(user: user),
          _ServicesTab(user: user),
          _IncomingTab(user: user),
          _ProfileTab(user: user),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 0 — DASHBOARD
// ═════════════════════════════════════════════════════════════════════════════

class _DashboardTab extends StatelessWidget {
  final AppUser user;
  const _DashboardTab({required this.user});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _GreetingCard(user: user),
        const SizedBox(height: 16),
        _ProviderStatsRow(user: user),
        const SizedBox(height: 20),
        Text('Recent Activity',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _RecentActivity(user: user),
      ],
    );
  }
}

// ── Greeting card ─────────────────────────────────────────────────────────────

class _GreetingCard extends StatelessWidget {
  final AppUser user;
  const _GreetingCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final firstName =
        user.fullName.trim().isEmpty ? 'Provider' : user.fullName.split(' ').first;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kOrange, kOrange.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage:
                user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
            backgroundColor: Colors.white.withValues(alpha: 0.25),
            child: user.photoUrl == null
                ? const Icon(Symbols.person, color: Colors.white, size: 30)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hello, $firstName!',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    roleLabel(user.role),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          // Logout button
          Consumer<AuthProvider>(
            builder: (_, auth, _) => IconButton(
              icon: const Icon(Symbols.logout, color: Colors.white),
              tooltip: 'Logout',
              onPressed: auth.logout,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats row ─────────────────────────────────────────────────────────────────

class _ProviderStatsRow extends StatelessWidget {
  final AppUser user;
  const _ProviderStatsRow({required this.user});

  @override
  Widget build(BuildContext context) {
    // Sellers use order stats; riders/drivers use delivery request stats.
    if (user.role == UserRole.seller) {
      return StreamBuilder<List<AppOrder>>(
        stream: OrderService().streamForSeller(user.uid),
        builder: (_, snap) {
          final orders = snap.data ?? [];
          final pending =
              orders.where((o) => o.status == OrderStatus.pending).length;
          final confirmed =
              orders.where((o) => o.status == OrderStatus.confirmed).length;
          final completed =
              orders.where((o) => o.status == OrderStatus.delivered).length;
          final revenue = orders
              .where((o) => o.status == OrderStatus.delivered)
              .fold<double>(0, (s, o) => s + o.total);
          return _StatsGrid(stats: [
            _Stat('Revenue', kwacha.format(revenue), Symbols.payments, Colors.green),
            _Stat('Pending', '$pending', Symbols.hourglass_empty, Colors.orange),
            _Stat('Confirmed', '$confirmed', Symbols.thumb_up, Colors.blue),
            _Stat('Completed', '$completed', Symbols.check_circle, kOrange),
          ]);
        },
      );
    }

    // Riders / drivers — use shopping request counts.
    return StreamBuilder<List<ShoppingRequest>>(
      stream: ShoppingRequestService().streamRunning(),
      builder: (_, snap) {
        final running = snap.data ?? [];
        final active =
            running.where((r) => r.status == RequestStatus.accepted).length;
        final done =
            running.where((r) => r.status == RequestStatus.fulfilled).length;
        return _StatsGrid(stats: [
          _Stat('Active', '$active', Symbols.directions_run, kOrange),
          _Stat('Completed', '$done', Symbols.check_circle, Colors.green),
          _Stat(
              'Role',
              user.role == UserRole.rider ? 'Rider' : 'Driver',
              user.role == UserRole.rider
                  ? Symbols.directions_car
                  : Symbols.delivery_dining,
              Colors.blue),
        ]);
      },
    );
  }
}

class _Stat {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _Stat(this.label, this.value, this.icon, this.color);
}

class _StatsGrid extends StatelessWidget {
  final List<_Stat> stats;
  const _StatsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: stats
          .map((s) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 6),
                      child: Column(
                        children: [
                          Icon(s.icon, color: s.color, size: 22),
                          const SizedBox(height: 6),
                          Text(s.value,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: s.color)),
                          const SizedBox(height: 2),
                          Text(s.label,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 10),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }
}

// ── Recent activity ───────────────────────────────────────────────────────────

class _RecentActivity extends StatelessWidget {
  final AppUser user;
  const _RecentActivity({required this.user});

  @override
  Widget build(BuildContext context) {
    if (user.role == UserRole.seller) {
      return StreamBuilder<List<AppOrder>>(
        stream: OrderService().streamForSeller(user.uid),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting &&
              snap.data == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final orders = (snap.data ?? []).take(5).toList();
          if (orders.isEmpty) {
            return _emptyActivity('No orders yet. Your first sale is coming!');
          }
          return Column(
            children: orders.map((o) => _OrderActivityTile(order: o)).toList(),
          );
        },
      );
    }

    return StreamBuilder<List<ShoppingRequest>>(
      stream: ShoppingRequestService().streamRunning(),
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting &&
            snap.data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final requests = (snap.data ?? []).take(5).toList();
        if (requests.isEmpty) {
          return _emptyActivity('No active deliveries. Accept a request!');
        }
        return Column(
          children:
              requests.map((r) => _RequestActivityTile(request: r)).toList(),
        );
      },
    );
  }

  Widget _emptyActivity(String msg) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(msg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey)),
        ),
      );
}

class _OrderActivityTile extends StatelessWidget {
  final AppOrder order;
  const _OrderActivityTile({required this.order});

  Color get _color {
    switch (order.status) {
      case OrderStatus.pending:   return Colors.orange;
      case OrderStatus.confirmed: return Colors.blue;
      case OrderStatus.delivered: return Colors.green;
      case OrderStatus.cancelled: return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _color.withValues(alpha: 0.1),
          child: Icon(Symbols.shopping_bag, color: _color, size: 20),
        ),
        title: Text(
          '${order.buyerName}  ·  ${kwacha.format(order.total)}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '${order.items.length} item(s)  ·  ${order.status.name}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Chip(
          label: Text(order.status.name,
              style: const TextStyle(color: Colors.white, fontSize: 11)),
          backgroundColor: _color,
          padding: EdgeInsets.zero,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

class _RequestActivityTile extends StatelessWidget {
  final ShoppingRequest request;
  const _RequestActivityTile({required this.request});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey.shade200)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: kOrangeLight,
          child: Icon(Symbols.delivery_dining, color: kOrange, size: 20),
        ),
        title: Text(request.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(
          '${request.requesterName}  ·  ${request.status.name}',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 1 — SERVICES
// ═════════════════════════════════════════════════════════════════════════════

class _ServicesTab extends StatelessWidget {
  final AppUser user;
  const _ServicesTab({required this.user});

  @override
  Widget build(BuildContext context) {
    switch (user.role) {
      case UserRole.seller:
        return _SellerProductsPane(sellerId: user.uid);
      case UserRole.driver:
        return const _DriverDeliveryPane();
      case UserRole.rider:
        return const _RiderPane();
      default:
        return const Center(child: Text('No services configured.'));
    }
  }
}

// ── Seller: products management ───────────────────────────────────────────────

class _SellerProductsPane extends StatelessWidget {
  // sellerId kept for reference (e.g. delete confirmation) but the stream
  // uses the auth-token–gated /products/my endpoint, not the public
  // /products/seller/{id} endpoint.
  final String sellerId;
  const _SellerProductsPane({required this.sellerId});

  @override
  Widget build(BuildContext context) {
    final svc = ProductService();
    return StreamBuilder<List<Product>>(
      stream: svc.streamMy(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting &&
            snap.data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final products = snap.data ?? [];
        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Symbols.inventory_2,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('No products yet.',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                const Text('Tap + Add product to list your first item.',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          );
        }
        return ListView.separated(
          itemCount: products.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final p = products[i];
            return ListTile(
              leading: p.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(p.imageUrl!,
                          width: 54, height: 54, fit: BoxFit.cover),
                    )
                  : Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Symbols.shopping_bag)),
              title: Text(p.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                '${kwacha.format(p.price)}  ·  ${p.category}'
                '${p.available ? '' : '  ·  Unavailable'}',
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'edit') {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                AddEditProductScreen(existing: p)));
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
                  } else if (v == 'delete') {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete product?'),
                        content: Text(p.name),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Cancel')),
                          TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Delete',
                                  style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (ok == true) await svc.delete(p.id);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                      value: 'toggle',
                      child: Text(
                          p.available ? 'Mark unavailable' : 'Mark available')),
                  const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete',
                          style: TextStyle(color: Colors.red))),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ── Driver: active delivery requests ─────────────────────────────────────────

class _DriverDeliveryPane extends StatelessWidget {
  const _DriverDeliveryPane();

  @override
  Widget build(BuildContext context) {
    final svc = ShoppingRequestService();
    return StreamBuilder<List<ShoppingRequest>>(
      stream: svc.streamOpen(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting &&
            snap.data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final requests = snap.data ?? [];
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Symbols.delivery_dining,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('No open delivery requests.',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: requests.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _DeliveryRequestCard(request: requests[i]),
        );
      },
    );
  }
}

class _DeliveryRequestCard extends StatefulWidget {
  final ShoppingRequest request;
  const _DeliveryRequestCard({required this.request});

  @override
  State<_DeliveryRequestCard> createState() => _DeliveryRequestCardState();
}

class _DeliveryRequestCardState extends State<_DeliveryRequestCard> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                  child: Text(r.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15))),
              if (r.runnerFee != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: kOrangeLight,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text('Fee: ${kwacha.format(r.runnerFee!)}',
                      style: const TextStyle(
                          color: kOrange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
            ]),
            const SizedBox(height: 4),
            Text('by ${r.requesterName}',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            ...r.items.map((item) => Text(
                  '• ${item.name}  ×${item.quantity}',
                  style: const TextStyle(fontSize: 13),
                )),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Symbols.home, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                  r.deliveryHostel +
                      (r.deliveryRoom != null ? ', ${r.deliveryRoom}' : ''),
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ]),
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Symbols.delivery_dining),
                  label: const Text('Accept delivery'),
                  onPressed: () async {
                    setState(() => _loading = true);
                    try {
                      await ShoppingRequestService().accept(r.id);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$e')));
                      }
                    } finally {
                      if (mounted) setState(() => _loading = false);
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Rider: placeholder ────────────────────────────────────────────────────────

class _RiderPane extends StatelessWidget {
  const _RiderPane();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.directions_car,
                size: 72,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            const Text('Rides Feature',
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Post available rides and manage bookings from students on campus.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Symbols.add),
              label: const Text('Post a ride'),
              onPressed: () {/* TODO */},
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 2 — INCOMING ORDERS / REQUESTS
// ═════════════════════════════════════════════════════════════════════════════

class _IncomingTab extends StatelessWidget {
  final AppUser user;
  const _IncomingTab({required this.user});

  @override
  Widget build(BuildContext context) {
    if (user.role == UserRole.seller) return _SellerOrdersPane(uid: user.uid);
    return _RunnerRequestsPane(uid: user.uid);
  }
}

// ── Seller incoming orders ────────────────────────────────────────────────────

class _SellerOrdersPane extends StatelessWidget {
  final String uid;
  const _SellerOrdersPane({required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppOrder>>(
      stream: OrderService().streamForSeller(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting &&
            snap.data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snap.data ?? [];
        final active = all
            .where((o) =>
                o.status == OrderStatus.pending ||
                o.status == OrderStatus.confirmed)
            .toList();
        if (active.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Symbols.inbox, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('No pending orders.',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: active.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _SellerOrderCard(order: active[i]),
        );
      },
    );
  }
}

class _SellerOrderCard extends StatefulWidget {
  final AppOrder order;
  const _SellerOrderCard({required this.order});

  @override
  State<_SellerOrderCard> createState() => _SellerOrderCardState();
}

class _SellerOrderCardState extends State<_SellerOrderCard> {
  bool _loading = false;
  final _svc = OrderService();

  Future<void> _update(OrderStatus s) async {
    setState(() => _loading = true);
    try {
      await _svc.updateStatus(widget.order.id, s);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final isPending = o.status == OrderStatus.pending;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(children: [
              Expanded(
                  child: Text(o.buyerName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15))),
              Text(kwacha.format(o.total),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: kOrange)),
            ]),
            const SizedBox(height: 4),
            Text(
              DateFormat.yMMMd().add_jm().format(o.createdAt),
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 8),
            // Items
            ...o.items.map((l) => Text(
                  '• ${l.name}  ×${l.quantity}  ·  ${kwacha.format(l.price * l.quantity)}',
                  style: const TextStyle(fontSize: 13),
                )),
            const SizedBox(height: 8),
            // Delivery info
            Row(children: [
              const Icon(Symbols.home, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(o.deliveryLocation,
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(width: 10),
              const Icon(Symbols.payments, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(paymentMethodLabel(o.paymentMethod),
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 12)),
            ]),
            const Divider(height: 20),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              Row(children: [
                if (isPending)
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Symbols.thumb_up, size: 18),
                      label: const Text('Confirm'),
                      onPressed: () => _update(OrderStatus.confirmed),
                    ),
                  ),
                if (!isPending) ...[
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Symbols.check_circle, size: 18),
                      label: const Text('Mark delivered'),
                      onPressed: () => _update(OrderStatus.delivered),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red)),
                  onPressed: () => _update(OrderStatus.cancelled),
                  child: const Text('Cancel'),
                ),
              ]),
          ],
        ),
      ),
    );
  }
}

// ── Runner (driver/rider) incoming requests ───────────────────────────────────

class _RunnerRequestsPane extends StatelessWidget {
  final String uid;
  const _RunnerRequestsPane({required this.uid});

  @override
  Widget build(BuildContext context) {
    final svc = ShoppingRequestService();
    return StreamBuilder<List<ShoppingRequest>>(
      stream: svc.streamRunning(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting &&
            snap.data == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final mine = (snap.data ?? [])
            .where((r) =>
                r.runnerId == uid &&
                r.status == RequestStatus.accepted)
            .toList();
        if (mine.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Symbols.inbox, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('No active assignments.',
                    style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                const Text('Accept a delivery from Services tab.',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: mine.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) =>
              _ActiveDeliveryCard(request: mine[i]),
        );
      },
    );
  }
}

class _ActiveDeliveryCard extends StatefulWidget {
  final ShoppingRequest request;
  const _ActiveDeliveryCard({required this.request});

  @override
  State<_ActiveDeliveryCard> createState() => _ActiveDeliveryCardState();
}

class _ActiveDeliveryCardState extends State<_ActiveDeliveryCard> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return Card(
      elevation: 0,
      color: kOrangeLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            Text('Requested by ${r.requesterName}',
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 8),
            ...r.items.map((item) => Text('• ${item.name}  ×${item.quantity}',
                style: const TextStyle(fontSize: 13))),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Symbols.home, size: 14, color: Colors.black45),
              const SizedBox(width: 4),
              Text(
                  r.deliveryHostel +
                      (r.deliveryRoom != null ? ', ${r.deliveryRoom}' : ''),
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
            ]),
            if (r.runnerFee != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Symbols.payments, size: 14, color: kOrange),
                const SizedBox(width: 4),
                Text('Your fee: ${kwacha.format(r.runnerFee!)}',
                    style: const TextStyle(
                        color: kOrange,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ]),
            ],
            const SizedBox(height: 12),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Symbols.check_circle),
                  label: const Text('Mark as delivered'),
                  onPressed: () async {
                    setState(() => _loading = true);
                    try {
                      await ShoppingRequestService().fulfill(r.id);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text('$e')));
                      }
                    } finally {
                      if (mounted) setState(() => _loading = false);
                    }
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 3 — PROFILE
// ═════════════════════════════════════════════════════════════════════════════

class _ProfileTab extends StatefulWidget {
  final AppUser user;
  const _ProfileTab({required this.user});

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  late TextEditingController _name;
  late TextEditingController _phone;
  late TextEditingController _hostel;
  late TextEditingController _location;
  XFile? _pickedPhoto;
  Uint8List? _pickedBytes;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _name     = TextEditingController(text: u.fullName);
    _phone    = TextEditingController(text: u.phone);
    _hostel   = TextEditingController(text: u.hostel ?? '');
    _location = TextEditingController(text: u.location ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _hostel.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final x = await ImagePicker()
        .pickImage(source: ImageSource.gallery, maxWidth: 600, imageQuality: 80);
    if (x == null) return;
    setState(() { _pickedPhoto = x; _pickedBytes = null; });
    final bytes = await x.readAsBytes();
    if (mounted) setState(() => _pickedBytes = bytes);
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;
    setState(() => _busy = true);
    try {
      String? photoUrl = user.photoUrl;
      if (_pickedPhoto != null) {
        photoUrl = await StorageService()
            .uploadImage(_pickedPhoto!, 'avatars/${user.uid}');
      }
      await auth.updateProfile(user.copyWith(
        fullName: _name.text.trim(),
        phone:    _phone.text.trim(),
        hostel:   _hostel.text.trim(),
        location: _location.text.trim(),
        photoUrl: photoUrl,
      ));
      if (mounted) {
        setState(() { _pickedPhoto = null; _pickedBytes = null; });
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profile updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Avatar
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundImage: _pickedBytes != null
                    ? MemoryImage(_pickedBytes!) as ImageProvider
                    : (user.photoUrl != null
                        ? NetworkImage(user.photoUrl!)
                        : null),
                child: (_pickedBytes == null && user.photoUrl == null)
                    ? const Icon(Symbols.person, size: 48)
                    : null,
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Material(
                  color: kOrange,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _pickPhoto,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Symbols.camera_alt,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Center(child: Text(user.email)),
        Center(
          child: Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: BoxDecoration(
              color: kOrangeLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(roleLabel(user.role),
                style: const TextStyle(color: kOrange, fontSize: 12)),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _name,
          decoration: const InputDecoration(
              labelText: 'Full Name', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phone,
          decoration: const InputDecoration(
              labelText: 'Phone', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _hostel,
          decoration: const InputDecoration(
              labelText: 'Hostel', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _location,
          decoration: const InputDecoration(
              labelText: 'Other location / block',
              border: OutlineInputBorder()),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save changes'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red)),
          icon: const Icon(Symbols.logout),
          label: const Text('Logout'),
          onPressed: () => context.read<AuthProvider>().logout(),
        ),
      ],
    );
  }
}
