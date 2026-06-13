import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_colors.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import 'leave_review_screen.dart';

/// Full detail view for a single order. Reached from the orders list or by
/// tapping an order notification.
class OrderDetailScreen extends StatelessWidget {
  final AppOrder order;
  const OrderDetailScreen({super.key, required this.order});

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
    return Scaffold(
      appBar: AppBar(title: const Text('Order details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Status + total header ──────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  kwacha.format(order.total),
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: kOrange),
                ),
              ),
              Chip(
                label: Text(order.status.name,
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
                backgroundColor: _statusColor,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(DateFormat.yMMMMd().add_jm().format(order.createdAt),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const Divider(height: 32),

          // ── Items ──────────────────────────────────────────────────────
          const _SectionLabel('Items'),
          ...order.items.map((l) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(child: Text('${l.name}  ×${l.quantity}')),
                    Text(kwacha.format(l.price * l.quantity),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              )),
          const Divider(height: 32),

          // ── Parties ────────────────────────────────────────────────────
          _DetailRow(
              icon: Symbols.storefront, label: 'Seller', value: order.sellerName),
          _DetailRow(
              icon: Symbols.person, label: 'Buyer', value: order.buyerName),
          if (order.buyerPhone.isNotEmpty)
            _DetailRow(
                icon: Symbols.phone, label: 'Phone', value: order.buyerPhone),
          const Divider(height: 32),

          // ── Delivery & payment ─────────────────────────────────────────
          _DetailRow(
            icon: order.deliveryMethod == DeliveryMethod.pickup
                ? Symbols.storefront
                : Symbols.local_shipping,
            label: order.deliveryMethod == DeliveryMethod.pickup
                ? 'Pickup'
                : 'Delivery',
            value: order.deliveryLocation,
          ),
          _DetailRow(
            icon: Symbols.payments,
            label: paymentMethodLabel(order.paymentMethod),
            value: order.paymentStatus == PaymentStatus.paid ? 'Paid' : 'Unpaid',
          ),

          if (order.status == OrderStatus.delivered) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
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
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      );
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                Text(value.isEmpty ? '—' : value,
                    style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
