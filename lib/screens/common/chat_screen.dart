import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/chat.dart';
import '../../providers/auth_provider.dart';
import '../../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String otherUid;
  final String otherName;
  const ChatScreen({super.key, required this.otherUid, required this.otherName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _svc = ChatService();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  String? _convoId;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final me = context.read<AuthProvider>().user;
    if (me == null) return;
    final id = await _svc.ensureConversation(
      meUid: me.uid,
      meName: me.fullName.isEmpty ? me.email : me.fullName,
      otherUid: widget.otherUid,
      otherName: widget.otherName,
    );
    if (mounted) setState(() => _convoId = id);
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final me = context.read<AuthProvider>().user;
    if (me == null || _convoId == null) return;
    final text = _input.text;
    _input.clear();
    await _svc.send(
      convoId: _convoId!,
      senderId: me.uid,
      senderName: me.fullName.isEmpty ? me.email : me.fullName,
      recipientId: widget.otherUid,
      text: text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<AuthProvider>().user;
    return Scaffold(
      appBar: AppBar(title: Text(widget.otherName)),
      body: Column(
        children: [
          Expanded(
            child: _convoId == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<List<ChatMessage>>(
                    stream: _svc.streamMessages(_convoId!),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final msgs = snap.data ?? [];
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scroll.hasClients) {
                          _scroll.jumpTo(_scroll.position.maxScrollExtent);
                        }
                      });
                      if (msgs.isEmpty) {
                        return const Center(
                            child: Text('Say hi to start the conversation.'));
                      }
                      return ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(12),
                        itemCount: msgs.length,
                        itemBuilder: (_, i) {
                          final m = msgs[i];
                          final mine = m.senderId == me?.uid;
                          return Align(
                            alignment:
                                mine ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              constraints: BoxConstraints(
                                maxWidth:
                                    MediaQuery.of(context).size.width * 0.75,
                              ),
                              decoration: BoxDecoration(
                                color: mine
                                    ? Colors.deepPurple
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    m.text,
                                    style: TextStyle(
                                        color: mine ? Colors.white : Colors.black),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat.jm().format(m.sentAt),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: mine
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.deepPurple),
                    onPressed: _send,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
