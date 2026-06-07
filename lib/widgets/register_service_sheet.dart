import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../models/service_listing.dart';
import '../services/api_client.dart';
import '../services/service_listing_service.dart';

/// Bottom sheet for creating a service listing. Shared by the buyer Services
/// tab and the seller dashboard's Listings tab.
class RegisterServiceSheet extends StatefulWidget {
  final VoidCallback? onCreated;
  const RegisterServiceSheet({super.key, this.onCreated});

  @override
  State<RegisterServiceSheet> createState() => _RegisterServiceSheetState();
}

class _RegisterServiceSheetState extends State<RegisterServiceSheet> {
  final _formKey = GlobalKey<FormState>();
  final _svc = ServiceListingService();

  final _titleCtrl     = TextEditingController();
  final _descCtrl      = TextEditingController();
  final _priceCtrl     = TextEditingController();
  final _priceNoteCtrl = TextEditingController();

  ServiceCategory _category = ServiceCategory.other;
  bool _busy = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _priceNoteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await _svc.create(
        title:       _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category:    _category,
        price: _priceCtrl.text.trim().isNotEmpty
            ? double.tryParse(_priceCtrl.text.trim())
            : null,
        priceNote: _priceNoteCtrl.text.trim().isNotEmpty
            ? _priceNoteCtrl.text.trim()
            : null,
      );
      if (mounted) {
        Navigator.pop(context);
        widget.onCreated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service listed successfully!')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          shrinkWrap: true,
          children: [
            Row(children: [
              const Expanded(
                child: Text('Register a Service',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              IconButton(
                icon: const Icon(Symbols.close),
                onPressed: () => Navigator.pop(context),
              ),
            ]),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Service title *',
                hintText: 'e.g. Maths Tutoring, Braiding, Laundry',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'What do you offer? Who can you help?',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ServiceCategory>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: ServiceCategory.values
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(serviceCategoryLabel(c)),
                      ))
                  .toList(),
              onChanged: (c) => setState(() => _category = c!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Price (K) — leave blank if negotiable',
                border: OutlineInputBorder(),
                prefixText: 'K ',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                if (double.tryParse(v.trim()) == null) {
                  return 'Enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceNoteCtrl,
              decoration: const InputDecoration(
                labelText: 'Price note (optional)',
                hintText: 'e.g. per hour, per kg, negotiable',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              icon: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Symbols.check),
              label: const Text('List my service'),
              onPressed: _busy ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
