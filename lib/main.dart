import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'models/app_user.dart';
import 'providers/auth_provider.dart';
import 'providers/cart_provider.dart';
import 'screens/admin/admin_dashboard.dart';
import 'screens/auth/complete_profile_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/buyer/home_screen.dart';
import 'screens/seller/seller_dashboard.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
      ],
      child: MaterialApp(
        title: 'CampLink',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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
    if (!auth.isAuthenticated) return const LoginScreen();
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
                const Icon(Icons.block, size: 72, color: Colors.red),
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
    switch (user.role) {
      case UserRole.seller:
        return const SellerDashboard();
      case UserRole.admin:
        return const AdminDashboard();
      case UserRole.buyer:
        return const BuyerHomeScreen();
    }
  }
}
