import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../services/product_service.dart';
import '../../services/storage_service.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? existing;
  const AddEditProductScreen({super.key, this.existing});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _form = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _desc;
  late TextEditingController _price;
  late String _category;
  late bool _available;
  String? _imageUrl;
  XFile? _pickedImage;
  Uint8List? _pickedImageBytes; // needed for web preview
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _name = TextEditingController(text: p?.name ?? '');
    _desc = TextEditingController(text: p?.description ?? '');
    _price = TextEditingController(text: p?.price.toStringAsFixed(2) ?? '');
    _category = p?.category ?? productCategories.first;
    _available = p?.available ?? true;
    _imageUrl = p?.imageUrl;
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
        source: ImageSource.gallery, maxWidth: 1024, imageQuality: 80);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    setState(() {
      _pickedImage = x;
      _pickedImageBytes = bytes;
    });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    setState(() => _busy = true);
    try {
      String? imageUrl = _imageUrl;
      if (_pickedImage != null) {
        imageUrl = await StorageService()
            .uploadImage(_pickedImage!, 'products/${user.uid}');
      }
      final price = double.tryParse(_price.text.trim()) ?? 0;
      final svc = ProductService();
      if (widget.existing == null) {
        await svc.create(Product(
          id: '',
          sellerId: user.uid,
          sellerName: user.fullName,
          name: _name.text.trim(),
          description: _desc.text.trim(),
          category: _category,
          price: price,
          available: _available,
          imageUrl: imageUrl,
          createdAt: DateTime.now(),
        ));
      } else {
        await svc.update(Product(
          id: widget.existing!.id,
          sellerId: widget.existing!.sellerId,
          sellerName: widget.existing!.sellerName,
          name: _name.text.trim(),
          description: _desc.text.trim(),
          category: _category,
          price: price,
          available: _available,
          imageUrl: imageUrl,
          createdAt: widget.existing!.createdAt,
        ));
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Add Product' : 'Edit Product'),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _pickedImageBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(_pickedImageBytes!,
                            fit: BoxFit.cover),
                      )
                    : (_imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child:
                                Image.network(_imageUrl!, fit: BoxFit.cover),
                          )
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Symbols.add_a_photo, size: 36),
                                SizedBox(height: 4),
                                Text('Tap to add image'),
                              ],
                            ),
                          )),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                  labelText: 'Name', border: OutlineInputBorder()),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              decoration: const InputDecoration(
                  labelText: 'Price (K)', border: OutlineInputBorder()),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) =>
                  (v == null || double.tryParse(v) == null) ? 'Invalid' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(
                  labelText: 'Category', border: OutlineInputBorder()),
              items: productCategories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _desc,
              decoration: const InputDecoration(
                  labelText: 'Description', border: OutlineInputBorder()),
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _available,
              onChanged: (v) => setState(() => _available = v),
              title: const Text('Available'),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
