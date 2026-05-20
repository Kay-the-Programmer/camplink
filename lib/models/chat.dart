import 'package:cloud_firestore/cloud_firestore.dart';

/// Deterministic conversation ID from two participants — sort both UIDs to
/// guarantee both users land on the same doc regardless of who starts the chat.
String conversationIdFor(String a, String b) {
  final pair = [a, b]..sort();
  return '${pair[0]}_${pair[1]}';
}

class Conversation {
  final String id;
  final List<String> participants;
  final Map<String, String> participantNames;
  final String lastMessage;
  final String lastSenderId;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.participants,
    required this.participantNames,
    required this.lastMessage,
    required this.lastSenderId,
    required this.updatedAt,
  });

  factory Conversation.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Conversation(
      id: doc.id,
      participants: List<String>.from(d['participants'] ?? const []),
      participantNames:
          Map<String, String>.from(d['participantNames'] ?? const {}),
      lastMessage: d['lastMessage'] ?? '',
      lastSenderId: d['lastSenderId'] ?? '',
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  String otherParticipantId(String me) =>
      participants.firstWhere((p) => p != me, orElse: () => me);
  String otherParticipantName(String me) =>
      participantNames[otherParticipantId(me)] ?? 'User';
}

class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime sentAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
  });

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return ChatMessage(
      id: doc.id,
      senderId: d['senderId'] ?? '',
      text: d['text'] ?? '',
      sentAt: (d['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'text': text,
        'sentAt': Timestamp.fromDate(sentAt),
      };
}
