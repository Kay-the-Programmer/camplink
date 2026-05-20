import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/app_user.dart';

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<AppUser>> streamUsers() => _db
      .collection('users')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(AppUser.fromDoc).toList());

  Future<void> setSuspended(String uid, bool suspended) async {
    await _db.collection('users').doc(uid).update({'suspended': suspended});
  }

  Future<void> setRole(String uid, UserRole role) async {
    await _db.collection('users').doc(uid).update({'role': roleToString(role)});
  }
}
