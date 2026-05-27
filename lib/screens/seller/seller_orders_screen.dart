import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../services/order_service.dart';

class SellerOrdersScreen extends StatelessWidget {
  const SellerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final svc = OrderService();
    return Scaffold(
      appBar: AppBar(title: const Text('Incoming Orders')),
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<List<AppOrder>>(
              stream: svc.streamForSeller(user.uid),
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
                  itemBuilder: (_, i) =>
                      _SellerOrderTile(order: orders[i], svc: svc),
                );
              },
            ),
    );
  }
}

class _SellerOrderTile extends StatelessWidget {
  final AppOrder order;
  final OrderService svc;
  const _SellerOrderTile({required this.order, required this.svc});

  Color _color(OrderStatus s) {
    switch (s) {
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
      title: Text('${order.buyerName} · ${kwacha.format(order.total)}'),
      subtitle: Text(DateFormat.yMMMd().add_jm().format(order.createdAt)),
      trailing: Chip(
        label: Text(order.status.name,
            style: const TextStyle(color: Colors.white, fontSize: 12)),
        backgroundColor: _color(order.status),
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
              Text('Buyer: ${order.buyerName} (${order.buyerPhone})'),
              Text('Delivery: ${order.deliveryMethod.name} → ${order.deliveryLocation}'),
              Text('Payment: ${paymentMethodLabel(order.paymentMethod)} (${order.paymentStatus.name})'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  if (order.status == OrderStatus.pending)
                    FilledButton(
                      onPressed: () =>
                          svc.updateStatus(order.id, OrderStatus.confirmed),
                      child: const Text('Confirm'),
                    ),
                  if (order.status == OrderStatus.pending ||
                      order.status == OrderStatus.confirmed)
                    OutlinedButton(
                      onPressed: () =>
                          svc.updateStatus(order.id, OrderStatus.cancelled),
                      child: const Text('Reject/Cancel'),
                    ),
                  if (order.status == OrderStatus.confirmed)
                    FilledButton.tonal(
                      onPressed: () =>
                          svc.updateStatus(order.id, OrderStatus.delivered),
                      child: const Text('Mark delivered'),
                    ),
                  if (order.paymentStatus == PaymentStatus.unpaid)
                    TextButton(
                      onPressed: () => svc.markPaid(order.id),
                      child: const Text('Mark paid'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
