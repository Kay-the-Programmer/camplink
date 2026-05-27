import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/chat.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: StreamBuilder<List<Conversation>>(
        stream: ChatService().streamForUser(user.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final convos = snap.data ?? [];
          if (convos.isEmpty) {
            return const Center(child: Text('No conversations yet.'));
          }
          return ListView.separated(
            itemCount: convos.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final c = convos[i];
              final otherName = c.otherParticipantName(user.uid);
              return ListTile(
                leading: const CircleAvatar(child: Icon(Symbols.person)),
                title: Text(otherName),
                subtitle: Text(
                  c.lastMessage.isEmpty ? '(no messages yet)' : c.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: c.updatedAt != null
                    ? Text(
                        DateFormat.MMMd().add_jm().format(c.updatedAt!),
                        style: const TextStyle(fontSize: 11),
                      )
                    : null,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      otherUid: c.otherParticipantId(user.uid),
                      otherName: otherName,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
