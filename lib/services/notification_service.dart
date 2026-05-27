import '../models/notification.dart';
import 'api_client.dart';

class NotificationService {
  Future<List<AppNotification>> fetchForUser(String userId) async {
    final data = await ApiClient.get('/notifications') as List;
    return data.map((e) => AppNotification.fromJson(e as Map<String, dynamic>)).toList();
  }

  Stream<List<AppNotification>> streamForUser(String userId) =>
      pollingStream(() => fetchForUser(userId), interval: const Duration(seconds: 20));

  Future<int> fetchUnreadCount(String userId) async {
    final data = await ApiClient.get('/notifications/unread-count') as Map<String, dynamic>;
    return (data['count'] as num).toInt();
  }

  Stream<int> unreadCount(String userId) =>
      pollingStream(() => fetchUnreadCount(userId), interval: const Duration(seconds: 20));

  Future<void> markRead(String id) async {
    await ApiClient.patch('/notifications/$id/read');
  }

  Future<void> markAllRead(String userId) async {
    await ApiClient.patch('/notifications/read-all');
  }
}
