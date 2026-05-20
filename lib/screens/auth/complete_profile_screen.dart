import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';

/// Shown after a brand-new Google sign-in — the Firebase user exists but no
/// Firestore profile doc does. Collects the fields Google can't give us
/// (phone, role, student ID) and pre-fills name from the Google account.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _form = GlobalKey<FormState>();
  late TextEditingController _name;
  final _phone = TextEditingController();
  final _studentId = TextEditingController();
  UserRole _role = UserRole.buyer;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final fb = context.read<AuthProvider>().pendingFirebaseUser;
    _name = TextEditingController(text: fb?.displayName ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _studentId.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().completeGoogleProfile(
            fullName: _name.text,
            phone: _phone.text,
            role: _role,
            studentId: _studentId.text,
          );
      // Root listener will re-route automatically.
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final fb = auth.pendingFirebaseUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finish your account'),
        actions: [
          TextButton(
            onPressed: () => auth.logout(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: fb?.photoURL != null
                        ? CachedNetworkImageProvider(fb!.photoURL!)
                        : null,
                    child: fb?.photoURL == null
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                if (fb?.email != null)
                  Center(
                      child: Text(fb!.email!,
                          style: const TextStyle(color: Colors.grey))),
                const SizedBox(height: 16),
                const Text(
                  "We need a couple more details before you can start shopping.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                      labelText: 'Full Name', border: OutlineInputBorder()),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  decoration: const InputDecoration(
                      labelText: 'Phone Number', border: OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().length < 9)
                      ? 'Enter a valid phone number'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _studentId,
                  decoration: const InputDecoration(
                      labelText: 'Student ID (optional)',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                const Text('Account type'),
                const SizedBox(height: 4),
                SegmentedButton<UserRole>(
                  segments: const [
                    ButtonSegment(value: UserRole.buyer, label: Text('Buyer')),
                    ButtonSegment(value: UserRole.seller, label: Text('Seller')),
                  ],
                  selected: {_role},
                  onSelectionChanged: (s) => setState(() => _role = s.first),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Finish'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
