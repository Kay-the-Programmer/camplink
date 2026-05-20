import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();
  AppUser? _user;
  User? _pendingFirebaseUser; // signed in via Google but no Firestore profile yet
  bool _loading = true;

  AppUser? get user => _user;
  User? get pendingFirebaseUser => _pendingFirebaseUser;
  bool get loading => _loading;
  bool get isAuthenticated => _user != null;
  bool get needsProfileCompletion => _user == null && _pendingFirebaseUser != null;

  AuthProvider() {
    _service.authStateChanges().listen((fbUser) async {
      if (fbUser == null) {
        _user = null;
        _pendingFirebaseUser = null;
      } else {
        final profile = await _service.fetchProfile(fbUser.uid);
        if (profile == null) {
          // Firebase user exists (e.g. just authed via Google) but the
          // Firestore profile doc hasn't been created yet — route to the
          // "Complete your profile" screen.
          _user = null;
          _pendingFirebaseUser = fbUser;
        } else {
          _user = profile;
          _pendingFirebaseUser = null;
        }
      }
      _loading = false;
      notifyListeners();
    });
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required UserRole role,
    String? studentId,
  }) async {
    _user = await _service.register(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
      role: role,
      studentId: studentId,
    );
    notifyListeners();
  }

  Future<void> login(String email, String password) =>
      _service.login(email, password);

  /// Returns true if Google sign-in completed (the auth state listener will
  /// pick it up and route accordingly). Returns false if the user cancelled
  /// the Google account picker.
  Future<bool> signInWithGoogle() async {
    final user = await _service.signInWithGoogle();
    return user != null;
  }

  Future<void> completeGoogleProfile({
    required String fullName,
    required String phone,
    required UserRole role,
    String? studentId,
  }) async {
    final fb = _pendingFirebaseUser;
    if (fb == null) {
      throw StateError('No pending Firebase user to complete.');
    }
    _user = await _service.completeGoogleProfile(
      firebaseUser: fb,
      fullName: fullName,
      phone: phone,
      role: role,
      studentId: studentId,
    );
    _pendingFirebaseUser = null;
    notifyListeners();
  }

  Future<void> resetPassword(String email) => _service.resetPassword(email);

  Future<void> logout() => _service.logout();

  Future<void> updateProfile(AppUser updated) async {
    await _service.updateProfile(updated);
    _user = updated;
    notifyListeners();
  }
}
