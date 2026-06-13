import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/push_messaging.dart';

class AuthProvider extends ChangeNotifier {
  /// Web OAuth client ID (client_type 3) from android/app/google-services.json.
  /// Required on Android so Google returns an [idToken] we can verify on the
  /// backend — without it `googleAuth.idToken` is null. The backend must accept
  /// this same client ID as the token audience.
  static const _googleServerClientId =
      '539638376002-c7kjflgfit25iv08gruoe2hifaj659ao.apps.googleusercontent.com';

  final AuthService _service = AuthService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: _googleServerClientId,
  );

  AppUser? _user;
  bool _loading = true;
  bool _needsProfileCompletion = false;

  AppUser? get user => _user;
  bool get loading => _loading;
  bool get isAuthenticated => _user != null;
  bool get needsProfileCompletion => _needsProfileCompletion;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    if (token != null) {
      ApiClient.setToken(token);
      try {
        _user = await _service.fetchProfile();
        PushMessaging.start();
      } catch (_) {
        await _clearToken();
      }
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
    ApiClient.setToken(token);
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    ApiClient.setToken(null);
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required UserRole role,
    String? studentId,
  }) async {
    final res = await _service.register(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
      role: role,
      studentId: studentId,
    );
    await _saveToken(res['token'] as String);
    _user = AppUser.fromJson(res['user'] as Map<String, dynamic>);
    PushMessaging.start();
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final res = await _service.login(email, password);
    await _saveToken(res['token'] as String);
    _user = AppUser.fromJson(res['user'] as Map<String, dynamic>);
    PushMessaging.start();
    notifyListeners();
  }

  /// Sign in with Google. Triggers the Google account picker, exchanges the
  /// ID token with the backend, and handles the profile-completion flow.
  Future<void> loginWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return; // user cancelled

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw const ApiException(0, 'Google sign-in failed: no ID token received.');
    }

    final res = await _service.loginWithGoogle(idToken);
    await _saveToken(res['token'] as String);
    _user = AppUser.fromJson(res['user'] as Map<String, dynamic>);
    _needsProfileCompletion =
        res['needsProfileCompletion'] as bool? ?? _user!.phone.isEmpty;
    PushMessaging.start();
    notifyListeners();
  }

  /// Called from CompleteProfileScreen after a Google user fills in their details.
  Future<void> completeGoogleProfile({
    required String phone,
    required UserRole role,
    String? studentId,
    String? fullName,
  }) async {
    final res = await _service.completeGoogleProfile(
      phone: phone,
      role: role,
      studentId: studentId,
      fullName: fullName,
    );
    await _saveToken(res['token'] as String);

    _user = AppUser.fromJson(res['user'] as Map<String, dynamic>);
    _needsProfileCompletion = false;
    notifyListeners();
  }

  Future<void> logout() async {
    // Unregister the device token while we're still authenticated.
    await PushMessaging.stop();
    _user = null;
    _needsProfileCompletion = false;
    await _clearToken();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> updateProfile(AppUser updated) async {
    _user = await _service.updateProfile(updated);
    notifyListeners();
  }

  /// Buyer requests a provider account; on success the role changes to the
  /// requested provider role with a PENDING verification status.
  Future<void> requestUpgrade(UserRole role) async {
    _user = await _service.requestUpgrade(role);
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    try {
      _user = await _service.fetchProfile();
      notifyListeners();
    } catch (_) {}
  }
}
