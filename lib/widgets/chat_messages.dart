import 'package:chat_app/widgets/message_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class ChatMessages extends StatelessWidget {
  const ChatMessages({super.key});
  @override
  Widget build(context) {
    final authenticatedUser = FirebaseAuth.instance.currentUser!;
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('chat')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (ctx, chatSnapshots) {
        if (chatSnapshots.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (!chatSnapshots.hasData || chatSnapshots.data!.docs.isEmpty) {
          return const Center(
            child: Text('Chưa có tin nhắn ...'),
          );
        }
        if (chatSnapshots.hasError) {
          const Center(
            child: Text('Có lỗi xảy ra'),
          );
        }

        final loadedMessage = chatSnapshots.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.only(left: 13, right: 13, bottom: 40),
          reverse: true,
          itemCount: loadedMessage.length,
          itemBuilder: (ctx, index) {
            final chatMessage = loadedMessage[index].data();
            final nextChatMessage = index+1<loadedMessage.length ? loadedMessage[index+1].data() : null;

            final currentMessageUserId = chatMessage['userId'];
            final nextMessageUserId = nextChatMessage != null ? nextChatMessage['userId'] : null;
            final nextUserIsSame = currentMessageUserId == nextMessageUserId;

            if(nextUserIsSame) {
              return MessageBubble.next(isMe: authenticatedUser.uid == currentMessageUserId, 
              message: chatMessage['text']);
            } else {
              return MessageBubble.first(
                isMe: authenticatedUser.uid == currentMessageUserId,
                message: chatMessage['text'],
                username: chatMessage['username'],
                userImage: chatMessage['image_url'],
              );
            }
          },
        );
      },
    );
  }
}