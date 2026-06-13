import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app_colors.dart';
import '../models/app_user.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../models/ride_booking.dart';
import '../models/service_listing.dart';
import '../models/shopping_request.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_client.dart';
import '../services/order_service.dart';
import '../services/product_service.dart';
import '../services/ride_service.dart';
import '../services/service_listing_service.dart';
import '../services/shopping_request_service.dart';
import '../services/search_history_service.dart';
import '../widgets/confirm.dart';
import '../widgets/notifications_bell.dart';
import '../widgets/product_card.dart';
import '../widgets/profile_editor.dart';
import '../widgets/register_service_sheet.dart';
import '../widgets/search_suggestions_panel.dart';
import 'buyer/cart_screen.dart';
import 'buyer/leave_review_screen.dart';
import 'buyer/product_detail_screen.dart';
import 'common/chat_list_screen.dart';
import 'provider/provider_shell.dart';
import 'requests/create_request_screen.dart';
import 'rides/book_ride_screen.dart';

// ── Tab index constants ───────────────────────────────────────────────────────
const kTabProducts = 0;
const kTabRides    = 1;
const kTabDelivery = 2;
const kTabServices = 3;
const kTabOrders   = 4;
const kTabProfile  = 5;

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
  late final TabController _ridesTabCtrl;
  late final TabController _servicesTabCtrl;

  @override
  void initState() {
    super.initState();
    _tab = widget.initialTab;
    _reqTabCtrl      = TabController(length: 2, vsync: this);
    _ridesTabCtrl    = TabController(length: 2, vsync: this);
    _servicesTabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _reqTabCtrl.dispose();
    _ridesTabCtrl.dispose();
    _servicesTabCtrl.dispose();
    super.dispose();
  }

  void switchTab(int i) => setState(() => _tab = i);

  void _showRegisterServiceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => RegisterServiceSheet(
        onCreated: () {
          _servicesTabCtrl.animateTo(1);
        },
      ),
    );
  }

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
          ],
          bottom: TabBar(
            controller: _ridesTabCtrl,
            tabs: const [
              Tab(text: 'Available'),
              Tab(text: 'My Rides'),
            ],
          ),
        );

      case kTabDelivery:
        return AppBar(
          title: const Text('Delivery'),
          actions: [
            const NotificationsBell(),
            IconButton(
              icon: const Icon(Symbols.chat_bubble),
              tooltip: 'Messages',
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ChatListScreen())),
            ),
          ],
          // Tabs (the open pool) appear only for approved riders & drivers.
          bottom: canRunDeliveries(context.watch<AuthProvider>().user)
              ? TabBar(
                  controller: _reqTabCtrl,
                  tabs: const [Tab(text: 'Available'), Tab(text: 'My Jobs')],
                )
              : null,
        );

      case kTabServices:
        return AppBar(
          title: const Text('Services'),
          actions: [
            const NotificationsBell(),
            IconButton(
              icon: const Icon(Symbols.chat_bubble),
              tooltip: 'Messages',
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ChatListScreen())),
            ),
          ],
          bottom: TabBar(
            controller: _servicesTabCtrl,
            tabs: const [
              Tab(text: 'Browse'),
              Tab(text: 'My Listings'),
            ],
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
              onPressed: () async {
                final ok = await confirmAction(
                  context,
                  title: 'Log out?',
                  message: 'You will need to sign in again to continue.',
                  confirmLabel: 'Log out',
                  icon: Symbols.logout,
                  destructive: true,
                );
                if (ok && context.mounted) {
                  context.read<AuthProvider>().logout();
                }
              },
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
          icon: const Icon(Symbols.directions_car),
          label: const Text('Book a Ride'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BookRideScreen()),
          ),
        );
      case kTabDelivery:
        return FloatingActionButton.extended(
          icon: const Icon(Symbols.add_task),
          label: const Text('Request delivery'),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CreateRequestScreen())),
        );
      case kTabServices:
        return FloatingActionButton.extended(
          icon: const Icon(Symbols.add_business),
          label: const Text('Register Service'),
          onPressed: () => _showRegisterServiceSheet(context),
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
          _RidesBody(ctrl: _ridesTabCtrl),
          _RequestsBody(ctrl: _reqTabCtrl),
          _ServicesBody(ctrl: _servicesTabCtrl),
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
            icon: Icon(Symbols.handyman),
            selectedIcon: Icon(Symbols.handyman, fill: 1),
            label: 'Services',
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
  final _historySvc = SearchHistoryService();
  final _focus = FocusNode();
  final _ctrl = TextEditingController();
  String _query = '';
  String _category = 'All';
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) setState(() => _focused = _focus.hasFocus);
    if (!_focus.hasFocus && _query.isNotEmpty) {
      _historySvc.add(_query);
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _selectSuggestion(String q) {
    _historySvc.add(q);
    _ctrl.text = q;
    setState(() => _query = q.toLowerCase());
    _focus.unfocus();
  }

  bool get _showSuggestions => _focused && _query.isEmpty;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            focusNode: _focus,
            controller: _ctrl,
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Symbols.search),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Symbols.close),
                      onPressed: () {
                        _ctrl.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _query = v.toLowerCase()),
            onSubmitted: (v) {
              if (v.trim().isNotEmpty) _historySvc.add(v.trim());
            },
          ),
        ),
        if (!_showSuggestions) ...[
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
        ],
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _showSuggestions
                ? SearchSuggestionsPanel(
                    key: const ValueKey('suggestions'),
                    onSelect: _selectSuggestion,
                  )
                : StreamBuilder<List<Product>>(
                    key: const ValueKey('grid'),
                    stream: _svc.streamAll(),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final all = snap.data ?? [];
                      final filtered = all.where((p) {
                        if (_category != 'All' && p.category != _category) {
                          return false;
                        }
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
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 1 — RIDES
// ═══════════════════════════════════════════════════════════════════════════════

class _RidesBody extends StatelessWidget {
  final TabController ctrl;
  const _RidesBody({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: ctrl,
      children: const [
        _AvailableRidesPane(),
        _MyRidesPane(),
      ],
    );
  }
}

// ── Available rides (pending bookings from other passengers) ──────────────────

class _AvailableRidesPane extends StatelessWidget {
  const _AvailableRidesPane();

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().user;
    final svc = RideService();
    return StreamBuilder<List<RideBooking>>(
      stream: svc.streamPending(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final rides = (snap.data ?? [])
            .where((r) => r.passengerId != me?.uid)
            .toList();
        if (rides.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Symbols.directions_car,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                const Text('No ride requests yet',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  'When other students post ride requests, they\'ll appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ]),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: rides.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) =>
              _RideCard(ride: rides[i], myUid: me?.uid, isDriver: true),
        );
      },
    );
  }
}

// ── My rides ──────────────────────────────────────────────────────────────────

class _MyRidesPane extends StatelessWidget {
  const _MyRidesPane();

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().user;
    final svc = RideService();
    return StreamBuilder<List<RideBooking>>(
      stream: svc.streamMine(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final rides = snap.data ?? [];
        if (rides.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Symbols.hail,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                const Text('No rides yet',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  'Tap "Book a Ride" below to request a campus ride.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ]),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: rides.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) =>
              _RideCard(ride: rides[i], myUid: me?.uid, isDriver: false),
        );
      },
    );
  }
}

// ── Ride card ─────────────────────────────────────────────────────────────────

class _RideCard extends StatefulWidget {
  final RideBooking ride;
  final String? myUid;
  final bool isDriver;
  const _RideCard(
      {required this.ride, required this.myUid, required this.isDriver});

  @override
  State<_RideCard> createState() => _RideCardState();
}

class _RideCardState extends State<_RideCard> {
  bool _loading = false;
  final _svc = RideService();

  Color get _statusColor {
    switch (widget.ride.status) {
      case RideStatus.pending:    return Colors.orange;
      case RideStatus.accepted:   return Colors.blue;
      case RideStatus.inProgress: return Colors.indigo;
      case RideStatus.completed:  return Colors.green;
      case RideStatus.cancelled:  return Colors.red;
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
    final r = widget.ride;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ─────────────────────────────────────────────────
            Row(children: [
              Expanded(
                child: Row(children: [
                  Icon(
                    r.type == RideType.instant ? Symbols.bolt : Symbols.schedule,
                    size: 16,
                    color: r.type == RideType.instant
                        ? Colors.amber.shade700
                        : Colors.blue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    r.type == RideType.instant ? 'Book Now' : 'Reserved',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: r.type == RideType.instant
                            ? Colors.amber.shade700
                            : Colors.blue),
                  ),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(rideStatusLabel(r.status),
                    style: TextStyle(
                        fontSize: 11,
                        color: _statusColor,
                        fontWeight: FontWeight.w600)),
              ),
            ]),

            const SizedBox(height: 12),

            // ── Route ──────────────────────────────────────────────────────
            Row(
              children: [
                Column(children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [BoxShadow(color: Colors.green.shade200, blurRadius: 4)],
                    ),
                  ),
                  Container(
                    width: 2, height: 28,
                    color: Colors.grey.shade300,
                  ),
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: kOrange,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [BoxShadow(color: kOrange.withValues(alpha: 0.3), blurRadius: 4)],
                    ),
                  ),
                ]),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.from,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 16),
                      Text(r.to,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Chips row ──────────────────────────────────────────────────
            Wrap(spacing: 6, runSpacing: 4, children: [
              _chip(
                r.direction == RouteDirection.campusToTown
                    ? Symbols.school
                    : Symbols.location_city,
                r.direction == RouteDirection.campusToTown
                    ? 'Campus → Town'
                    : 'Town → Campus',
              ),
              if (r.direction == RouteDirection.townToCampus)
                _chip(
                  r.dropOff == DropOff.across
                      ? Symbols.directions_walk
                      : Symbols.school,
                  r.dropOffLabel,
                  color: r.dropOff == DropOff.across
                      ? Colors.green
                      : kOrange,
                ),
              _chip(Symbols.person,
                  '${r.seats} seat${r.seats > 1 ? 's' : ''}'),
              if (r.scheduledAt != null)
                _chip(Symbols.schedule,
                    DateFormat('d MMM  •  h:mm a').format(r.scheduledAt!),
                    color: Colors.blue),
              if (r.fare != null)
                _chip(Symbols.account_balance_wallet,
                    'K${r.fare!.toStringAsFixed(0)}',
                    color: Colors.green),
            ]),

            if (r.note != null && r.note!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(r.note!,
                  style: TextStyle(
                      fontSize: 12, color: scheme.onSurfaceVariant)),
            ],

            // ── Driver info ────────────────────────────────────────────────
            if (r.driverName != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Symbols.directions_car, size: 15, color: kOrange),
                const SizedBox(width: 4),
                Text('Driver: ${r.driverName}',
                    style: const TextStyle(
                        color: kOrange, fontSize: 13)),
              ]),
            ],

            // ── Passenger name (shown on Available tab) ────────────────────
            if (widget.isDriver) ...[
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Symbols.person, size: 15, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Requested by ${r.passengerName}',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
              ]),
            ],

            const Divider(height: 20),

            if (_loading)
              const Center(child: CircularProgressIndicator())
            else
              _actions(r, scheme),
          ],
        ),
      ),
    );
  }

  Widget _actions(RideBooking r, ColorScheme scheme) {
    // Driver view — accept a pending ride
    if (widget.isDriver && r.status == RideStatus.pending) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          icon: const Icon(Symbols.directions_car),
          label: const Text('Accept this ride'),
          onPressed: () => _act(() => _svc.accept(r.id)),
        ),
      );
    }
    // Driver view — mark as complete
    if (widget.isDriver &&
        r.status == RideStatus.accepted &&
        r.driverId == widget.myUid) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          icon: const Icon(Symbols.check_circle),
          label: const Text('Mark as completed'),
          onPressed: () => _act(() => _svc.complete(r.id)),
        ),
      );
    }
    // Passenger view — cancel active ride
    if (!widget.isDriver &&
        r.passengerId == widget.myUid &&
        r.isActive) {
      return OutlinedButton.icon(
        icon: const Icon(Symbols.cancel, color: Colors.red),
        label: const Text('Cancel ride',
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
          border:
              Border.all(color: (color ?? Colors.grey).withValues(alpha: 0.3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 12, color: color ?? Colors.grey),
          const SizedBox(width: 4),
          Text(label,
              style:
                  TextStyle(fontSize: 11, color: color ?? Colors.grey)),
        ]),
      );
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 2 — DELIVERY
// ═══════════════════════════════════════════════════════════════════════════════

class _RequestsBody extends StatelessWidget {
  final TabController ctrl;
  const _RequestsBody({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().user;

    // Approved riders & drivers get the open pool plus their jobs. Everyone
    // else only ever sees the requests they posted — the pool stays hidden.
    if (canRunDeliveries(me)) {
      return TabBarView(
        controller: ctrl,
        children: const [
          _OpenRequestsPane(),
          _MyRequestsPane(),
        ],
      );
    }
    return const _MyRequestsPane();
  }
}

/// The open delivery pool. Only ever rendered for approved riders & drivers
/// (the parent gates on [canRunDeliveries]), so no in-widget role check needed.
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
          return const _DeliveryEmpty(
            icon: Symbols.inbox,
            title: 'No open requests',
            message: 'New delivery requests from students will show up here.',
          );
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

/// Reusable centred empty-state for the delivery panes.
class _DeliveryEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  const _DeliveryEmpty(
      {required this.icon, required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 64,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(title,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600)),
          ],
        ),
      ),
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
            final me = context.watch<AuthProvider>().user;
            final mine = snapMine.data ?? [];
            final running = snapRun.data ?? [];
            final all = {...mine, ...running}.toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            if (all.isEmpty) {
              return _DeliveryEmpty(
                icon: Symbols.delivery_dining,
                title: 'No delivery requests yet',
                message: canRunDeliveries(me)
                    ? 'Jobs you accept and requests you post will appear here.'
                    : 'Tap "Request delivery" to ask a campus runner to fetch '
                        'something for you.',
              );
            }
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

  /// Set once an action (accept / fulfil / cancel) succeeds, so the card shows
  /// instant confirmation instead of waiting up to 20s for the next poll.
  bool _done = false;

  Future<void> _act(Future<void> Function() fn,
      {String? success, bool markDone = false}) async {
    setState(() => _loading = true);
    try {
      await fn();
      if (!mounted) return;
      if (success != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(success)));
      }
      if (markDone) setState(() => _done = true);
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
    // Once an action has succeeded, confirm it inline until the list refreshes.
    if (_done) {
      return Row(children: [
        Icon(Symbols.check_circle, size: 18, color: Colors.green.shade600),
        const SizedBox(width: 6),
        Text('Done', style: TextStyle(color: Colors.green.shade700)),
      ]);
    }
    // Runner accepting an open request
    if (widget.isRunner && r.status == RequestStatus.open) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          icon: const Icon(Symbols.directions_run),
          label: const Text('Accept & run this'),
          onPressed: () => _act(() => _svc.accept(r.id),
              success: 'Delivery accepted! Find it under "Mine".',
              markDone: true),
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
          onPressed: () => _act(() => _svc.fulfill(r.id),
              success: 'Marked as delivered.', markDone: true),
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
        onPressed: () => _act(() => _svc.cancel(r.id),
            success: 'Request cancelled.', markDone: true),
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

class _ProfileBody extends StatelessWidget {
  const _ProfileBody();

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    // Providers see their dashboard/verification card; buyers see the option to
    // upgrade to a provider account. Logout lives in the app bar here.
    Widget? extra;
    if (user != null) {
      if (isProvider(user.role)) {
        extra = _ProviderCard(user: user);
      } else if (user.role == UserRole.buyer) {
        extra = const _UpgradeCard();
      }
    }
    return ProfileEditor(extra: extra);
  }
}

// ── Provider access / verification card (shown in Profile) ────────────────────

/// For seller / rider / driver accounts. Surfaces the provider dashboard once
/// approved, or the verification status while pending / rejected — without ever
/// blocking access to the rest of the marketplace.
class _ProviderCard extends StatefulWidget {
  final AppUser user;
  const _ProviderCard({required this.user});

  @override
  State<_ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends State<_ProviderCard> {
  bool _checking = false;

  Future<void> _checkStatus() async {
    setState(() => _checking = true);
    await context.read<AuthProvider>().refreshProfile();
    if (mounted) setState(() => _checking = false);
  }

  String get _providerNoun {
    switch (widget.user.role) {
      case UserRole.seller: return 'products';
      case UserRole.rider:  return 'rides';
      case UserRole.driver: return 'deliveries';
      default:              return 'listings';
    }
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final status = u.verificationStatus ?? VerificationStatus.pending;

    // Approved → entry point to the provider dashboard.
    if (status == VerificationStatus.approved) {
      return _CardShell(
        color: kOrangeLight,
        icon: Symbols.dashboard,
        iconColor: kOrange,
        title: '${roleLabel(u.role)} dashboard',
        body: 'Manage your $_providerNoun and incoming activity.',
        action: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Symbols.arrow_forward),
            label: const Text('Open dashboard'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProviderShell()),
            ),
          ),
        ),
      );
    }

    // Pending → status + manual refresh, but full app access remains.
    if (status == VerificationStatus.pending) {
      return _CardShell(
        color: Colors.orange.shade50,
        icon: Symbols.hourglass_empty,
        iconColor: Colors.orange.shade700,
        title: '${roleLabel(u.role)} application under review',
        body: 'You can shop and use the whole app while our team reviews your '
            "application. We'll let you know once it's approved.",
        action: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: _checking
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Symbols.refresh),
            label: const Text('Check status'),
            onPressed: _checking ? null : _checkStatus,
          ),
        ),
      );
    }

    // Rejected → reason + support, still a usable buyer account.
    return _CardShell(
      color: Colors.red.shade50,
      icon: Symbols.cancel,
      iconColor: Colors.red.shade600,
      title: '${roleLabel(u.role)} application not approved',
      body: (u.rejectionReason != null && u.rejectionReason!.isNotEmpty)
          ? u.rejectionReason!
          : 'Your provider application was not approved. You can still shop and '
              'order as a buyer.',
      action: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          icon: const Icon(Symbols.mail),
          label: const Text('Contact support'),
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please email support@camplink.app')),
          ),
        ),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  final Color color;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final Widget action;

  const _CardShell({
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ]),
          const SizedBox(height: 8),
          Text(body,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade700, height: 1.4)),
          const SizedBox(height: 14),
          action,
        ],
      ),
    );
  }
}

// ── Buyer → provider upgrade card (shown in Profile) ──────────────────────────

/// Lets a buyer request a provider account. Buyers can only buy; to list
/// products/services or run rides/deliveries they request an upgrade, which an
/// admin reviews via the existing verification flow.
class _UpgradeCard extends StatefulWidget {
  const _UpgradeCard();

  @override
  State<_UpgradeCard> createState() => _UpgradeCardState();
}

class _UpgradeCardState extends State<_UpgradeCard> {
  bool _busy = false;

  Future<void> _request() async {
    final role = await showModalBottomSheet<UserRole>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _UpgradeRolePicker(),
    );
    if (role == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await context.read<AuthProvider>().requestUpgrade(role);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Upgrade requested — an admin will review your account.')));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      color: kOrangeLight,
      icon: Symbols.storefront,
      iconColor: kOrange,
      title: 'Start selling on CampLink',
      body: 'Want to sell products, offer rides, or run deliveries? Request a '
          'provider account and an admin will review it. You can keep shopping '
          'in the meantime.',
      action: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          icon: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Icon(Symbols.upgrade),
          label: const Text('Request upgrade'),
          onPressed: _busy ? null : _request,
        ),
      ),
    );
  }
}

/// Bottom sheet to choose which provider role to request.
class _UpgradeRolePicker extends StatelessWidget {
  const _UpgradeRolePicker();

  @override
  Widget build(BuildContext context) {
    const options = [
      (UserRole.seller, Symbols.storefront, 'Seller',
          'List products and fulfil orders.'),
      (UserRole.rider, Symbols.directions_car, 'Rider',
          'Offer campus rides and earn from bookings.'),
      (UserRole.driver, Symbols.delivery_dining, 'Delivery Driver',
          'Accept and complete delivery requests.'),
    ];
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('What would you like to become?',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          ...options.map((o) => ListTile(
                leading: CircleAvatar(
                  backgroundColor: kOrangeLight,
                  child: Icon(o.$2, color: kOrange),
                ),
                title: Text(o.$3,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(o.$4),
                trailing: const Icon(Symbols.chevron_right),
                onTap: () => Navigator.pop(context, o.$1),
              )),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TAB 3 — SERVICES
// ═══════════════════════════════════════════════════════════════════════════════

class _ServicesBody extends StatelessWidget {
  final TabController ctrl;
  const _ServicesBody({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return TabBarView(
      controller: ctrl,
      children: const [
        _BrowseServicesPane(),
        _MyServicesPane(),
      ],
    );
  }
}

// ── Browse all services ───────────────────────────────────────────────────────

class _BrowseServicesPane extends StatefulWidget {
  const _BrowseServicesPane();

  @override
  State<_BrowseServicesPane> createState() => _BrowseServicesPaneState();
}

class _BrowseServicesPaneState extends State<_BrowseServicesPane> {
  final _svc = ServiceListingService();
  final _ctrl = TextEditingController();
  String _query = '';
  ServiceCategory? _category;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: TextField(
            controller: _ctrl,
            decoration: InputDecoration(
              hintText: 'Search services...',
              prefixIcon: const Icon(Symbols.search),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Symbols.close),
                      onPressed: () {
                        _ctrl.clear();
                        setState(() => _query = '');
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _query = v.toLowerCase()),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('All'),
                  selected: _category == null,
                  onSelected: (_) => setState(() => _category = null),
                ),
              ),
              ...ServiceCategory.values.map((c) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(serviceCategoryLabel(c)),
                      selected: _category == c,
                      onSelected: (_) =>
                          setState(() => _category = _category == c ? null : c),
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: StreamBuilder<List<ServiceListing>>(
            stream: _svc.streamAll(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final all = snap.data ?? [];
              final filtered = all.where((s) {
                if (!s.available) return false;
                if (_category != null && s.category != _category) return false;
                if (_query.isNotEmpty &&
                    !s.title.toLowerCase().contains(_query) &&
                    !s.description.toLowerCase().contains(_query) &&
                    !s.providerName.toLowerCase().contains(_query)) {
                  return false;
                }
                return true;
              }).toList();
              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Symbols.handyman,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.4)),
                      const SizedBox(height: 16),
                      const Text('No services found',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(
                        'Be the first to register a service for your fellow students.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ]),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) =>
                    _ServiceCard(listing: filtered[i], isOwner: false),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── My service listings ───────────────────────────────────────────────────────

class _MyServicesPane extends StatelessWidget {
  const _MyServicesPane();

  @override
  Widget build(BuildContext context) {
    final svc = ServiceListingService();
    return StreamBuilder<List<ServiceListing>>(
      stream: svc.streamMine(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final listings = snap.data ?? [];
        if (listings.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Symbols.add_business,
                    size: 64,
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.4)),
                const SizedBox(height: 16),
                const Text('No listings yet',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  'Tap "Register Service" below to advertise what you offer.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ]),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: listings.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) =>
              _ServiceCard(listing: listings[i], isOwner: true),
        );
      },
    );
  }
}

// ── Service card ──────────────────────────────────────────────────────────────

class _ServiceCard extends StatefulWidget {
  final ServiceListing listing;
  final bool isOwner;
  const _ServiceCard({required this.listing, required this.isOwner});

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _loading = false;
  final _svc = ServiceListingService();

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
    final l = widget.listing;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(l.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (l.available ? Colors.green : Colors.grey)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: (l.available ? Colors.green : Colors.grey)
                          .withValues(alpha: 0.4)),
                ),
                child: Text(
                  l.available ? 'Available' : 'Unavailable',
                  style: TextStyle(
                      fontSize: 11,
                      color: l.available ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Symbols.person, size: 13, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(l.providerName,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600)),
            ]),
            const SizedBox(height: 8),
            Text(l.description,
                style: TextStyle(
                    fontSize: 13, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 10),
            Wrap(spacing: 6, runSpacing: 4, children: [
              _chip(
                _categoryIcon(l.category),
                serviceCategoryLabel(l.category),
              ),
              if (l.price != null)
                _chip(Symbols.account_balance_wallet,
                    'K${l.price!.toStringAsFixed(0)}',
                    color: Colors.green),
              if (l.priceNote != null && l.priceNote!.isNotEmpty)
                _chip(Symbols.info, l.priceNote!),
            ]),
            if (l.providerPhone != null && l.providerPhone!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Symbols.phone, size: 14, color: kOrange),
                const SizedBox(width: 4),
                Text(l.providerPhone!,
                    style:
                        const TextStyle(color: kOrange, fontSize: 13)),
              ]),
            ],
            if (widget.isOwner) ...[
              const Divider(height: 20),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(
                          l.available ? Symbols.pause : Symbols.play_arrow),
                      label: Text(
                          l.available ? 'Mark unavailable' : 'Mark available'),
                      onPressed: () => _act(
                          () => _svc.toggleAvailability(l.id, !l.available)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Symbols.delete, color: Colors.red),
                    tooltip: 'Delete listing',
                    onPressed: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Delete listing?'),
                          content: const Text(
                              'This will remove your service listing permanently.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel')),
                            FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete')),
                          ],
                        ),
                      );
                      if (ok == true) _act(() => _svc.delete(l.id));
                    },
                  ),
                ]),
            ],
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(ServiceCategory c) {
    switch (c) {
      case ServiceCategory.tutoring:    return Symbols.school;
      case ServiceCategory.haircut:     return Symbols.content_cut;
      case ServiceCategory.laundry:     return Symbols.local_laundry_service;
      case ServiceCategory.food:        return Symbols.restaurant;
      case ServiceCategory.techHelp:    return Symbols.computer;
      case ServiceCategory.photography: return Symbols.photo_camera;
      case ServiceCategory.design:      return Symbols.brush;
      case ServiceCategory.other:       return Symbols.handyman;
    }
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
          Icon(icon, size: 12, color: color ?? Colors.grey),
          const SizedBox(width: 4),
          Text(label,
              style:
                  TextStyle(fontSize: 11, color: color ?? Colors.grey)),
        ]),
      );
}
