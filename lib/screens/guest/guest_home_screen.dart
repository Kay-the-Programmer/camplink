import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_colors.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../widgets/product_card.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../buyer/product_detail_screen.dart';

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
          _GuestLockedBody(
            icon: Symbols.directions_car,
            title: 'Campus Rides',
            subtitle: 'Book and share rides around campus with other students.',
            onLogin: _goToLogin,
            onRegister: _goToRegister,
          ),
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
  String _query = '';
  String _category = 'All';

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
            decoration: const InputDecoration(
              hintText: 'Search products...',
              prefixIcon: Icon(Symbols.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _query = v.toLowerCase()),
          ),
        ),

        // Category chips
        const SizedBox(height: 8),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: ['All', ...productCategories].map((c) {
              final selected = c == _category;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(c),
                  selected: selected,
                  onSelected: (_) => setState(() => _category = c),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),

        // Product grid
        Expanded(
          child: StreamBuilder<List<Product>>(
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
      ],
    );
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

// ── Auth prompt bottom sheet (reusable) ───────────────────────────────────────

void showAuthPrompt(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) => _AuthPromptSheet(parentContext: context),
  );
}

class _AuthPromptSheet extends StatelessWidget {
  final BuildContext parentContext;
  const _AuthPromptSheet({required this.parentContext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Symbols.lock, size: 48, color: kOrange),
          const SizedBox(height: 12),
          const Text(
            'Login to continue',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create an account or log in to add items to your cart and place orders.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  parentContext,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('Login'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  parentContext,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              child: const Text('Create account'),
            ),
          ),
        ],
      ),
    );
  }
}
