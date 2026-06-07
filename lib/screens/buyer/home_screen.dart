import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../services/product_service.dart';
import '../../services/search_history_service.dart';
import '../../widgets/notifications_bell.dart';
import '../../widgets/product_card.dart';
import '../../widgets/search_suggestions_panel.dart';
import '../common/chat_list_screen.dart';
import 'cart_screen.dart';
import 'product_detail_screen.dart';

class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
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
    final cart = context.watch<CartProvider>();
    return Scaffold(
      appBar: AppBar(
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
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Colors.red, shape: BoxShape.circle),
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text('${cart.count}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11)),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
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
            const SizedBox(height: 8),
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
                      stream: _productService.streamAll(),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snap.hasError) {
                          return Center(child: Text('Error: ${snap.error}'));
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
                          return const Center(
                              child: Text('No products found.'));
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
                                    builder: (_) =>
                                        ProductDetailScreen(product: p)),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
