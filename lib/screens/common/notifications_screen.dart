import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../app_colors.dart';
import '../../models/notification.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';
import '../../services/order_service.dart';
import '../buyer/order_detail_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _icon(NotificationType t) {
    switch (t) {
      case NotificationType.orderPlaced:
        return Symbols.shopping_bag;
      case NotificationType.orderConfirmed:
        return Symbols.check_circle;
      case NotificationType.orderDelivered:
        return Symbols.local_shipping;
      case NotificationType.orderCancelled:
        return Symbols.cancel;
      case NotificationType.paymentConfirmed:
        return Symbols.payments;
      case NotificationType.message:
        return Symbols.chat;
      case NotificationType.requestAccepted:
        return Symbols.directions_run;
      case NotificationType.requestFulfilled:
        return Symbols.check_circle;
      case NotificationType.rideAccepted:
        return Symbols.directions_car;
      case NotificationType.rideCompleted:
        return Symbols.where_to_vote;
      case NotificationType.rideCancelled:
        return Symbols.cancel;
      case NotificationType.accountApproved:
        return Symbols.verified;
      case NotificationType.accountRejected:
        return Symbols.gpp_bad;
      case NotificationType.other:
        return Symbols.notifications;
    }
  }

  /// Mark read, then open the linked order if this notification points at one.
  Future<void> _onTap(BuildContext context, NotificationService svc,
      AppNotification n) async {
    if (!n.read) svc.markRead(n.id);
    if (!notifOpensOrder(n.type) || n.orderId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final order = await OrderService().fetchById(n.orderId!);
      navigator.push(
          MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)));
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Could not open this order.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final svc = NotificationService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (user != null)
            IconButton(
              tooltip: 'Mark all read',
              icon: const Icon(Symbols.done_all),
              onPressed: () => svc.markAllRead(user.uid),
            ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<List<AppNotification>>(
              stream: svc.streamForUser(user.uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return const Center(child: Text('No notifications.'));
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final n = items[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            n.read ? Colors.grey.shade300 : kOrange,
                        child: Icon(_icon(n.type),
                            color: n.read ? Colors.grey : Colors.white,
                            size: 20),
                      ),
                      title: Text(n.title,
                          style: TextStyle(
                              fontWeight: n.read
                                  ? FontWeight.normal
                                  : FontWeight.bold)),
                      subtitle: Text(n.body),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat.MMMd().add_jm().format(n.createdAt),
                            style: const TextStyle(fontSize: 11),
                          ),
                          if (notifOpensOrder(n.type)) ...[
                            const SizedBox(width: 4),
                            const Icon(Symbols.chevron_right,
                                size: 18, color: Colors.grey),
                          ],
                        ],
                      ),
                      onTap: () => _onTap(context, svc, n),
                    );
                  },
                );
              },
            ),
    );
  }
}
