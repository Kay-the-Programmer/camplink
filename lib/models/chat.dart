class Conversation {
  final String id;
  final List<ParticipantInfo> participants;
  final String lastMessage;
  final String lastSenderId;
  final DateTime? updatedAt;

  Conversation({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastSenderId,
    this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> j) => Conversation(
        id:           j['id'] as String,
        participants: (j['participants'] as List)
            .map((e) => ParticipantInfo.fromJson(e as Map<String, dynamic>))
            .toList(),
        lastMessage:  j['lastMessage'] as String? ?? '',
        lastSenderId: j['lastSenderId'] as String? ?? '',
        updatedAt:    j['updatedAt'] != null
            ? DateTime.parse(j['updatedAt'] as String)
            : null,
      );

  String otherParticipantId(String me) =>
      participants.firstWhere((p) => p.id != me, orElse: () => participants.first).id;

  String otherParticipantName(String me) =>
      participants.firstWhere((p) => p.id != me, orElse: () => participants.first).name;
}

class ParticipantInfo {
  final String id;
  final String name;
  final String? photoUrl;

  const ParticipantInfo({required this.id, required this.name, this.photoUrl});

  factory ParticipantInfo.fromJson(Map<String, dynamic> j) => ParticipantInfo(
        id:       j['id'] as String,
        name:     j['name'] as String,
        photoUrl: j['photoUrl'] as String?,
      );
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime sentAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.sentAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id:             j['id'] as String,
        conversationId: j['conversationId'] as String,
        senderId:       j['senderId'] as String,
        senderName:     j['senderName'] as String,
        text:           j['text'] as String,
        sentAt:         DateTime.parse(j['sentAt'] as String),
      );
}
