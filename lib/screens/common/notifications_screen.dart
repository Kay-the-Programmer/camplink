import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/notification.dart';
import '../../providers/auth_provider.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _icon(NotificationType t) {
    switch (t) {
      case NotificationType.orderPlaced:
        return Icons.shopping_bag;
      case NotificationType.orderConfirmed:
        return Icons.check_circle;
      case NotificationType.orderDelivered:
        return Icons.local_shipping;
      case NotificationType.orderCancelled:
        return Icons.cancel;
      case NotificationType.paymentConfirmed:
        return Icons.payments;
      case NotificationType.message:
        return Icons.chat;
      case NotificationType.other:
        return Icons.notifications;
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
              icon: const Icon(Icons.done_all),
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
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final n = items[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            n.read ? Colors.grey.shade300 : Colors.deepPurple,
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
                      trailing: Text(
                        DateFormat.MMMd().add_jm().format(n.createdAt),
                        style: const TextStyle(fontSize: 11),
                      ),
                      onTap: () {
                        if (!n.read) svc.markRead(n.id);
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
