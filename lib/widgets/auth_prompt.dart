import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../app_colors.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';

/// Shows a bottom-sheet prompting the guest to log in or register.
/// [context] is used for navigation so it must be a valid mounted context.
/// [message] is optional body text shown below the title.
void showAuthPrompt(
  BuildContext context, {
  String message =
      'Create an account or log in to continue.',
}) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _AuthPromptSheet(parentContext: context, message: message),
  );
}

class _AuthPromptSheet extends StatelessWidget {
  final BuildContext parentContext;
  final String message;
  const _AuthPromptSheet(
      {required this.parentContext, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 56, height: 56,
            decoration: const BoxDecoration(
              color: kOrangeLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Symbols.lock, size: 28, color: kOrange),
          ),
          const SizedBox(height: 14),
          const Text(
            'Sign in to continue',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  parentContext,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Login', style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  parentContext,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child:
                  const Text('Create account', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
