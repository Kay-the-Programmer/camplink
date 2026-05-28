import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import 'app_colors.dart';
import 'models/app_user.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/ride_prices_provider.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/auth/complete_profile_screen.dart';
import 'screens/guest/guest_home_screen.dart';
import 'screens/main_shell.dart';
import 'screens/provider/pending_verification_screen.dart';
import 'screens/provider/provider_shell.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CampLinkApp());
}

class CampLinkApp extends StatelessWidget {
  const CampLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => RidePricesProvider()),
      ],
      child: MaterialApp(
        title: 'CampLink',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: kOrange),
          useMaterial3: true,
        ),
        home: const _Root(),
      ),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.loading) return const SplashScreen();
    if (auth.needsProfileCompletion) return const CompleteProfileScreen();
    if (!auth.isAuthenticated) return const GuestHomeScreen();
    final user = auth.user!;
    if (user.suspended) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account suspended')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Symbols.block, size: 72, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Your account has been suspended.\nContact an administrator.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () => auth.logout(),
                  child: const Text('Logout'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (user.role == UserRole.admin) return const AdminDashboard();

    if (isProvider(user.role)) {
      // Verified providers get the full shell.
      if (user.isVerified) return const ProviderShell();
      // Pending / rejected providers see the holding screen.
      return PendingVerificationScreen(
        status: user.verificationStatus ?? VerificationStatus.pending,
        role: user.role,
        rejectionReason: user.rejectionReason,
      );
    }

    return const MainShell();
  }
}
