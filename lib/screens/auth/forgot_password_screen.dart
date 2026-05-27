import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app_colors.dart';

/// Password reset is handled server-side via email (not yet implemented).
/// This screen informs the user to contact support.
class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Symbols.lock_reset, size: 48, color: kOrange),
            SizedBox(height: 16),
            Text(
              'To reset your password, please contact the CampLink administrator or use the app at your institution.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
