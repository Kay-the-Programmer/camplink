// ── Roles ─────────────────────────────────────────────────────────────────────

enum UserRole { buyer, seller, rider, driver, admin }

UserRole roleFromString(String? s) {
  switch (s?.toUpperCase()) {
    case 'SELLER': return UserRole.seller;
    case 'RIDER':  return UserRole.rider;
    case 'DRIVER': return UserRole.driver;
    case 'ADMIN':  return UserRole.admin;
    default:       return UserRole.buyer;
  }
}

String roleLabel(UserRole r) {
  switch (r) {
    case UserRole.buyer:  return 'Buyer';
    case UserRole.seller: return 'Seller';
    case UserRole.rider:  return 'Rider';
    case UserRole.driver: return 'Delivery Driver';
    case UserRole.admin:  return 'Admin';
  }
}

/// True for any role that requires admin verification before operating.
bool isProvider(UserRole r) =>
    r == UserRole.seller || r == UserRole.rider || r == UserRole.driver;

/// True only for riders and drivers whose application has been approved — the
/// sole users allowed to view and accept the open delivery pool. Everyone else
/// (buyers, sellers, pending riders/drivers) must never see those requests.
bool canRunDeliveries(AppUser? u) =>
    u != null &&
    (u.role == UserRole.rider || u.role == UserRole.driver) &&
    u.isVerified;

// ── Verification status ───────────────────────────────────────────────────────

enum VerificationStatus { pending, approved, rejected }

VerificationStatus verificationStatusFromString(String? s) {
  switch (s?.toUpperCase()) {
    case 'APPROVED': return VerificationStatus.approved;
    case 'REJECTED': return VerificationStatus.rejected;
    default:         return VerificationStatus.pending;
  }
}

String verificationStatusToApi(VerificationStatus s) => s.name.toUpperCase();

// ── User model ────────────────────────────────────────────────────────────────

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

  /// Non-null only for providers (seller / rider / driver).
  /// Null means the account type does not require verification (buyer/admin).
  final VerificationStatus? verificationStatus;

  /// Populated by the admin when rejecting an application.
  final String? rejectionReason;

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
    this.verificationStatus,
    this.rejectionReason,
  });

  // ── Derived helpers ─────────────────────────────────────────────────────────

  /// True when this provider account has been approved to operate.
  /// Always true for non-providers (buyers / admins).
  bool get isVerified {
    if (!isProvider(role)) return true;
    return verificationStatus == VerificationStatus.approved;
  }

  // ── JSON ────────────────────────────────────────────────────────────────────

  factory AppUser.fromJson(Map<String, dynamic> j) {
    final role = roleFromString(j['role'] as String?);
    return AppUser(
      uid:       j['id'] as String,
      email:     j['email'] as String,
      fullName:  j['fullName'] as String,
      phone:     j['phone'] as String? ?? '',
      studentId: j['studentId'] as String?,
      role:      role,
      photoUrl:  j['photoUrl'] as String?,
      hostel:    j['hostel'] as String?,
      location:  j['location'] as String?,
      suspended: j['suspended'] as bool? ?? false,
      createdAt: j['createdAt'] != null
          ? DateTime.parse(j['createdAt'] as String)
          : DateTime.now(),
      // Only parse verificationStatus for provider roles.
      verificationStatus: isProvider(role)
          ? verificationStatusFromString(j['verificationStatus'] as String?)
          : null,
      rejectionReason: j['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'fullName':  fullName,
        'phone':     phone,
        'studentId': studentId,
        'photoUrl':  photoUrl,
        'hostel':    hostel,
        'location':  location,
      };

  AppUser copyWith({
    String? fullName,
    String? phone,
    String? studentId,
    String? photoUrl,
    String? hostel,
    String? location,
    bool? suspended,
    VerificationStatus? verificationStatus,
    String? rejectionReason,
  }) =>
      AppUser(
        uid:                uid,
        email:              email,
        fullName:           fullName           ?? this.fullName,
        phone:              phone              ?? this.phone,
        studentId:          studentId          ?? this.studentId,
        role:               role,
        photoUrl:           photoUrl           ?? this.photoUrl,
        hostel:             hostel             ?? this.hostel,
        location:           location           ?? this.location,
        suspended:          suspended          ?? this.suspended,
        createdAt:          createdAt,
        verificationStatus: verificationStatus ?? this.verificationStatus,
        rejectionReason:    rejectionReason    ?? this.rejectionReason,
      );
}
