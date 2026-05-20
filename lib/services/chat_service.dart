import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/chat.dart';
import '../models/notification.dart';
import 'notification_service.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notif = NotificationService();

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _db.collection('conversations');

  CollectionReference<Map<String, dynamic>> _messages(String convoId) =>
      _conversations.doc(convoId).collection('messages');

  Future<String> ensureConversation({
    required String meUid,
    required String meName,
    required String otherUid,
    required String otherName,
  }) async {
    final id = conversationIdFor(meUid, otherUid);
    final docRef = _conversations.doc(id);
    final snap = await docRef.get();
    if (!snap.exists) {
      await docRef.set({
        'participants': [meUid, otherUid],
        'participantNames': {meUid: meName, otherUid: otherName},
        'lastMessage': '',
        'lastSenderId': '',
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    }
    return id;
  }

  Stream<List<Conversation>> streamForUser(String uid) => _conversations
      .where('participants', arrayContains: uid)
      .orderBy('updatedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Conversation.fromDoc).toList());

  Stream<List<ChatMessage>> streamMessages(String convoId) =>
      _messages(convoId)
          .orderBy('sentAt')
          .snapshots()
          .map((s) => s.docs.map(ChatMessage.fromDoc).toList());

  Future<void> send({
    required String convoId,
    required String senderId,
    required String senderName,
    required String recipientId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final now = DateTime.now();
    await _messages(convoId).add(ChatMessage(
      id: '',
      senderId: senderId,
      text: trimmed,
      sentAt: now,
    ).toMap());
    await _conversations.doc(convoId).update({
      'lastMessage': trimmed,
      'lastSenderId': senderId,
      'updatedAt': Timestamp.fromDate(now),
    });
    await _notif.push(
      userId: recipientId,
      type: NotificationType.message,
      title: 'New message from $senderName',
      body: trimmed.length > 80 ? '${trimmed.substring(0, 80)}…' : trimmed,
    );
  }
}
