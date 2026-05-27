import '../models/chat.dart';
import 'api_client.dart';

class ChatService {
  Future<Conversation> ensureConversation({
    required String meUid,
    required String meName,
    required String otherUid,
    required String otherName,
  }) async {
    final data = await ApiClient.post('/conversations', {'otherUserId': otherUid})
        as Map<String, dynamic>;
    return Conversation.fromJson(data);
  }

  Future<List<Conversation>> fetchForUser(String uid) async {
    final data = await ApiClient.get('/conversations') as List;
    return data.map((e) => Conversation.fromJson(e as Map<String, dynamic>)).toList();
  }

  Stream<List<Conversation>> streamForUser(String uid) =>
      pollingStream(() => fetchForUser(uid), interval: const Duration(seconds: 10));

  Future<List<ChatMessage>> fetchMessages(String convoId) async {
    final data = await ApiClient.get('/conversations/$convoId/messages') as List;
    return data.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  Stream<List<ChatMessage>> streamMessages(String convoId) =>
      pollingStream(() => fetchMessages(convoId), interval: const Duration(seconds: 5));

  Future<void> send({
    required String convoId,
    required String senderId,
    required String senderName,
    required String recipientId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await ApiClient.post('/conversations/$convoId/messages', {'text': trimmed});
  }
}
