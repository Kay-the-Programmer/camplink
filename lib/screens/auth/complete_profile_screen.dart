import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../app_colors.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _studentId = TextEditingController();
  UserRole _role = UserRole.buyer;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _studentId.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    try {
      final auth = context.read<AuthProvider>();
      await auth.completeGoogleProfile(
        phone: _phone.text,
        role: _role,
        studentId: _studentId.text,
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: kOrangeLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Symbols.person_add, size: 40, color: kOrange),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Complete your profile',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                if (user != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Signed in as ${user.email}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 32),

                TextFormField(
                  controller: _phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Symbols.phone),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.trim().length < 9) ? 'Enter a valid phone number' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _studentId,
                  decoration: const InputDecoration(
                    labelText: 'Student ID (optional)',
                    prefixIcon: Icon(Symbols.badge),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                Text(
                  'I want to join as…',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),

                ..._roleOptions.map((opt) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RoleTile(
                    option: opt,
                    selected: _role == opt.role,
                    onTap: () => setState(() => _role = opt.role),
                  ),
                )),

                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      Icon(Symbols.error, size: 18, color: scheme.onErrorContainer),
                      const SizedBox(width: 8),
                      Expanded(child: Text(
                        _error!,
                        style: TextStyle(color: scheme.onErrorContainer),
                      )),
                    ]),
                  ),
                ],

                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _busy
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Continue', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _busy ? null : () => context.read<AuthProvider>().logout(),
                  child: Text('Use a different account',
                      style: TextStyle(color: scheme.onSurfaceVariant)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _roleOptions = [
  _RoleOption(UserRole.buyer, Symbols.shopping_cart, 'Buyer',
      'Browse products, place orders and request deliveries.'),
  _RoleOption(UserRole.seller, Symbols.storefront, 'Seller',
      'List products and fulfill orders from other students.'),
  _RoleOption(UserRole.rider, Symbols.directions_car, 'Rider',
      'Offer campus rides and earn from bookings.'),
  _RoleOption(UserRole.driver, Symbols.delivery_dining, 'Delivery Driver',
      'Accept and complete campus delivery requests.'),
];

class _RoleOption {
  final UserRole role;
  final IconData icon;
  final String title;
  final String subtitle;
  const _RoleOption(this.role, this.icon, this.title, this.subtitle);
}

class _RoleTile extends StatelessWidget {
  final _RoleOption option;
  final bool selected;
  final VoidCallback onTap;
  const _RoleTile({required this.option, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? kOrange : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          color: selected ? kOrangeLight : Colors.transparent,
        ),
        child: Row(children: [
          Icon(option.icon, color: selected ? kOrange : Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(option.title,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selected ? kOrange : null)),
              Text(option.subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ]),
          ),
          if (selected)
            const Icon(Symbols.check_circle, color: kOrange, size: 20),
        ]),
      ),
    );
  }
}
