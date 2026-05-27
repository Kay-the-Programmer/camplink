import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';
import 'leave_review_screen.dart';

class BuyerOrdersScreen extends StatelessWidget {
  const BuyerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final svc = OrderService();
    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<List<AppOrder>>(
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
            ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  final AppOrder order;
  const _OrderTile({required this.order});

  Color get _statusColor {
    switch (order.status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text('Order · ${kwacha.format(order.total)}'),
      subtitle: Text(DateFormat.yMMMd().add_jm().format(order.createdAt)),
      trailing: Chip(
        label: Text(order.status.name,
            style: const TextStyle(color: Colors.white, fontSize: 12)),
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
                  '${l.name} x${l.quantity}  ·  ${kwacha.format(l.price * l.quantity)}')),
              const SizedBox(height: 8),
              Text(
                  'Delivery: ${order.deliveryMethod.name} → ${order.deliveryLocation}'),
              Text(
                  'Payment: ${paymentMethodLabel(order.paymentMethod)} (${order.paymentStatus.name})'),
              if (order.status == OrderStatus.delivered) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Symbols.star),
                  label: const Text('Leave a review'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => LeaveReviewScreen(order: order)),
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
