import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../services/product_service.dart';
import '../../services/storage_service.dart';

/// Maximum number of images a single product can carry.
const _kMaxImages = 5;

class AddEditProductScreen extends StatefulWidget {
  final Product? existing;
  const AddEditProductScreen({super.key, this.existing});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

/// One slot in the image strip — either an already-uploaded image (referenced
/// by its host-relative path) or a freshly picked file pending upload.
class _ImageSlot {
  final String? path; // set for already-uploaded images
  final XFile? file; // set for newly picked images
  final Uint8List? bytes; // preview bytes for newly picked images
  const _ImageSlot.existing(this.path)
      : file = null,
        bytes = null;
  const _ImageSlot.picked(this.file, this.bytes) : path = null;

  bool get isNew => file != null;
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _form = GlobalKey<FormState>();
  late TextEditingController _name;
  late TextEditingController _desc;
  late TextEditingController _price;
  late String _category;
  late bool _available;
  final List<_ImageSlot> _images = [];
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
    if (p != null) {
      _images.addAll(p.imageUrls.map((u) => _ImageSlot.existing(u)));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_images.length >= _kMaxImages) return;
    final picker = ImagePicker();
    // Let the user grab several at once, but never exceed the cap.
    final picked = await picker.pickMultiImage(maxWidth: 1024, imageQuality: 80);
    if (picked.isEmpty) return;
    final remaining = _kMaxImages - _images.length;
    for (final x in picked.take(remaining)) {
      final bytes = await x.readAsBytes();
      if (!mounted) return;
      setState(() => _images.add(_ImageSlot.picked(x, bytes)));
    }
    if (picked.length > remaining && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can add up to $_kMaxImages images.')),
      );
    }
  }

  void _removeAt(int i) => setState(() => _images.removeAt(i));

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image.')),
      );
      return;
    }
    final user = context.read<AuthProvider>().user;
    if (user == null) return;
    setState(() => _busy = true);
    try {
      // Upload any new images, then assemble the final ordered list of paths.
      final storage = StorageService();
      final imageUrls = <String>[];
      for (final slot in _images) {
        if (slot.isNew) {
          imageUrls.add(await storage.uploadImage(slot.file!, 'products/${user.uid}'));
        } else {
          imageUrls.add(slot.path!);
        }
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
          imageUrls: imageUrls,
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
          imageUrls: imageUrls,
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
      // Block interaction and show progress while uploading + saving.
      body: Stack(
        children: [
          Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ImageStrip(
                  images: _images,
                  max: _kMaxImages,
                  onAdd: _pickImage,
                  onRemove: _removeAt,
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
                  validator: (v) => (v == null || double.tryParse(v) == null)
                      ? 'Invalid'
                      : null,
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
          if (_busy)
            const _BusyOverlay(message: 'Saving product…'),
        ],
      ),
    );
  }
}

/// Horizontal strip of image thumbnails with an "add" tile at the end.
class _ImageStrip extends StatelessWidget {
  final List<_ImageSlot> images;
  final int max;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  const _ImageStrip({
    required this.images,
    required this.max,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Images (${images.length}/$max)',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
            Text('· first is the cover',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (var i = 0; i < images.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _Thumb(slot: images[i], onRemove: () => onRemove(i)),
                ),
              if (images.length < max)
                GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Symbols.add_a_photo, size: 28),
                        SizedBox(height: 4),
                        Text('Add', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  final _ImageSlot slot;
  final VoidCallback onRemove;
  const _Thumb({required this.slot, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final image = slot.isNew
        ? Image.memory(slot.bytes!, width: 96, height: 96, fit: BoxFit.cover)
        : Image.network(ApiClient.fileUrl(slot.path),
            width: 96,
            height: 96,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                const Icon(Symbols.broken_image, size: 36));
    return Stack(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(8), child: image),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              decoration: const BoxDecoration(
                  color: Colors.black54, shape: BoxShape.circle),
              padding: const EdgeInsets.all(2),
              child: const Icon(Symbols.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}

/// Full-screen translucent overlay shown during a blocking background action.
class _BusyOverlay extends StatelessWidget {
  final String message;
  const _BusyOverlay({required this.message});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.35),
        child: Center(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  const SizedBox(width: 16),
                  Text(message),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
