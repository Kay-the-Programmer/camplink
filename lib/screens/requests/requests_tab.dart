import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../app_colors.dart';
import '../../models/product.dart';
import '../../models/shopping_request.dart';
import '../../providers/auth_provider.dart';
import '../../services/shopping_request_service.dart';
import '../../services/api_client.dart';
import 'create_request_screen.dart';

class RequestsTab extends StatelessWidget {
  const RequestsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Requests Board'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Open Requests'),
            Tab(text: 'Mine'),
          ]),
        ),
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Symbols.add_task),
          label: const Text('Post request'),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
          ),
        ),
        body: const TabBarView(children: [
          _OpenBoard(),
          _MyRequests(),
        ]),
      ),
    );
  }
}

// ── Open requests board ──────────────────────────────────────────────────────

class _OpenBoard extends StatelessWidget {
  const _OpenBoard();

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().user;
    final svc = ShoppingRequestService();
    return StreamBuilder<List<ShoppingRequest>>(
      stream: svc.streamOpen(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snap.data ?? [];
        // Filter out own requests from the board
        final open = all.where((r) => r.requesterId != me?.uid).toList();
        if (open.isEmpty) {
          return const Center(
            child: Text('No open requests right now.\nBe the first to post one!',
                textAlign: TextAlign.center),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: open.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _RequestCard(request: open[i], isRunner: true),
        );
      },
    );
  }
}

// ── My requests + running ────────────────────────────────────────────────────

class _MyRequests extends StatelessWidget {
  const _MyRequests();

  @override
  Widget build(BuildContext context) {
    final svc = ShoppingRequestService();
    return StreamBuilder<List<ShoppingRequest>>(
      stream: svc.streamMine(),
      builder: (context, snapMine) {
        return StreamBuilder<List<ShoppingRequest>>(
          stream: svc.streamRunning(),
          builder: (context, snapRunning) {
            final mine    = snapMine.data ?? [];
            final running = snapRunning.data ?? [];
            final all = [...mine, ...running]
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            if (all.isEmpty) {
              return const Center(
                child: Text('No activity yet.\nPost a request or accept one from the board.',
                    textAlign: TextAlign.center),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: all.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final r = all[i];
                final isRunning = running.any((x) => x.id == r.id);
                return _RequestCard(request: r, isRunner: isRunning);
              },
            );
          },
        );
      },
    );
  }
}

// ── Request card ─────────────────────────────────────────────────────────────

class _RequestCard extends StatelessWidget {
  final ShoppingRequest request;
  final bool isRunner; // true = show Accept/Fulfill, false = show Cancel

  const _RequestCard({required this.request, required this.isRunner});

  Color _statusColor() {
    switch (request.status) {
      case RequestStatus.open:      return Colors.green;
      case RequestStatus.accepted:  return Colors.blue;
      case RequestStatus.fulfilled: return Colors.grey;
      case RequestStatus.cancelled: return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().user;
    final svc = ShoppingRequestService();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Expanded(
                  child: Text(request.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
                Chip(
                  label: Text(request.status.name,
                      style: const TextStyle(color: Colors.white, fontSize: 11)),
                  backgroundColor: _statusColor(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            Text('by ${request.requesterName}',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 10),

            // Items
            ...request.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      const Icon(Symbols.circle, size: 6, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(
                              '${item.name}  ×${item.quantity}'
                              '${item.estimatedPrice != null ? '  — ${kwacha.format(item.estimatedPrice!)} each' : ''}')),
                      if (item.notes != null)
                        Text('(${item.notes})',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                )),

            const SizedBox(height: 10),
            // Delivery + fee chips
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _chip(Symbols.home, request.deliveryHostel +
                    (request.deliveryRoom != null ? ', ${request.deliveryRoom}' : '')),
                if (request.budget != null)
                  _chip(Symbols.account_balance_wallet,
                      'Budget: ${kwacha.format(request.budget!)}'),
                if (request.runnerFee != null)
                  _chip(Symbols.delivery_dining,
                      'Fee: ${kwacha.format(request.runnerFee!)}', kOrange),
              ],
            ),

            if (request.note != null) ...[
              const SizedBox(height: 8),
              Text(request.note!,
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],

            // Runner info (if accepted)
            if (request.status == RequestStatus.accepted &&
                request.runnerName != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Symbols.directions_run, size: 16, color: kOrange),
                  const SizedBox(width: 4),
                  Text('Runner: ${request.runnerName}',
                      style: const TextStyle(color: kOrange, fontSize: 13)),
                ],
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Action buttons
            _ActionRow(request: request, isRunner: isRunner, svc: svc, me: me?.uid),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, [Color? color]) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: (color ?? Colors.grey).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: (color ?? Colors.grey).withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color ?? Colors.grey),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(fontSize: 12, color: color ?? Colors.grey)),
          ],
        ),
      );
}

class _ActionRow extends StatefulWidget {
  final ShoppingRequest request;
  final bool isRunner;
  final ShoppingRequestService svc;
  final String? me;

  const _ActionRow(
      {required this.request,
      required this.isRunner,
      required this.svc,
      required this.me});

  @override
  State<_ActionRow> createState() => _ActionRowState();
}

class _ActionRowState extends State<_ActionRow> {
  bool _loading = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    if (_loading) return const Center(child: CircularProgressIndicator());

    // Runner view: accept open / fulfill accepted
    if (widget.isRunner) {
      if (r.status == RequestStatus.open) {
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Symbols.directions_run),
            label: const Text('Accept & Run this'),
            onPressed: () => _run(() => widget.svc.accept(r.id)),
          ),
        );
      }
      if (r.status == RequestStatus.accepted &&
          r.runnerId == widget.me) {
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Symbols.check_circle),
            label: const Text('Mark as delivered'),
            onPressed: () => _run(() => widget.svc.fulfill(r.id)),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    // Requester view: cancel own open request
    if (r.requesterId == widget.me &&
        (r.status == RequestStatus.open ||
            r.status == RequestStatus.accepted)) {
      return OutlinedButton.icon(
        icon: const Icon(Symbols.cancel, color: Colors.red),
        label: const Text('Cancel request',
            style: TextStyle(color: Colors.red)),
        onPressed: () => _run(() => widget.svc.cancel(r.id)),
      );
    }
    return const SizedBox.shrink();
  }
}
