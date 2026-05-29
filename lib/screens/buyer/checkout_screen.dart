import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../app_colors.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../models/ride_booking.dart' show campusLocations;
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../services/order_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  DeliveryMethod _delivery = DeliveryMethod.delivery;
  PaymentMethod _payment = PaymentMethod.cashOnDelivery;
  String? _location;
  final _customLocation = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _location = user?.hostel ?? user?.location;
  }

  @override
  void dispose() {
    _customLocation.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    final cart = context.read<CartProvider>();
    final auth = context.read<AuthProvider>();
    final sellerId = cart.singleSellerId;
    if (sellerId == null || auth.user == null) return;

    final loc = _delivery == DeliveryMethod.pickup
        ? 'Pickup at seller'
        : (_customLocation.text.trim().isNotEmpty
            ? _customLocation.text.trim()
            : (_location ?? ''));
    if (_delivery == DeliveryMethod.delivery && loc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a delivery location.')),
      );
      return;
    }

    setState(() => _busy = true);
    try {
      final order = await OrderService().place(
        items: cart.items,
        deliveryMethod: _delivery,
        deliveryLocation: loc,
        paymentMethod: _payment,
      );
      cart.clear();
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Order placed!'),
            content: Text(
                'Total: ${kwacha.format(order.total)}\nPayment: ${paymentMethodLabel(order.paymentMethod)}\n\nYou will be notified when the seller confirms.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to place order: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Order summary',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...cart.items.map((i) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text('${i.product.name} x${i.quantity}'),
                trailing: Text(kwacha.format(i.subtotal)),
              )),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(kwacha.format(cart.total),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kOrange)),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Delivery method',
              style: TextStyle(fontWeight: FontWeight.bold)),
          SegmentedButton<DeliveryMethod>(
            segments: const [
              ButtonSegment(
                  value: DeliveryMethod.delivery,
                  label: Text('Delivery'),
                  icon: Icon(Symbols.delivery_dining)),
              ButtonSegment(
                  value: DeliveryMethod.pickup,
                  label: Text('Pickup'),
                  icon: Icon(Symbols.store)),
            ],
            selected: {_delivery},
            onSelectionChanged: (s) => setState(() => _delivery = s.first),
          ),
          if (_delivery == DeliveryMethod.delivery) ...[
            const SizedBox(height: 16),
            const Text('Delivery location',
                style: TextStyle(fontWeight: FontWeight.bold)),
            DropdownButtonFormField<String>(
              initialValue: campusLocations.contains(_location) ? _location : null,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              hint: const Text('Select location'),
              items: campusLocations
                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                  .toList(),
              onChanged: (v) => setState(() => _location = v),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _customLocation,
              decoration: const InputDecoration(
                labelText: 'Or enter custom location (e.g. block/room)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Text('Payment method',
              style: TextStyle(fontWeight: FontWeight.bold)),
          RadioGroup<PaymentMethod>(
            groupValue: _payment,
            onChanged: (v) {
              if (v != null) setState(() => _payment = v);
            },
            child: Column(
              children: PaymentMethod.values
                  .map((m) => RadioListTile<PaymentMethod>(
                        value: m,
                        title: Text(paymentMethodLabel(m)),
                        contentPadding: EdgeInsets.zero,
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: _busy ? null : _placeOrder,
            child: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Place Order'),
          ),
        ),
      ),
    );
  }
}
