import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dicoding_chatting/pages/login_page.dart';
import 'package:dicoding_chatting/widgets/message_bubble.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  static const String id = 'chat_page';

  const ChatPage({Key? key}) : super(key: key);

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late User? _activeUser;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _messageTextController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getCurrentUser();
  }

  void getCurrentUser() {
    try {
      _activeUser = _auth.currentUser;
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Room'),
        actions: [
          IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Logout',
              onPressed: () async {
                final navigator = Navigator.of(context);
                await _auth.signOut();
                navigator.pushReplacementNamed(LoginPage.id);
              })
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _firestore
                    .collection('message')
                    .orderBy('dataCreated', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ListView(
                    reverse: true,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 16.0,
                    ),
                    children: snapshot.data!.docs.map((document) {
                      final data = document.data();
                      final String messageText = data['text'];
                      final String messageSender = data['sender'];
                      return MessageBubble(
                        sender: messageSender,
                        text: messageText,
                        isMyChat: messageSender == _activeUser?.email,
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageTextController,
                    decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                MaterialButton(
                  color: Theme.of(context).primaryColor,
                  textTheme: ButtonTextTheme.primary,
                  onPressed: () {
                    _firestore.collection('message').add({
                      'text': _messageTextController.text,
                      'sender': _activeUser?.email,
                      'dataCreated': Timestamp.now(),
                    });

                    _messageTextController.clear();
                  },
                  child: const Text('SEND'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageTextController.dispose();
    super.dispose();
  }
}
