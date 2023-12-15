import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NewMessage extends StatefulWidget {
  const NewMessage({super.key});
  @override
  State<NewMessage> createState() {
    return _NewMessageState();
  }
}

class _NewMessageState extends State<NewMessage> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _messageController.dispose();
  }

  void _submitMessage() async {
    final enteredMessage = _messageController.text;

    if(enteredMessage.isEmpty) {
      return;
    }
    //restart textfield và đóng keyboard
    _messageController.clear();
    FocusScope.of(context).unfocus();
    //lấy dữ liệu từ người dùng đang login và data từ Firestore
    final user = FirebaseAuth.instance.currentUser!;
    final userData = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    //Gửi mess lên fisebasestore
    FirebaseFirestore.instance.collection('chat').add({
      'text' : enteredMessage,
      'createdAt' : Timestamp.now(),
      'userId' : user.uid,
      'username' : userData.data()!['username'],
      'image_url' : userData.data()!['image_url'],
    });

  }

  @override
  Widget build(context) {
    return
      Padding(
        padding: const EdgeInsets.all(20),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                label: Text('Tin nhắn'),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          IconButton(
            onPressed: _submitMessage,
            icon: Icon(
              Icons.send,
              color: Theme.of(context).colorScheme.primary,
              ),
          ),
        ],),
        );
  }
}