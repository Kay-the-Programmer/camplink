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
import 'screens/splash_screen.dart';
import 'services/push_messaging.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushMessaging.initFirebase();
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
        navigatorKey: rootNavigatorKey,
        scaffoldMessengerKey: rootMessengerKey,
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

    // Every other role — buyer, seller, rider and driver — lands in the full
    // marketplace shell so anyone can browse and buy. Providers reach their
    // dashboard and see their verification status from the Profile tab, instead
    // of being held on a blocking review screen while their application is
    // pending.
    return const MainShell();
  }
}
