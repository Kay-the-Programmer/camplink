import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:image_picker/image_picker.dart';

import '../../app_colors.dart';
import '../../models/app_user.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/storage_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _name;
  late TextEditingController _phone;
  late TextEditingController _hostel;
  late TextEditingController _location;
  XFile? _pickedPhoto;
  Uint8List? _pickedPhotoBytes; // needed for web preview (no File.path access)
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().user;
    _name = TextEditingController(text: u?.fullName ?? '');
    _phone = TextEditingController(text: u?.phone ?? '');
    _hostel = TextEditingController(text: u?.hostel ?? '');
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
    final x = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 600, imageQuality: 80);
    if (x == null) return;
    final bytes = await x.readAsBytes();
    setState(() {
      _pickedPhoto = x;
      _pickedPhotoBytes = bytes;
    });
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
        phone: _phone.text.trim(),
        hostel: _hostel.text.trim(),
        location: _location.text.trim(),
        photoUrl: photoUrl,
      ));
      if (mounted) {
        setState(() {
          _pickedPhoto = null;
          _pickedPhotoBytes = null;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Profile updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Symbols.logout),
            onPressed: () => auth.logout(),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundImage: _pickedPhotoBytes != null
                            ? MemoryImage(_pickedPhotoBytes!) as ImageProvider
                            : (user.photoUrl != null
                                ? CachedNetworkImageProvider(user.photoUrl!)
                                : null),
                        child: (_pickedPhotoBytes == null &&
                                user.photoUrl == null)
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
                const SizedBox(height: 12),
                Center(child: Text(user.email)),
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 3),
                    decoration: BoxDecoration(
                      color: kOrangeLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      roleLabel(user.role),
                      style: const TextStyle(
                          color: kOrange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                if (user.studentId != null)
                  Center(child: Text('Student ID: ${user.studentId}')),
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
              ],
            ),
    );
  }
}
