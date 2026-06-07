import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_colors.dart';
import '../../models/product.dart';
import '../../models/ride_booking.dart';
import '../../services/product_service.dart';
import '../../services/ride_service.dart';
import '../../services/search_history_service.dart';
import '../../widgets/auth_prompt.dart';
import '../../widgets/product_card.dart';
import '../../widgets/search_suggestions_panel.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../buyer/product_detail_screen.dart';
import '../rides/book_ride_screen.dart';

class GuestHomeScreen extends StatefulWidget {
  const GuestHomeScreen({super.key});

  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen> {
  int _navIndex = 0; // 0 = Products, 1 = Rides, 2 = Delivery

  void _goToLogin() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );

  void _goToRegister() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RegisterScreen()),
      );

  static const _titles = ['Products', 'Rides', 'Delivery'];

  Widget? _fab() {
    if (_navIndex == 1) {
      return FloatingActionButton.extended(
        icon: const Icon(Symbols.directions_car),
        label: const Text('Book a Ride'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BookRideScreen()),
        ),
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_navIndex]),
        actions: [
          TextButton(
            onPressed: _goToLogin,
            child: const Text('Login'),
          ),
        ],
      ),
      floatingActionButton: _fab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Symbols.storefront),
            selectedIcon: Icon(Symbols.storefront, fill: 1),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Symbols.directions_car),
            selectedIcon: Icon(Symbols.directions_car, fill: 1),
            label: 'Rides',
          ),
          NavigationDestination(
            icon: Icon(Symbols.delivery_dining),
            selectedIcon: Icon(Symbols.delivery_dining, fill: 1),
            label: 'Delivery',
          ),
        ],
      ),
      body: IndexedStack(
        index: _navIndex,
        children: [
          _GuestProductsBody(
            onLogin: _goToLogin,
            onRegister: _goToRegister,
          ),
          const _GuestRidesBody(),
          _GuestLockedBody(
            icon: Symbols.delivery_dining,
            title: 'Campus Delivery',
            subtitle: 'Request delivery of items from anywhere on campus.',
            onLogin: _goToLogin,
            onRegister: _goToRegister,
          ),
        ],
      ),
    );
  }
}

// ── Products tab (browse freely) ──────────────────────────────────────────────

class _GuestProductsBody extends StatefulWidget {
  final VoidCallback onLogin;
  final VoidCallback onRegister;
  const _GuestProductsBody({required this.onLogin, required this.onRegister});

  @override
  State<_GuestProductsBody> createState() => _GuestProductsBodyState();
}

class _GuestProductsBodyState extends State<_GuestProductsBody> {
  final _productService = ProductService();
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
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        // Sign-up banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: scheme.primaryContainer,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Shop on campus',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Login or sign up to place orders.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: widget.onRegister,
                child: const Text('Sign up'),
              ),
            ],
          ),
        ),

        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
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
          // Category chips
          const SizedBox(height: 8),
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
          const SizedBox(height: 8),
        ],

        // Product grid or suggestions
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
                    stream: _productService.streamAll(),
                    builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}'));
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
                itemBuilder: (_, i) {
                  final p = filtered[i];
                  return ProductCard(
                    product: p,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(product: p),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
      ],
    );
  }
}

// ── Guest ride card ───────────────────────────────────────────────────────────

class _GuestRideCard extends StatelessWidget {
  final RideBooking ride;
  const _GuestRideCard({required this.ride});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type badge
            Row(children: [
              Icon(
                ride.type == RideType.instant ? Symbols.bolt : Symbols.schedule,
                size: 15,
                color: ride.type == RideType.instant
                    ? Colors.amber.shade700
                    : Colors.blue,
              ),
              const SizedBox(width: 4),
              Text(
                ride.type == RideType.instant ? 'Book Now' : 'Reserved',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ride.type == RideType.instant
                      ? Colors.amber.shade700
                      : Colors.blue,
                ),
              ),
              const Spacer(),
              if (ride.seats > 1)
                Text('${ride.seats} seats',
                    style: TextStyle(
                        fontSize: 12, color: scheme.onSurfaceVariant)),
            ]),
            const SizedBox(height: 12),

            // Route
            Row(children: [
              Column(children: [
                Container(
                  width: 10, height: 10,
                  decoration: const BoxDecoration(
                      color: Colors.green, shape: BoxShape.circle),
                ),
                Container(width: 2, height: 26, color: Colors.grey.shade300),
                Container(
                  width: 10, height: 10,
                  decoration: const BoxDecoration(
                      color: kOrange, shape: BoxShape.circle),
                ),
              ]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ride.from,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      const SizedBox(height: 14),
                      Text(ride.to,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                    ]),
              ),
            ]),

            if (ride.scheduledAt != null) ...[
              const SizedBox(height: 8),
              Row(children: [
                Icon(Symbols.schedule,
                    size: 14, color: scheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text(
                  'Scheduled: ${_fmt(ride.scheduledAt!)}',
                  style: TextStyle(
                      fontSize: 12, color: scheme.onSurfaceVariant),
                ),
              ]),
            ],

            const Divider(height: 20),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => showAuthPrompt(
                  context,
                  message:
                      'Sign in to book this ride from ${ride.from} to ${ride.to}.',
                ),
                child: const Text('Book this ride'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    final months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '${dt.day} ${months[dt.month - 1]}  •  $h:$m $ampm';
  }
}

// ── Rides / Delivery placeholder (login required) ─────────────────────────────

class _GuestLockedBody extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  const _GuestLockedBody({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onLogin,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: kOrange),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onLogin,
                child: const Text('Login to continue'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onRegister,
                child: const Text('Create account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Guest rides tab ───────────────────────────────────────────────────────────

class _GuestRidesBody extends StatefulWidget {
  const _GuestRidesBody();

  @override
  State<_GuestRidesBody> createState() => _GuestRidesBodyState();
}

class _GuestRidesBodyState extends State<_GuestRidesBody> {
  final _svc = RideService();

  void _openBooking({String? from, String? to}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookRideScreen(initialFrom: from, initialTo: to),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        // ── Sign-in nudge banner ─────────────────────────────────────────
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Campus Rides',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: scheme.onPrimaryContainer)),
                    const SizedBox(height: 2),
                    Text('Browse & book — sign in to confirm.',
                        style: TextStyle(
                            fontSize: 12,
                            color: scheme.onPrimaryContainer
                                .withValues(alpha: 0.8))),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: const Text('Sign in'),
              ),
            ]),
          ),
        ),

        // ── Quick booking card ───────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Card(
              elevation: 0,
              color: scheme.surfaceContainerHighest,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(children: [
                  ListTile(
                    leading: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: Colors.green.shade100, shape: BoxShape.circle),
                      child: Icon(Symbols.my_location,
                          size: 18, color: Colors.green.shade700),
                    ),
                    title: Text('Pickup location',
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                    subtitle: const Text('From', style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Symbols.chevron_right),
                    onTap: () => _openBooking(),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 28),
                    child: Divider(height: 1, color: scheme.outlineVariant),
                  ),
                  ListTile(
                    leading: Container(
                      width: 36, height: 36,
                      decoration: const BoxDecoration(
                          color: kOrangeLight, shape: BoxShape.circle),
                      child: const Icon(Symbols.location_on,
                          size: 18, color: kOrange),
                    ),
                    title: Text('Destination',
                        style: TextStyle(color: scheme.onSurfaceVariant)),
                    subtitle: const Text('To', style: TextStyle(fontSize: 11)),
                    trailing: const Icon(Symbols.chevron_right),
                    onTap: () => _openBooking(),
                  ),
                ]),
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // ── Available rides heading ──────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Available rides',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: scheme.onSurface)),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        // ── Ride list ────────────────────────────────────────────────────
        StreamBuilder<List<RideBooking>>(
          stream: _svc.streamPending(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SliverToBoxAdapter(
                child: Center(
                    child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                )),
              );
            }

            final rides = snap.data ?? [];

            if (rides.isEmpty) {
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Symbols.directions_car,
                          size: 52,
                          color: scheme.primary.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text('No rides posted yet',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface)),
                      const SizedBox(height: 6),
                      Text(
                        'Be the first — tap "Book a Ride" below.',
                        style: TextStyle(
                            fontSize: 13,
                            color: scheme.onSurfaceVariant),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
              sliver: SliverList.separated(
                itemCount: rides.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) =>
                    _GuestRideCard(ride: rides[i]),
              ),
            );
          },
        ),
      ],
    );
  }
}
