import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../app_colors.dart';
import '../../models/app_user.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../models/ride_prices.dart';
import '../../models/shopping_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/ride_prices_provider.dart';
import '../../services/admin_service.dart';
import '../../services/api_client.dart';
import '../../services/order_service.dart';
import '../../services/product_service.dart';
import '../../services/shopping_request_service.dart';
import '../../widgets/confirm.dart';
import '../../widgets/notifications_bell.dart';

// ═════════════════════════════════════════════════════════════════════════════
// SUPER ADMIN DASHBOARD
// ═════════════════════════════════════════════════════════════════════════════

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _tab = 0;

  static const _tabs = [
    (icon: Symbols.dashboard,       label: 'Overview'),
    (icon: Symbols.people,          label: 'Users'),
    (icon: Symbols.inventory_2,     label: 'Products'),
    (icon: Symbols.receipt_long,    label: 'Orders'),
    (icon: Symbols.delivery_dining, label: 'Delivery'),
    (icon: Symbols.directions_car,  label: 'Rides'),
  ];

  static const _titles = [
    'Platform Overview',
    'User Management',
    'Product Moderation',
    'All Orders',
    'Delivery Requests',
    'Ride Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_tab]),
        actions: [
          const NotificationsBell(),
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Symbols.logout),
              tooltip: 'Logout',
              onPressed: () async {
                final ok = await confirmAction(
                  ctx,
                  title: 'Log out?',
                  message: 'You will need to sign in again to continue.',
                  confirmLabel: 'Log out',
                  icon: Symbols.logout,
                  destructive: true,
                );
                if (ok && ctx.mounted) ctx.read<AuthProvider>().logout();
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.icon, fill: 1),
                  label: t.label,
                ))
            .toList(),
      ),
      body: IndexedStack(
        index: _tab,
        children: const [
          _OverviewTab(),
          _UsersTab(),
          _ProductsTab(),
          _OrdersTab(),
          _DeliveryTab(),
          _RidesTab(),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 0 — OVERVIEW
// ═════════════════════════════════════════════════════════════════════════════

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context) {
    final adminSvc  = AdminService();
    final orderSvc  = OrderService();
    final prodSvc   = ProductService();

    return StreamBuilder<List<AppUser>>(
      stream: adminSvc.streamUsers(),
      builder: (context, userSnap) {
        return StreamBuilder<List<AppOrder>>(
          stream: orderSvc.streamAll(),
          builder: (context, orderSnap) {
            return StreamBuilder<List<Product>>(
              stream: prodSvc.streamAll(),
              builder: (context, prodSnap) {
                final users    = userSnap.data  ?? [];
                final orders   = orderSnap.data ?? [];
                final products = prodSnap.data  ?? [];
                final totalProducts = products.length;

                // ── Computed metrics ──────────────────────────────────────
                final totalUsers     = users.length;
                final totalProviders = users
                    .where((u) => isProvider(u.role))
                    .length;
                final totalBuyers = users
                    .where((u) => u.role == UserRole.buyer)
                    .length;
                final suspended = users.where((u) => u.suspended).length;
                final pendingVerify  = users
                    .where((u) =>
                        isProvider(u.role) &&
                        u.verificationStatus == VerificationStatus.pending)
                    .length;

                final totalOrders    = orders.length;
                final pendingOrders  = orders
                    .where((o) => o.status == OrderStatus.pending)
                    .length;
                final totalRevenue   = orders
                    .where((o) => o.status == OrderStatus.delivered)
                    .fold<double>(0, (s, o) => s + o.total);

                final recentOrders = orders
                    .toList()
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // ── Pending-verification alert banner ────────────────
                    if (pendingVerify > 0)
                      _VerifyBanner(count: pendingVerify),

                    const SizedBox(height: 4),

                    // ── Section: Platform Stats ──────────────────────────
                    _SectionHeader(
                        icon: Symbols.bar_chart, title: 'Platform Stats'),
                    const SizedBox(height: 10),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.0,
                      children: [
                        _StatCard(
                          label: 'Total Users',
                          value: '$totalUsers',
                          icon: Symbols.people,
                          color: Colors.blue,
                        ),
                        _StatCard(
                          label: 'Pending Verify',
                          value: '$pendingVerify',
                          icon: Symbols.pending_actions,
                          color: Colors.amber.shade700,
                        ),
                        _StatCard(
                          label: 'Service Providers',
                          value: '$totalProviders',
                          icon: Symbols.storefront,
                          color: kOrange,
                        ),
                        _StatCard(
                          label: 'Buyers',
                          value: '$totalBuyers',
                          icon: Symbols.shopping_cart,
                          color: Colors.purple,
                        ),
                        _StatCard(
                          label: 'Suspended',
                          value: '$suspended',
                          icon: Symbols.block,
                          color: Colors.red,
                        ),
                        _StatCard(
                          label: 'Total Products',
                          value: '$totalProducts',
                          icon: Symbols.inventory_2,
                          color: Colors.indigo,
                        ),
                        _StatCard(
                          label: 'Total Orders',
                          value: '$totalOrders',
                          icon: Symbols.receipt_long,
                          color: Colors.teal,
                        ),
                        _StatCard(
                          label: 'Pending Orders',
                          value: '$pendingOrders',
                          icon: Symbols.hourglass_empty,
                          color: Colors.orange,
                        ),
                        _StatCard(
                          label: 'Total Revenue',
                          value: kwacha.format(totalRevenue),
                          icon: Symbols.payments,
                          color: Colors.green.shade700,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── Section: Recent Orders ───────────────────────────
                    _SectionHeader(
                        icon: Symbols.history, title: 'Recent Orders'),
                    const SizedBox(height: 10),

                    if (recentOrders.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                            child: Text('No orders yet.',
                                style: TextStyle(color: Colors.grey))),
                      )
                    else
                      ...recentOrders.take(8).map(
                            (o) => _AdminOrderTile(order: o, compact: true),
                          ),

                    const SizedBox(height: 24),

                    // ── Section: User Role Breakdown ─────────────────────
                    _SectionHeader(
                        icon: Symbols.pie_chart, title: 'Users by Role'),
                    const SizedBox(height: 10),
                    _RoleBreakdown(users: users),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 18, color: kOrange),
      const SizedBox(width: 8),
      Text(title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold)),
    ]);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: color)),
                Text(label,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 11),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

class _RoleBreakdown extends StatelessWidget {
  final List<AppUser> users;
  const _RoleBreakdown({required this.users});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return const SizedBox.shrink();

    final counts = <UserRole, int>{};
    for (final u in users) {
      counts[u.role] = (counts[u.role] ?? 0) + 1;
    }

    final roleColors = {
      UserRole.buyer:  Colors.purple,
      UserRole.seller: kOrange,
      UserRole.rider:  Colors.blue,
      UserRole.driver: Colors.teal,
      UserRole.admin:  Colors.red,
    };

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: UserRole.values.map((r) {
            final count = counts[r] ?? 0;
            final pct   = users.isEmpty ? 0.0 : count / users.length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(children: [
                SizedBox(
                  width: 80,
                  child: Text(roleLabel(r),
                      style: const TextStyle(fontSize: 12)),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      color: roleColors[r] ?? Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('$count',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: roleColors[r] ?? Colors.grey,
                        fontSize: 12)),
              ]),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Pending-verification alert banner ────────────────────────────────────────

class _VerifyBanner extends StatelessWidget {
  final int count;
  const _VerifyBanner({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(children: [
        Icon(Symbols.pending_actions,
            color: Colors.amber.shade800, size: 22),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            '$count provider application${count == 1 ? '' : 's'} awaiting '
            'your review.',
            style: TextStyle(
                color: Colors.amber.shade900,
                fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8),
        Text('→ Users tab',
            style: TextStyle(
                color: Colors.amber.shade800,
                fontSize: 12,
                fontStyle: FontStyle.italic)),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 1 — USERS
// ═════════════════════════════════════════════════════════════════════════════

class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  UserRole? _filter;       // null = all roles
  bool      _pendingOnly = false;
  String    _search = '';

  @override
  Widget build(BuildContext context) {
    final svc = AdminService();
    final me  = context.read<AuthProvider>().user;

    return Column(
      children: [
        // ── Search bar ─────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search by name or email…',
              prefixIcon: Icon(Symbols.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
          ),
        ),

        // ── Filter chips ───────────────────────────────────────────────
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: const Text('All'),
                  selected: _filter == null && !_pendingOnly,
                  onSelected: (_) => setState(
                      () { _filter = null; _pendingOnly = false; }),
                ),
              ),
              // Pending-review shortcut chip
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  avatar: const Icon(Symbols.pending_actions, size: 14),
                  label: const Text('Pending Review'),
                  selected: _pendingOnly,
                  selectedColor: Colors.amber.shade100,
                  checkmarkColor: Colors.amber.shade800,
                  onSelected: (_) => setState(
                      () { _pendingOnly = !_pendingOnly; _filter = null; }),
                ),
              ),
              ...UserRole.values.map((r) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(roleLabel(r)),
                      selected: _filter == r,
                      onSelected: (_) => setState(() {
                        _filter = _filter == r ? null : r;
                        _pendingOnly = false;
                      }),
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // ── User list ──────────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<List<AppUser>>(
            stream: svc.streamUsers(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting &&
                  snap.data == null) {
                return const Center(child: CircularProgressIndicator());
              }
              final all = snap.data ?? [];
              final filtered = all.where((u) {
                if (_pendingOnly) {
                  return isProvider(u.role) &&
                      u.verificationStatus == VerificationStatus.pending;
                }
                if (_filter != null && u.role != _filter) return false;
                if (_search.isNotEmpty) {
                  return u.fullName.toLowerCase().contains(_search) ||
                      u.email.toLowerCase().contains(_search);
                }
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    _pendingOnly
                        ? 'No pending applications.'
                        : 'No users found.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                );
              }

              return ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, indent: 72),
                itemBuilder: (_, i) {
                  final u = filtered[i];
                  final isMe = u.uid == me?.uid;
                  return _UserTile(
                    user: u,
                    isMe: isMe,
                    onAction: (action) async {
                      if (action == 'suspend') {
                        await svc.setSuspended(u.uid, !u.suspended);
                      } else if (action.startsWith('role:')) {
                        await svc.setRole(u.uid,
                            roleFromString(action.substring(5)));
                      }
                    },
                    onVerify: (approved, reason) async {
                      await svc.verifyProvider(u.uid,
                          approved: approved, reason: reason);
                    },
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

class _UserTile extends StatelessWidget {
  final AppUser user;
  final bool isMe;
  final Future<void> Function(String action) onAction;
  final Future<void> Function(bool approved, String? reason)? onVerify;

  const _UserTile({
    required this.user,
    required this.isMe,
    required this.onAction,
    this.onVerify,
  });

  Color get _roleColor {
    switch (user.role) {
      case UserRole.admin:  return Colors.red;
      case UserRole.seller: return kOrange;
      case UserRole.rider:  return Colors.blue;
      case UserRole.driver: return Colors.teal;
      default:              return Colors.purple;
    }
  }

  // Returns (label, background, text) for the verification badge, or null.
  (String, Color, Color)? get _verifyBadge {
    if (!isProvider(user.role)) return null;
    switch (user.verificationStatus) {
      case VerificationStatus.pending:
        return ('PENDING REVIEW', Colors.amber.shade100, Colors.amber.shade900);
      case VerificationStatus.approved:
        return ('VERIFIED', Colors.green.shade100, Colors.green.shade800);
      case VerificationStatus.rejected:
        return ('REJECTED', Colors.red.shade50, Colors.red.shade700);
      case null:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = _verifyBadge;
    final isPendingProvider = isProvider(user.role) &&
        user.verificationStatus == VerificationStatus.pending;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundImage: user.photoUrl != null
            ? NetworkImage(ApiClient.fileUrl(user.photoUrl))
            : null,
        backgroundColor:
            user.suspended ? Colors.red.shade100 : _roleColor.withValues(alpha: 0.15),
        child: user.photoUrl == null
            ? Icon(
                user.suspended ? Symbols.block : Symbols.person,
                color: user.suspended ? Colors.red : _roleColor,
                size: 20,
              )
            : null,
      ),
      title: Row(children: [
        Expanded(
          child: Text(
            user.fullName.isEmpty ? user.email : user.fullName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        if (isMe)
          const Text('You', style: TextStyle(color: Colors.grey, fontSize: 11)),
      ]),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user.email,
              style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 3),
          Wrap(
            spacing: 5,
            runSpacing: 3,
            children: [
              // Role pill
              _Pill(
                label: roleLabel(user.role),
                bg: _roleColor.withValues(alpha: 0.1),
                fg: _roleColor,
              ),
              // Suspended pill
              if (user.suspended)
                const _Pill(
                  label: 'SUSPENDED',
                  bg: Color(0xFFFFEBEE),
                  fg: Colors.red,
                ),
              // Verification status pill
              if (badge != null)
                _Pill(label: badge.$1, bg: badge.$2, fg: badge.$3),
            ],
          ),
        ],
      ),
      trailing: isMe
          ? null
          : PopupMenuButton<String>(
              onSelected: (action) async {
                if (action == 'approve') {
                  await onVerify?.call(true, null);
                } else if (action == 'reject') {
                  final reason = await showDialog<String>(
                    context: context,
                    builder: (_) => const _RejectReasonDialog(),
                  );
                  if (reason != null && reason.isNotEmpty) {
                    await onVerify?.call(false, reason);
                  }
                } else {
                  await onAction(action);
                }
              },
              itemBuilder: (_) => [
                // ── Approve / Reject (pending providers only) ─────────
                if (isPendingProvider) ...[
                  PopupMenuItem(
                    value: 'approve',
                    child: Row(children: [
                      Icon(Symbols.check_circle,
                          size: 18, color: Colors.green.shade700),
                      const SizedBox(width: 8),
                      const Text('Approve application'),
                    ]),
                  ),
                  PopupMenuItem(
                    value: 'reject',
                    child: Row(children: [
                      Icon(Symbols.cancel,
                          size: 18, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      const Text('Reject application'),
                    ]),
                  ),
                  const PopupMenuDivider(),
                ],
                // ── Suspend / Unsuspend ───────────────────────────────
                PopupMenuItem(
                  value: 'suspend',
                  child: Row(children: [
                    Icon(
                        user.suspended
                            ? Symbols.lock_open
                            : Symbols.block,
                        size: 18,
                        color: user.suspended ? Colors.green : Colors.red),
                    const SizedBox(width: 8),
                    Text(user.suspended ? 'Unsuspend' : 'Suspend'),
                  ]),
                ),
                const PopupMenuDivider(),
                // ── Role change ───────────────────────────────────────
                const PopupMenuItem(
                    value: 'role:buyer',
                    child: Text('Set role → Buyer')),
                const PopupMenuItem(
                    value: 'role:seller',
                    child: Text('Set role → Seller')),
                const PopupMenuItem(
                    value: 'role:rider',
                    child: Text('Set role → Rider')),
                const PopupMenuItem(
                    value: 'role:driver',
                    child: Text('Set role → Delivery Driver')),
                const PopupMenuItem(
                    value: 'role:admin',
                    child: Text('Set role → Admin')),
              ],
            ),
    );
  }
}

// ── Small reusable pill badge ─────────────────────────────────────────────────

class _Pill extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  const _Pill({required this.label, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(label,
          style: TextStyle(
              color: fg, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Rejection-reason dialog ───────────────────────────────────────────────────

class _RejectReasonDialog extends StatefulWidget {
  const _RejectReasonDialog();

  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  final _ctrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(children: [
        Icon(Symbols.cancel, color: Colors.red, size: 22),
        SizedBox(width: 8),
        Text('Reject application'),
      ]),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _ctrl,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Reason for rejection',
            hintText:
                'Explain why the application is being rejected…',
            border: OutlineInputBorder(),
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Please enter a reason.' : null,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style:
              FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _ctrl.text.trim());
            }
          },
          child: const Text('Reject'),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 2 — PRODUCTS
// ═════════════════════════════════════════════════════════════════════════════

class _ProductsTab extends StatefulWidget {
  const _ProductsTab();

  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final svc = ProductService();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search products or seller…',
              prefixIcon: Icon(Symbols.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Product>>(
            stream: svc.streamAll(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting &&
                  snap.data == null) {
                return const Center(child: CircularProgressIndicator());
              }
              final all = snap.data ?? [];
              final filtered = _search.isEmpty
                  ? all
                  : all
                      .where((p) =>
                          p.name.toLowerCase().contains(_search) ||
                          p.sellerName.toLowerCase().contains(_search) ||
                          p.category.toLowerCase().contains(_search))
                      .toList();

              if (filtered.isEmpty) {
                return const Center(child: Text('No products.'));
              }

              return ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, indent: 72),
                itemBuilder: (_, i) {
                  final p = filtered[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: p.imageUrl != null
                          ? Image.network(ApiClient.fileUrl(p.imageUrl),
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Symbols.broken_image),
                                  ))
                          : Container(
                              width: 50,
                              height: 50,
                              color: Colors.grey.shade200,
                              child: const Icon(Symbols.shopping_bag)),
                    ),
                    title: Text(p.name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${kwacha.format(p.price)}  ·  ${p.category}'),
                        Text('by ${p.sellerName}',
                            style: const TextStyle(fontSize: 11,
                                color: Colors.grey)),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!p.available)
                          const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: Chip(
                              label: Text('Unavailable',
                                  style: TextStyle(fontSize: 10)),
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        IconButton(
                          icon: const Icon(Symbols.delete,
                              color: Colors.red),
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Remove product?'),
                                content: Text(
                                    '${p.name} by ${p.sellerName}'),
                                actions: [
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel')),
                                  TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Remove',
                                          style: TextStyle(
                                              color: Colors.red))),
                                ],
                              ),
                            );
                            if (ok == true) await svc.delete(p.id);
                          },
                        ),
                      ],
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

// ═════════════════════════════════════════════════════════════════════════════
// TAB 3 — ORDERS
// ═════════════════════════════════════════════════════════════════════════════

class _OrdersTab extends StatefulWidget {
  const _OrdersTab();

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  OrderStatus? _statusFilter;
  String _search = '';

  static const _statusColors = {
    OrderStatus.pending:   Colors.orange,
    OrderStatus.confirmed: Colors.blue,
    OrderStatus.delivered: Colors.green,
    OrderStatus.cancelled: Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search buyer or seller…',
              prefixIcon: Icon(Symbols.search),
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
          ),
        ),
        // Status filter chips
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: const Text('All'),
                  selected: _statusFilter == null,
                  onSelected: (_) => setState(() => _statusFilter = null),
                ),
              ),
              ...OrderStatus.values.map((s) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(s.name),
                      selected: _statusFilter == s,
                      selectedColor:
                          (_statusColors[s] ?? Colors.grey).withValues(alpha: 0.2),
                      onSelected: (_) => setState(
                          () => _statusFilter =
                              _statusFilter == s ? null : s),
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // List
        Expanded(
          child: StreamBuilder<List<AppOrder>>(
            stream: OrderService().streamAll(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting &&
                  snap.data == null) {
                return const Center(child: CircularProgressIndicator());
              }
              final all = snap.data ?? [];
              final filtered = all.where((o) {
                if (_statusFilter != null && o.status != _statusFilter) {
                  return false;
                }
                if (_search.isNotEmpty) {
                  return o.buyerName.toLowerCase().contains(_search) ||
                      o.sellerName.toLowerCase().contains(_search);
                }
                return true;
              }).toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

              if (filtered.isEmpty) {
                return const Center(child: Text('No orders found.'));
              }

              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (_, i) =>
                    _AdminOrderTile(order: filtered[i], compact: false),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AdminOrderTile extends StatelessWidget {
  final AppOrder order;
  final bool compact;
  const _AdminOrderTile({required this.order, required this.compact});

  static const _statusColors = {
    OrderStatus.pending:   Colors.orange,
    OrderStatus.confirmed: Colors.blue,
    OrderStatus.delivered: Colors.green,
    OrderStatus.cancelled: Colors.red,
  };

  Color get _color =>
      _statusColors[order.status] ?? Colors.grey;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Symbols.receipt_long, color: _color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${order.buyerName}  →  ${order.sellerName}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${kwacha.format(order.total)}  ·  '
                  '${order.items.length} item(s)  ·  '
                  '${DateFormat.MMMd().format(order.createdAt)}',
                  style:
                      const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                if (!compact)
                  Text(
                    '${paymentMethodLabel(order.paymentMethod)}  ·  '
                    '${order.paymentStatus.name}',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 11),
                  ),
              ],
            ),
          ),
          Chip(
            label: Text(order.status.name,
                style:
                    const TextStyle(color: Colors.white, fontSize: 11)),
            backgroundColor: _color,
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ]),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 4 — DELIVERY REQUESTS
// ═════════════════════════════════════════════════════════════════════════════

class _DeliveryTab extends StatefulWidget {
  const _DeliveryTab();

  @override
  State<_DeliveryTab> createState() => _DeliveryTabState();
}

class _DeliveryTabState extends State<_DeliveryTab> {
  RequestStatus? _filter;

  static const _statusColors = {
    RequestStatus.open:      Colors.green,
    RequestStatus.accepted:  Colors.blue,
    RequestStatus.fulfilled: Colors.grey,
    RequestStatus.cancelled: Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: const Text('All'),
                  selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null),
                ),
              ),
              ...RequestStatus.values.map((s) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(s.name),
                      selected: _filter == s,
                      selectedColor:
                          (_statusColors[s] ?? Colors.grey).withValues(alpha: 0.2),
                      onSelected: (_) => setState(
                          () => _filter = _filter == s ? null : s),
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // List — admin sees open requests (same public stream for now)
        Expanded(
          child: StreamBuilder<List<ShoppingRequest>>(
            stream: ShoppingRequestService().streamOpen(),
            builder: (context, snapOpen) {
              return StreamBuilder<List<ShoppingRequest>>(
                stream: ShoppingRequestService().streamRunning(),
                builder: (context, snapRun) {
                  final open    = snapOpen.data ?? [];
                  final running = snapRun.data  ?? [];
                  var all = {...open, ...running}.toList()
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  if (_filter != null) {
                    all = all.where((r) => r.status == _filter).toList();
                  }

                  if (snapOpen.connectionState == ConnectionState.waiting &&
                      all.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (all.isEmpty) {
                    return const Center(
                        child: Text('No delivery requests.',
                            style: TextStyle(color: Colors.grey)));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: all.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, i) =>
                        _AdminDeliveryTile(request: all[i]),
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

class _AdminDeliveryTile extends StatelessWidget {
  final ShoppingRequest request;
  const _AdminDeliveryTile({required this.request});

  static const _statusColors = {
    RequestStatus.open:      Colors.green,
    RequestStatus.accepted:  Colors.blue,
    RequestStatus.fulfilled: Colors.grey,
    RequestStatus.cancelled: Colors.red,
  };

  @override
  Widget build(BuildContext context) {
    final r = request;
    final color = _statusColors[r.status] ?? Colors.grey;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.grey.shade200)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Symbols.delivery_dining, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  Text(
                    'by ${r.requesterName}  ·  ${r.items.length} item(s)',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12),
                  ),
                  if (r.runnerName != null)
                    Text(
                      'Runner: ${r.runnerName}',
                      style: const TextStyle(
                          color: Colors.blue, fontSize: 11),
                    ),
                  Text(
                    '→ ${r.deliveryHostel}'
                    '${r.deliveryRoom != null ? ', ${r.deliveryRoom}' : ''}',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ),
            Chip(
              label: Text(r.status.name,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 10)),
              backgroundColor: color,
              padding: EdgeInsets.zero,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TAB 5 — RIDE SETTINGS
// ═════════════════════════════════════════════════════════════════════════════

class _RidesTab extends StatefulWidget {
  const _RidesTab();

  @override
  State<_RidesTab> createState() => _RidesTabState();
}

class _RidesTabState extends State<_RidesTab> {
  final _form = GlobalKey<FormState>();

  // Controllers initialised from the current provider values.
  late final TextEditingController _campusToTownCtrl;
  late final TextEditingController _townToAcrossCtrl;
  late final TextEditingController _townToInsideCtrl;

  bool _saving  = false;
  bool _success = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = context.read<RidePricesProvider>().prices;
    _campusToTownCtrl = TextEditingController(
        text: p.campusToTown.toStringAsFixed(2));
    _townToAcrossCtrl = TextEditingController(
        text: p.townToAcross.toStringAsFixed(2));
    _townToInsideCtrl = TextEditingController(
        text: p.townToInsideCampus.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _campusToTownCtrl.dispose();
    _townToAcrossCtrl.dispose();
    _townToInsideCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; _success = false; });
    try {
      final updated = RidePrices(
        campusToTown:       double.parse(_campusToTownCtrl.text.trim()),
        townToAcross:       double.parse(_townToAcrossCtrl.text.trim()),
        townToInsideCampus: double.parse(_townToInsideCtrl.text.trim()),
      );
      await context.read<RidePricesProvider>().updatePrices(updated);
      if (mounted) setState(() => _success = true);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep field values in sync if another admin updates prices
    // and the provider notifies while this tab is open.
    final prices = context.watch<RidePricesProvider>().prices;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Info banner ───────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: kOrangeLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: kOrange.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            const Icon(Symbols.info, color: kOrange, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'These prices are shown to students before they book a ride. '
                'Changes take effect immediately for all users.',
                style: TextStyle(
                    color: kOrange.withValues(alpha: 0.9), fontSize: 13),
              ),
            ),
          ]),
        ),

        const SizedBox(height: 24),
        _SectionHeader(icon: Symbols.directions_car, title: 'Fare Configuration'),
        const SizedBox(height: 14),

        Form(
          key: _form,
          child: Column(children: [

            // ── Campus → Town ─────────────────────────────────────────────
            _PriceTile(
              fromIcon: Symbols.school,
              toIcon: Symbols.location_city,
              label: 'Campus → Town',
              description: 'Fare per seat from any campus location to town.',
              ctrl: _campusToTownCtrl,
            ),
            const SizedBox(height: 12),

            // ── Town → Across ─────────────────────────────────────────────
            _PriceTile(
              fromIcon: Symbols.location_city,
              toIcon: Symbols.directions_walk,
              label: 'Town → Across (outside gate)',
              description: 'Fare per seat — driver drops passenger at the '
                  'road crossing outside the campus gate.',
              ctrl: _townToAcrossCtrl,
            ),
            const SizedBox(height: 12),

            // ── Town → Inside Campus ──────────────────────────────────────
            _PriceTile(
              fromIcon: Symbols.location_city,
              toIcon: Symbols.school,
              label: 'Town → Inside Campus',
              description: 'Fare per seat — driver enters campus and drops '
                  'passenger at their chosen location.',
              ctrl: _townToInsideCtrl,
            ),
          ]),
        ),

        // ── Current prices summary ────────────────────────────────────────
        const SizedBox(height: 24),
        _SectionHeader(icon: Symbols.receipt, title: 'Active Prices'),
        const SizedBox(height: 10),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Column(children: [
            _ActivePriceRow(
              label: 'Campus → Town',
              amount: prices.campusToTown,
            ),
            const Divider(height: 1),
            _ActivePriceRow(
              label: 'Town → Across',
              amount: prices.townToAcross,
            ),
            const Divider(height: 1),
            _ActivePriceRow(
              label: 'Town → Inside Campus',
              amount: prices.townToInsideCampus,
            ),
          ]),
        ),

        // ── Feedback ──────────────────────────────────────────────────────
        if (_success) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(children: [
              Icon(Symbols.check_circle,
                  size: 18, color: Colors.green.shade700),
              const SizedBox(width: 8),
              Text('Prices updated successfully.',
                  style: TextStyle(color: Colors.green.shade800)),
            ]),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Icon(Symbols.error,
                  size: 18,
                  color: Theme.of(context).colorScheme.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(_error!,
                    style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onErrorContainer)),
              ),
            ]),
          ),
        ],

        const SizedBox(height: 24),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14)),
          child: _saving
              ? const SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Save Prices', style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ── Price input tile ──────────────────────────────────────────────────────────

class _PriceTile extends StatelessWidget {
  final IconData fromIcon;
  final IconData toIcon;
  final String label;
  final String description;
  final TextEditingController ctrl;

  const _PriceTile({
    required this.fromIcon,
    required this.toIcon,
    required this.label,
    required this.description,
    required this.ctrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          // Route icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kOrangeLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(fromIcon, size: 16, color: kOrange),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Symbols.arrow_forward, size: 12, color: kOrange),
              ),
              Icon(toIcon, size: 16, color: kOrange),
            ]),
          ),
          const SizedBox(width: 12),

          // Label + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 2),
                Text(description,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Price input
          SizedBox(
            width: 90,
            child: TextFormField(
              controller: ctrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                prefixText: 'K ',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final n = double.tryParse(v.trim());
                if (n == null || n <= 0) return 'Invalid';
                return null;
              },
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Active price row (read-only) ──────────────────────────────────────────────

class _ActivePriceRow extends StatelessWidget {
  final String label;
  final double amount;
  const _ActivePriceRow({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(fontSize: 13)),
        ),
        Text(
          'K ${amount.toStringAsFixed(2)} / seat',
          style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: kOrange,
              fontSize: 13),
        ),
      ]),
    );
  }
}
