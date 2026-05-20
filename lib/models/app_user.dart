import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { buyer, seller, admin }

UserRole roleFromString(String? s) {
  switch (s) {
    case 'seller':
      return UserRole.seller;
    case 'admin':
      return UserRole.admin;
    default:
      return UserRole.buyer;
  }
}

String roleToString(UserRole r) => r.name;

class AppUser {
  final String uid;
  final String email;
  final String fullName;
  final String phone;
  final String? studentId;
  final UserRole role;
  final String? photoUrl;
  final String? hostel;
  final String? location;
  final bool suspended;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.role,
    this.studentId,
    this.photoUrl,
    this.hostel,
    this.location,
    this.suspended = false,
    required this.createdAt,
  });

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      email: d['email'] ?? '',
      fullName: d['fullName'] ?? '',
      phone: d['phone'] ?? '',
      studentId: d['studentId'],
      role: roleFromString(d['role']),
      photoUrl: d['photoUrl'],
      hostel: d['hostel'],
      location: d['location'],
      suspended: d['suspended'] ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'email': email,
        'fullName': fullName,
        'phone': phone,
        'studentId': studentId,
        'role': roleToString(role),
        'photoUrl': photoUrl,
        'hostel': hostel,
        'location': location,
        'suspended': suspended,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  AppUser copyWith({
    String? fullName,
    String? phone,
    String? studentId,
    String? photoUrl,
    String? hostel,
    String? location,
    bool? suspended,
  }) =>
      AppUser(
        uid: uid,
        email: email,
        fullName: fullName ?? this.fullName,
        phone: phone ?? this.phone,
        studentId: studentId ?? this.studentId,
        role: role,
        photoUrl: photoUrl ?? this.photoUrl,
        hostel: hostel ?? this.hostel,
        location: location ?? this.location,
        suspended: suspended ?? this.suspended,
        createdAt: createdAt,
      );
}
