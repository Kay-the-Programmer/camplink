import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_colors.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/shopping_request.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_client.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';
import '../services/shopping_request_service.dart';
import '../services/storage_service.dart';
import '../widgets/notifications_bell.dart';
import '../widgets/product_card.dart';
import 'buyer/cart_screen.dart';
import 'buyer/leave_review_screen.dart';
import 'buyer/product_detail_screen.dart';
import 'common/chat_list_screen.dart';
import 'requests/create_request_screen.dart';
import 'seller/seller_orders_screen.dart';

// ── Tab index constants ───────────────────────────────────────────────────────
const kTabProducts = 0;
const kTabRides    = 1;
const kTabDelivery = 2;
const kTabOrders   = 3;
const kTabProfile  = 4;

// Legacy aliases kept so other files that reference the old names still compile.
const kTabShop     = kTabProducts;
const kTabMyStore  = kTabRides;
const kTabRequests = kTabDelivery;

// ── Shell ─────────────────────────────────────────────────────────────────────

class MainShell extends StatefulWidget {
  final int initialTab;
  const MainShell({super.key, this.initialTab = kTabShop});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> with TickerProviderStateMixin {
  late int _tab;
  late final TabController _reqTabCtrl;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    _reqTabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _reqTabCtrl.dispose();
    super.dispose();
  }

  void switchTab(int i) => setState(() => _tab = i);

  // ── AppBar per tab ──────────────────────────────────────────────────────────

  PreferredSizeWidget _appBar(BuildContext context) {
    switch (_tab) {
      case kTabShop:
        return _ShopAppBar();

      case kTabRides:
        return AppBar(
          title: const Text('Rides'),
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
        );

      case kTabDelivery:
        return AppBar(
          title: const Text('Delivery'),
          bottom: TabBar(
            controller: _reqTabCtrl,
            tabs: const [Tab(text: 'Available'), Tab(text: 'Mine')],
          ),
        );

      case kTabOrders:
        return AppBar(title: const Text('My Orders'));

      case kTabProfile:
        return AppBar(
          title: const Text('Profile'),
          actions: [
            IconButton(
              icon: const Icon(Symbols.logout),
              tooltip: 'Logout',
              onPressed: () => context.read<AuthProvider>().logout(),
            ),
          ],
        );

      default:
        return AppBar(title: const Text('CampLink'));
    }
  }

  // ── FAB per tab ─────────────────────────────────────────────────────────────

  Widget? _fab(BuildContext context) {
    switch (_tab) {
      case kTabRides:
        return FloatingActionButton.extended(
          icon: const Icon(Symbols.add),
          label: const Text('Post a ride'),
          onPressed: () {/* TODO: add ride screen */},
        );
      case kTabDelivery:
        return FloatingActionButton.extended(
          icon: const Icon(Symbols.add_task),
          label: const Text('Request delivery'),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CreateRequestScreen())),
        );
      default:
        return null;
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().count;

    return Scaffold(
      appBar: _appBar(context),
      floatingActionButton: _fab(context),
      body: IndexedStack(
        index: _tab,
        children: [
          const _ShopBody(),
          const _RidesBody(),
          _RequestsBody(ctrl: _reqTabCtrl),
          const _OrdersBody(),
          const _ProfileBody(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: _badge(cartCount, const Icon(Symbols.storefront)),
            selectedIcon: _badge(cartCount, const Icon(Symbols.storefront, fill: 1)),
            label: 'Products',
          ),
          const NavigationDestination(
            icon: Icon(Symbols.directions_car),
            selectedIcon: Icon(Symbols.directions_car, fill: 1),
            label: 'Rides',
          ),
          const NavigationDestination(
            icon: Icon(Symbols.delivery_dining),
            selectedIcon: Icon(Symbols.delivery_dining, fill: 1),
            label: 'Delivery',
          ),
          const NavigationDestination(
            icon: Icon(Symbols.receipt_long),
            selectedIcon: Icon(Symbols.receipt_long, fill: 1),
            label: 'Orders',
          ),
          const NavigationDestination(
            icon: Icon(Symbols.person),
            selectedIcon: Icon(Symbols.person, fill: 1),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  static Widget _badge(int n, Widget icon) =>
      n > 0 ? Badge(label: Text('$n'), child: icon) : icon;
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 0 — SHOP
// ═══════════════════════════════════════════════════════════════════════════════

class _ShopAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ShopAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return AppBar(
      title: const Text('CampLink'),
      actions: [
        const NotificationsBell(),
        IconButton(
          icon: const Icon(Symbols.chat_bubble),
          tooltip: 'Messages',
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ChatListScreen())),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Symbols.shopping_cart),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CartScreen())),
            ),
            if (cart.count > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                      color: Colors.red, shape: BoxShape.circle),
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text('${cart.count}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 10)),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ShopBody extends StatefulWidget {
  const _ShopBody();

  @override
  State<_ShopBody> createState() => _ShopBodyState();
}

class _ShopBodyState extends State<_ShopBody> {
  final _svc = ProductService();
  String _query = '';
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search products...',
              prefixIcon: Icon(Symbols.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _query = v.toLowerCase()),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: ['All', ...productCategories].map((c) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(c),
                  selected: c == _category,
                  onSelected: (_) => setState(() => _category = c),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: StreamBuilder<List<Product>>(
            stream: _svc.streamAll(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final all = snap.data ?? [];
              final filtered = all.where((p) {
                if (_category != 'All' && p.category != _category) return false;
                if (_query.isNotEmpty &&
                    !p.name.toLowerCase().contains(_query) &&
                    !p.description.toLowerCase().contains(_query)) {
                  return false;
                }
                return p.available;
              }).toList();
              if (filtered.isEmpty) {
                return const Center(child: Text('No products found.'));
              }
              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.72,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: filtered.length,
                itemBuilder: (_, i) => ProductCard(
                  product: filtered[i],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ProductDetailScreen(product: filtered[i])),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 1 — RIDES
// ═══════════════════════════════════════════════════════════════════════════════

class _RidesBody extends StatelessWidget {
  const _RidesBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Symbols.directions_car,
                size: 72, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            const Text(
              'Campus Rides',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Book or offer rides around campus.\nThis feature is coming soon.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 2 — DELIVERY
// ═══════════════════════════════════════════════════════════════════════════════

class _RequestsBody extends StatelessWidget {
  final TabController ctrl;
  const _RequestsBody({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: ctrl,
      children: const [
        _OpenRequestsPane(),
        _MyRequestsPane(),
      ],
    );
  }
}

class _OpenRequestsPane extends StatelessWidget {
  const _OpenRequestsPane();

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().user;
    final svc = ShoppingRequestService();
    return StreamBuilder<List<ShoppingRequest>>(
      stream: svc.streamOpen(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final open = (snap.data ?? [])
            .where((r) => r.requesterId != me?.uid)
            .toList();
        if (open.isEmpty) {
          return const Center(
              child: Text('No open requests.\nBe the first to post one!',
                  textAlign: TextAlign.center));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: open.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) =>
              _RequestCard(request: open[i], myUid: me?.uid, isRunner: true),
        );
      },
    );
  }
}

class _MyRequestsPane extends StatelessWidget {
  const _MyRequestsPane();

  @override
  Widget build(BuildContext context) {
    final svc = ShoppingRequestService();
    return StreamBuilder<List<ShoppingRequest>>(
      stream: svc.streamMine(),
      builder: (ctx, snapMine) {
        return StreamBuilder<List<ShoppingRequest>>(
          stream: svc.streamRunning(),
          builder: (ctx, snapRun) {
            final mine = snapMine.data ?? [];
            final running = snapRun.data ?? [];
            final all = {...mine, ...running}.toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            if (all.isEmpty) {
              return const Center(
                  child: Text(
                      'No activity yet.\nPost a request or accept one.',
                      textAlign: TextAlign.center));
            }
            final me = context.read<AuthProvider>().user;
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: all.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final r = all[i];
                final isRunner = running.any((x) => x.id == r.id);
                return _RequestCard(
                    request: r, myUid: me?.uid, isRunner: isRunner);
              },
            );
          },
        );
      },
    );
  }
}

class _RequestCard extends StatefulWidget {
  final ShoppingRequest request;
  final String? myUid;
  final bool isRunner;
  const _RequestCard(
      {required this.request, required this.myUid, required this.isRunner});

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _loading = false;
  final _svc = ShoppingRequestService();

  Color get _statusColor {
    switch (widget.request.status) {
      case RequestStatus.open:      return Colors.green;
      case RequestStatus.accepted:  return Colors.blue;
      case RequestStatus.fulfilled: return Colors.grey;
      case RequestStatus.cancelled: return Colors.red;
    }
  }

  Future<void> _act(Future<void> Function() fn) async {
    setState(() => _loading = true);
    try {
      await fn();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return Card(
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
              Chip(
                label: Text(r.status.name,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 11)),
                backgroundColor: _statusColor,
                padding: EdgeInsets.zero,
              ),
            ]),
            Text('by ${r.requesterName}',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 10),
            ...r.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    '• ${item.name}  ×${item.quantity}'
                    '${item.estimatedPrice != null ? '  (${kwacha.format(item.estimatedPrice!)} each)' : ''}'
                    '${item.notes != null ? '  — ${item.notes}' : ''}',
                    style: const TextStyle(fontSize: 13),
                  ),
                )),
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 4, children: [
              _chip(Symbols.home,
                  r.deliveryHostel +
                      (r.deliveryRoom != null ? ', ${r.deliveryRoom}' : '')),
              if (r.budget != null)
                _chip(Symbols.account_balance_wallet,
                    'Budget: ${kwacha.format(r.budget!)}'),
              if (r.runnerFee != null)
                _chip(Symbols.delivery_dining,
                    'Fee: ${kwacha.format(r.runnerFee!)}',
                    color: kOrange),
            ]),
            if (r.note != null) ...[
              const SizedBox(height: 6),
              Text(r.note!,
                  style: const TextStyle(
                      color: Colors.grey, fontSize: 12)),
            ],
            if (r.status == RequestStatus.accepted &&
                r.runnerName != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Symbols.directions_run, size: 16, color: kOrange),
                const SizedBox(width: 4),
                Text('Runner: ${r.runnerName}',
                    style: const TextStyle(color: kOrange, fontSize: 13)),
              ]),
            ],
            const Divider(height: 20),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              _actions(r),
          ],
        ),
      ),
    );
  }

  Widget _actions(ShoppingRequest r) {
    // Runner accepting an open request
    if (widget.isRunner && r.status == RequestStatus.open) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          icon: const Icon(Symbols.directions_run),
          label: const Text('Accept & run this'),
          onPressed: () => _act(() => _svc.accept(r.id)),
        ),
      );
    }
    // Runner marking fulfilled
    if (widget.isRunner &&
        r.status == RequestStatus.accepted &&
        r.runnerId == widget.myUid) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          icon: const Icon(Symbols.check_circle),
          label: const Text('Mark as delivered'),
          onPressed: () => _act(() => _svc.fulfill(r.id)),
        ),
      );
    }
    // Requester cancelling
    if (r.requesterId == widget.myUid &&
        (r.status == RequestStatus.open ||
            r.status == RequestStatus.accepted)) {
      return OutlinedButton.icon(
        icon: const Icon(Symbols.cancel, color: Colors.red),
        label: const Text('Cancel request',
            style: TextStyle(color: Colors.red)),
        onPressed: () => _act(() => _svc.cancel(r.id)),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _chip(IconData icon, String label, {Color? color}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: (color ?? Colors.grey).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: (color ?? Colors.grey).withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: color ?? Colors.grey),
          const SizedBox(width: 4),
          Text(label,
              style:
                  TextStyle(fontSize: 12, color: color ?? Colors.grey)),
        ]),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 3 — ORDERS
// ═══════════════════════════════════════════════════════════════════════════════

class _OrdersBody extends StatelessWidget {
  const _OrdersBody();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final svc = OrderService();
    if (user == null) return const Center(child: Text('Not logged in'));

    return StreamBuilder<List<AppOrder>>(
      stream: svc.streamForBuyer(user.uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snap.data ?? [];
        if (orders.isEmpty) {
          return const Center(child: Text('No orders yet.'));
        }
        return ListView.separated(
          itemCount: orders.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) => _OrderTile(order: orders[i]),
        );
      },
    );
  }
}

class _OrderTile extends StatelessWidget {
  final AppOrder order;
  const _OrderTile({required this.order});

  Color get _statusColor {
    switch (order.status) {
      case OrderStatus.pending:   return Colors.orange;
      case OrderStatus.confirmed: return Colors.blue;
      case OrderStatus.delivered: return Colors.green;
      case OrderStatus.cancelled: return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text('Order · ${kwacha.format(order.total)}'),
      subtitle:
          Text(DateFormat.yMMMd().add_jm().format(order.createdAt)),
      trailing: Chip(
        label: Text(order.status.name,
            style:
                const TextStyle(color: Colors.white, fontSize: 12)),
        backgroundColor: _statusColor,
        padding: EdgeInsets.zero,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...order.items.map((l) => Text(
                  '${l.name} x${l.quantity}  ·  '
                  '${kwacha.format(l.price * l.quantity)}')),
              const SizedBox(height: 8),
              Text('Delivery: ${order.deliveryMethod.name} → '
                  '${order.deliveryLocation}'),
              Text('Payment: ${paymentMethodLabel(order.paymentMethod)}'
                  ' (${order.paymentStatus.name})'),
              if (order.status == OrderStatus.delivered) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Symbols.star),
                  label: const Text('Leave a review'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            LeaveReviewScreen(order: order)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 4 — PROFILE
// ═══════════════════════════════════════════════════════════════════════════════

class _ProfileBody extends StatefulWidget {
  const _ProfileBody();

  @override
  State<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<_ProfileBody> {
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
    final u = context.read<AuthProvider>().user;
    _name     = TextEditingController(text: u?.fullName ?? '');
    _phone    = TextEditingController(text: u?.phone ?? '');
    _hostel   = TextEditingController(text: u?.hostel ?? '');
    _location = TextEditingController(text: u?.location ?? '');
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
    setState(() {
      _pickedPhoto = x;
      _pickedBytes = null;
    });
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
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const Center(child: Text('Not logged in'));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
            child: Text('Role: ${user.role.name}',
                style: const TextStyle(color: Colors.grey))),
        if (user.studentId != null)
          Center(child: Text('Student ID: ${user.studentId}')),
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
      ],
    );
  }
}
