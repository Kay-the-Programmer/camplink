import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../app_colors.dart';
import '../models/app_user.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../services/storage_service.dart';
import 'confirm.dart';

/// Shared profile view + editor used by both the buyer shell and the seller
/// dashboard. Shows the avatar, identity, and contact details. Details are
/// read-only by default; tapping "Edit profile" reveals editable fields. Pass
/// an [extra] widget to inject role-specific content (e.g. the provider status
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
  bool _editing = false;

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

  /// Reset the controllers to the stored values, then enter edit mode.
  void _startEditing() {
    final u = context.read<AuthProvider>().user;
    _name.text     = u?.fullName ?? '';
    _phone.text    = u?.phone ?? '';
    _hostel.text   = u?.hostel ?? '';
    _location.text = u?.location ?? '';
    setState(() => _editing = true);
  }

  void _cancelEditing() {
    setState(() {
      _editing = false;
      _pickedPhoto = null;
      _pickedBytes = null;
    });
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
          _editing = false;
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

  Future<void> _logout() async {
    final ok = await confirmAction(
      context,
      title: 'Log out?',
      message: 'You will need to sign in again to continue.',
      confirmLabel: 'Log out',
      icon: Symbols.logout,
      destructive: true,
    );
    if (!ok || !mounted) return;
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
                        ? NetworkImage(ApiClient.fileUrl(user.photoUrl))
                        : null),
                child: (_pickedBytes == null && user.photoUrl == null)
                    ? const Icon(Symbols.person, size: 48)
                    : null,
              ),
              // Camera button only while editing.
              if (_editing)
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
        // Details: read-only view, or editable fields.
        if (_editing) _buildEditFields() else _buildReadonly(user),

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

  // ── Read-only details + Edit button ─────────────────────────────────────────

  Widget _buildReadonly(AppUser user) {
    return Column(
      children: [
        _InfoRow(
            icon: Symbols.person, label: 'Full Name', value: user.fullName),
        _InfoRow(icon: Symbols.phone, label: 'Phone', value: user.phone),
        _InfoRow(
            icon: Symbols.home, label: 'Hostel', value: user.hostel ?? ''),
        _InfoRow(
            icon: Symbols.location_on,
            label: 'Other location / block',
            value: user.location ?? ''),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          icon: const Icon(Symbols.edit),
          label: const Text('Edit profile'),
          onPressed: _startEditing,
        ),
      ],
    );
  }

  // ── Editable fields + Save / Cancel ─────────────────────────────────────────

  Widget _buildEditFields() {
    return Column(
      children: [
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
              labelText: 'Other location / block',
              border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : _cancelEditing,
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save changes'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// A single read-only labelled field in the profile view.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? 'Not set' : value,
                  style: TextStyle(
                    fontSize: 15,
                    color: value.isEmpty ? Colors.grey : null,
                    fontStyle:
                        value.isEmpty ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
