import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../models/review.dart';
import '../../providers/auth_provider.dart';
import '../../services/review_service.dart';

class LeaveReviewScreen extends StatefulWidget {
  final AppOrder order;
  const LeaveReviewScreen({super.key, required this.order});

  @override
  State<LeaveReviewScreen> createState() => _LeaveReviewScreenState();
}

class _LeaveReviewScreenState extends State<LeaveReviewScreen> {
  int _rating = 5;
  final _comment = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    setState(() => _busy = true);
    try {
      final svc = ReviewService();
      if (await svc.orderAlreadyReviewed(widget.order.id)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('You already reviewed this order.')));
          Navigator.pop(context);
        }
        return;
      }
      await svc.create(Review(
        id: '',
        sellerId: widget.order.sellerId,
        buyerId: user.uid,
        buyerName: user.fullName,
        orderId: widget.order.id,
        rating: _rating,
        comment: _comment.text.trim(),
        createdAt: DateTime.now(),
      ));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Thanks for your review!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Leave a review')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Rate the seller',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final v = i + 1;
                return IconButton(
                  iconSize: 36,
                  icon: Icon(v <= _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber),
                  onPressed: () => setState(() => _rating = v),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _comment,
              maxLines: 4,
              decoration: const InputDecoration(
                  labelText: 'Comment (optional)',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Submit review'),
            ),
          ],
        ),
      ),
    );
  }
}
