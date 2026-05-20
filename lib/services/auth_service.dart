import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/app_user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _google = GoogleSignIn();

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<AppUser?> fetchProfile(String uid) async {
    final snap = await _db.collection('users').doc(uid).get();
    if (!snap.exists) return null;
    return AppUser.fromDoc(snap);
  }

  Future<AppUser> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required UserRole role,
    String? studentId,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = AppUser(
      uid: cred.user!.uid,
      email: email.trim(),
      fullName: fullName.trim(),
      phone: phone.trim(),
      studentId: studentId?.trim().isEmpty ?? true ? null : studentId!.trim(),
      role: role,
      createdAt: DateTime.now(),
    );
    await _db.collection('users').doc(user.uid).set(user.toMap());
    await cred.user!.updateDisplayName(fullName.trim());
    return user;
  }

  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Signs in with Google. Returns `null` if the user cancelled the picker.
  /// Otherwise returns the Firebase user; the caller (AuthProvider) is
  /// responsible for detecting whether a profile doc exists yet.
  Future<User?> signInWithGoogle() async {
    final googleUser = await _google.signIn();
    if (googleUser == null) return null; // user cancelled
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final cred = await _auth.signInWithCredential(credential);
    return cred.user;
  }

  /// Creates the Firestore profile doc for a Google user who just signed in
  /// for the first time. The Firebase user must already exist.
  Future<AppUser> completeGoogleProfile({
    required User firebaseUser,
    required String fullName,
    required String phone,
    required UserRole role,
    String? studentId,
  }) async {
    final user = AppUser(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      fullName: fullName.trim(),
      phone: phone.trim(),
      studentId: studentId?.trim().isEmpty ?? true ? null : studentId!.trim(),
      role: role,
      photoUrl: firebaseUser.photoURL,
      createdAt: DateTime.now(),
    );
    await _db.collection('users').doc(user.uid).set(user.toMap());
    if ((firebaseUser.displayName ?? '') != fullName.trim()) {
      await firebaseUser.updateDisplayName(fullName.trim());
    }
    return user;
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> logout() async {
    // Sign out of Google too so the next sign-in re-prompts for account choice.
    try {
      await _google.signOut();
    } catch (_) {
      // Ignore — user may not have signed in via Google in this session.
    }
    await _auth.signOut();
  }

  Future<void> updateProfile(AppUser user) async {
    await _db.collection('users').doc(user.uid).update(user.toMap());
  }
}
