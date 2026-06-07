import '../models/app_user.dart';
import 'api_client.dart';

class AuthService {
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required UserRole role,
    String? studentId,
  }) async {
    return await ApiClient.post('/auth/register', {
      'email':     email.trim(),
      'password':  password,
      'fullName':  fullName.trim(),
      'phone':     phone.trim(),
      'studentId': studentId?.trim().isEmpty ?? true ? null : studentId!.trim(),
      'role':      role.name.toUpperCase(),
    }) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    return await ApiClient.post('/auth/login', {
      'email':    email.trim(),
      'password': password,
    }) as Map<String, dynamic>;
  }

  /// Exchange a Google ID token for a CampLink JWT.
  /// The backend should verify the token and return {token, user, needsProfileCompletion?}.
  Future<Map<String, dynamic>> loginWithGoogle(String idToken) async {
    return await ApiClient.post('/auth/google', {
      'idToken': idToken,
    }) as Map<String, dynamic>;
  }

  /// Complete profile for Google users who need to set phone/role after OAuth.
  Future<Map<String, dynamic>> completeGoogleProfile({
    required String phone,
    required UserRole role,
    String? studentId,
    String? fullName,
  }) async {
    return await ApiClient.post('/auth/complete-profile', {
      'phone':     phone.trim(),
      'role':      role.name.toUpperCase(),
      if (studentId != null && studentId.trim().isNotEmpty)
        'studentId': studentId.trim(),
      if (fullName != null && fullName.trim().isNotEmpty)
        'fullName': fullName.trim(),
    }) as Map<String, dynamic>;
  }

  Future<AppUser> fetchProfile() async {
    final data = await ApiClient.get('/auth/me') as Map<String, dynamic>;
    return AppUser.fromJson(data);
  }

  /// Buyer requests to become a provider (seller / rider / driver). The account
  /// is moved into the pending-verification queue for an admin to review.
  Future<AppUser> requestUpgrade(UserRole role) async {
    final data = await ApiClient.post('/auth/upgrade-request', {
      'role': role.name.toUpperCase(),
    }) as Map<String, dynamic>;
    return AppUser.fromJson(data);
  }

  Future<AppUser> updateProfile(AppUser user) async {
    final data = await ApiClient.put('/auth/me', user.toMap()) as Map<String, dynamic>;
    return AppUser.fromJson(data);
  }
}
