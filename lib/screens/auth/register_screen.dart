import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../app_colors.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';

class _RoleOption {
  final UserRole role;
  final IconData icon;
  final String title;
  final String subtitle;
  const _RoleOption(this.role, this.icon, this.title, this.subtitle);
}

const _roleOptions = [
  _RoleOption(
    UserRole.buyer,
    Symbols.shopping_cart,
    'Buyer',
    'Browse products, place orders and request deliveries.',
  ),
  _RoleOption(
    UserRole.seller,
    Symbols.storefront,
    'Seller',
    'List products and fulfill orders from other students.',
  ),
  _RoleOption(
    UserRole.rider,
    Symbols.directions_car,
    'Rider',
    'Offer campus rides and earn from bookings.',
  ),
  _RoleOption(
    UserRole.driver,
    Symbols.delivery_dining,
    'Delivery Driver',
    'Accept and complete campus delivery requests.',
  ),
];

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _studentId = TextEditingController();
  final _password = TextEditingController();
  UserRole _role = UserRole.buyer;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _studentId.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().register(
            email: _email.text,
            password: _password.text,
            fullName: _name.text,
            phone: _phone.text,
            role: _role,
            studentId: _studentId.text,
          );
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                      labelText: 'Full Name', border: OutlineInputBorder()),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(
                      labelText: 'Email', border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Enter a valid email'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  decoration: const InputDecoration(
                      labelText: 'Phone Number', border: OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                  validator: (v) =>
                      (v == null || v.trim().length < 9) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _studentId,
                  decoration: const InputDecoration(
                      labelText: 'Student ID (optional)',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _password,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  obscureText: _obscure,
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Min 6 characters' : null,
                ),
                const SizedBox(height: 16),
                const Text(
                  'I want to join as…',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                ..._roleOptions.map(
                  (opt) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => setState(() => _role = opt.role),
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _role == opt.role
                                ? kOrange
                                : Colors.grey.shade300,
                            width: _role == opt.role ? 2 : 1,
                          ),
                          color: _role == opt.role
                              ? kOrangeLight
                              : Colors.transparent,
                        ),
                        child: Row(children: [
                          Icon(opt.icon,
                              color: _role == opt.role
                                  ? kOrange
                                  : Colors.grey.shade600),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(opt.title,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: _role == opt.role
                                            ? kOrange
                                            : null)),
                                Text(opt.subtitle,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600)),
                              ],
                            ),
                          ),
                          if (_role == opt.role)
                            const Icon(Symbols.check_circle,
                                color: kOrange, size: 20),
                        ]),
                      ),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(children: [
                      Icon(Icons.error_outline, size: 18,
                          color: Theme.of(context).colorScheme.onErrorContainer),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!,
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onErrorContainer))),
                    ]),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
