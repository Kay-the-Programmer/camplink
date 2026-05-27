import '../models/app_user.dart';
import 'api_client.dart';

class AdminService {
  // ── Users ──────────────────────────────────────────────────────────────────

  Future<List<AppUser>> fetchUsers() async {
    final data = await ApiClient.get('/admin/users') as List;
    return data.map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  Stream<List<AppUser>> streamUsers() => pollingStream(fetchUsers);

  Future<void> setSuspended(String uid, bool suspended) async {
    await ApiClient.patch('/admin/users/$uid/suspend', {'suspended': suspended});
  }

  Future<void> setRole(String uid, UserRole role) async {
    await ApiClient.patch(
        '/admin/users/$uid/role', {'role': role.name.toUpperCase()});
  }

  // ── Provider verification ─────────────────────────────────────────────────

  /// Approve or reject a pending service-provider application.
  /// [reason] is required when [approved] is false.
  Future<void> verifyProvider(
    String uid, {
    required bool approved,
    String? reason,
  }) async {
    await ApiClient.patch('/admin/users/$uid/verify', {
      'verificationStatus': approved ? 'APPROVED' : 'REJECTED',
      if (!approved && reason != null) 'rejectionReason': reason,
    });
  }
}
