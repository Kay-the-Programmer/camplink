import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../app_colors.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../services/storage_service.dart';

/// Shared profile view + editor used by both the buyer shell and the seller
/// dashboard. Shows the avatar, identity, and editable contact fields. Pass an
/// [extra] widget to inject role-specific content (e.g. the provider status
/// card) and set [showLogout] to include a logout button at the bottom.
class ProfileEditor extends StatefulWidget {
  final Widget? extra;
  final bool showLogout;
  const ProfileEditor({super.key, this.extra, this.showLogout = false});

  @override
  State<ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<ProfileEditor> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _hostel;
  late final TextEditingController _location;
  XFile? _pickedPhoto;
  Uint8List? _pickedBytes;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().user;
    _name     = TextEditingController(text: u?.fullName ?? '');
    _phone    = TextEditingController(text: u?.phone ?? '');
    _hostel   = TextEditingController(text: u?.hostel ?? '');
    _location = TextEditingController(text: u?.location ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _hostel.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final x = await ImagePicker()
        .pickImage(source: ImageSource.gallery, maxWidth: 600, imageQuality: 80);
    if (x == null) return;
    setState(() {
      _pickedPhoto = x;
      _pickedBytes = null;
    });
    final bytes = await x.readAsBytes();
    if (mounted) setState(() => _pickedBytes = bytes);
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;
    setState(() => _busy = true);
    try {
      String? photoUrl = user.photoUrl;
      if (_pickedPhoto != null) {
        photoUrl = await StorageService()
            .uploadImage(_pickedPhoto!, 'avatars/${user.uid}');
      }
      await auth.updateProfile(user.copyWith(
        fullName: _name.text.trim(),
        phone:    _phone.text.trim(),
        hostel:   _hostel.text.trim(),
        location: _location.text.trim(),
        photoUrl: photoUrl,
      ));
      if (mounted) {
        setState(() {
          _pickedPhoto = null;
          _pickedBytes = null;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profile updated')));
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

  void _logout() {
    // ProviderShell is pushed over the root shell; pop back first so we don't
    // strand this route over the guest screen after sign-out.
    Navigator.of(context).popUntil((r) => r.isFirst);
    context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null) return const Center(child: Text('Not logged in'));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Avatar
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundImage: _pickedBytes != null
                    ? MemoryImage(_pickedBytes!) as ImageProvider
                    : (user.photoUrl != null
                        ? NetworkImage(user.photoUrl!)
                        : null),
                child: (_pickedBytes == null && user.photoUrl == null)
                    ? const Icon(Symbols.person, size: 48)
                    : null,
              ),
              Positioned(
                right: -4,
                bottom: -4,
                child: Material(
                  color: kOrange,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _pickPhoto,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Symbols.camera_alt,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Center(child: Text(user.email)),
        const SizedBox(height: 4),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: BoxDecoration(
              color: kOrangeLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(roleLabel(user.role),
                style: const TextStyle(color: kOrange, fontSize: 12)),
          ),
        ),
        if (user.studentId != null && user.studentId!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Center(child: Text('Student ID: ${user.studentId}')),
        ],

        if (widget.extra != null) ...[
          const SizedBox(height: 20),
          widget.extra!,
        ],

        const SizedBox(height: 24),
        TextField(
          controller: _name,
          decoration: const InputDecoration(
              labelText: 'Full Name', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _phone,
          decoration: const InputDecoration(
              labelText: 'Phone', border: OutlineInputBorder()),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _hostel,
          decoration: const InputDecoration(
              labelText: 'Hostel', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _location,
          decoration: const InputDecoration(
              labelText: 'Other location / block', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: _busy
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save changes'),
        ),
        if (widget.showLogout) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red)),
            icon: const Icon(Symbols.logout),
            label: const Text('Logout'),
            onPressed: _logout,
          ),
        ],
      ],
    );
  }
}
