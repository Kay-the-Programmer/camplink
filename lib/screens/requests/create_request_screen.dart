import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../models/shopping_request.dart';
import '../../services/shopping_request_service.dart';
import '../../services/api_client.dart';

class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key});

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _hostel = TextEditingController();
  final _room = TextEditingController();
  final _budget = TextEditingController();
  final _note = TextEditingController();
  final _runnerFee = TextEditingController();
  final _svc = ShoppingRequestService();

  final List<_ItemRow> _items = [_ItemRow()];
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _hostel.dispose();
    _room.dispose();
    _budget.dispose();
    _note.dispose();
    _runnerFee.dispose();
    for (final r in _items) {
      r.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final items = _items.map((r) => ShoppingRequestItem(
            name: r.name.text.trim(),
            quantity: int.tryParse(r.qty.text.trim()) ?? 1,
            estimatedPrice: double.tryParse(r.price.text.trim()),
            notes: r.notes.text.trim().isEmpty ? null : r.notes.text.trim(),
          )).toList();

      await _svc.create(
        title: _title.text.trim(),
        items: items,
        deliveryHostel: _hostel.text.trim(),
        deliveryRoom: _room.text.trim().isEmpty ? null : _room.text.trim(),
        budget: double.tryParse(_budget.text.trim()),
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
        runnerFee: double.tryParse(_runnerFee.text.trim()),
      );

      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Shopping Request')),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Request title',
                hintText: 'e.g. Groceries from Shoprite',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 20),

            // ── Items list ─────────────────────────────────────────────────
            Row(
              children: [
                const Text('Items to buy',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Symbols.add, size: 18),
                  label: const Text('Add item'),
                  onPressed: () => setState(() => _items.add(_ItemRow())),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ..._items.asMap().entries.map((entry) {
              final i = entry.key;
              final row = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text('Item ${i + 1}',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          const Spacer(),
                          if (_items.length > 1)
                            IconButton(
                              icon: const Icon(Symbols.close, size: 18),
                              onPressed: () => setState(() {
                                row.dispose();
                                _items.removeAt(i);
                              }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: row.name,
                        decoration: const InputDecoration(
                          labelText: 'Item name *',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: row.qty,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Qty *',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) {
                                final n = int.tryParse(v ?? '');
                                return n == null || n < 1 ? 'Min 1' : null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: row.price,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Est. price (K)',
                                isDense: true,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: row.notes,
                        decoration: const InputDecoration(
                          labelText: 'Notes (size, colour, brand…)',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),

            // ── Delivery ───────────────────────────────────────────────────
            const Text('Delivery details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _hostel,
              decoration: const InputDecoration(
                labelText: 'Hostel / delivery location *',
                hintText: 'e.g. Sinozulu Hostel',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _room,
              decoration: const InputDecoration(
                labelText: 'Room number (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _budget,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Total budget (K)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _runnerFee,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Runner fee (K)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _note,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Additional notes',
                hintText: 'Any special instructions for the runner…',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Post request'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemRow {
  final name  = TextEditingController();
  final qty   = TextEditingController(text: '1');
  final price = TextEditingController();
  final notes = TextEditingController();

  void dispose() {
    name.dispose();
    qty.dispose();
    price.dispose();
    notes.dispose();
  }
}
