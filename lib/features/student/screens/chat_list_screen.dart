import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/chat_service.dart';
import '../../../shared/models/user_model.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  final ChatService _chatService = ChatService();

  ChatListScreen({super.key});

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ [ChatListScreen] No user signed in.');
      return const Scaffold(
        body: Center(child: Text('Please sign in first.')),
      );
    }

    print('👤 [ChatListScreen] Logged-in user: ${user.uid}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Chats'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _chatService.getUserChats(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            print('⏳ [ChatListScreen] Waiting for chat stream...');
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print('❌ [ChatListScreen] Stream error: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            print('📭 [ChatListScreen] No chats found for ${user.uid}');
            return const Center(child: Text('No chats yet.'));
          }

          final chats = snapshot.data!.docs;
          print('💬 [ChatListScreen] Loaded ${chats.length} chat(s)');

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final data = chat.data();
              final chatId = chat.id;

              print('📦 [ChatListScreen] Chat $index → ID: $chatId | Data: $data');

              final participants = List<String>.from(data['participants'] ?? []);
              print('👥 [ChatListScreen] Participants: $participants');

              final otherUserId = participants.firstWhere(
                (id) => id != user.uid,
                orElse: () => '',
              );

              if (otherUserId.isEmpty) {
                print('⚠️ [ChatListScreen] No other user found for chat $chatId');
                return const ListTile(
                  leading: CircleAvatar(child: Icon(Icons.person)),
                  title: Text('Unknown chat'),
                );
              }

              print('🔍 [ChatListScreen] Fetching other user profile: $otherUserId');

              return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    print('⏳ [ChatListScreen] Waiting for user $otherUserId data...');
                    return const ListTile(
                      leading: CircleAvatar(child: Icon(Icons.person)),
                      title: Text('Loading...'),
                    );
                  }

                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    print('❌ [ChatListScreen] User $otherUserId not found in Firestore');
                    return const ListTile(
                      leading: CircleAvatar(child: Icon(Icons.error)),
                      title: Text('User not found'),
                    );
                  }

                  final userDoc = userSnapshot.data;
                  final userData = userDoc?.data() ?? <String, dynamic>{};

                  print('📄 [ChatListScreen] User data for $otherUserId: $userData');

                  final Map<String, dynamic> modelMap = {
                    ...userData,
                    'id': otherUserId,
                    'email': userData['email'] ?? '${otherUserId}@example.com',
                    'createdAt': userData['createdAt'] ?? Timestamp.fromDate(DateTime.now()),
                    'updatedAt': userData['updatedAt'] ?? Timestamp.fromDate(DateTime.now()),
                    'role': userData['role'] ?? 'teacher',
                  };

                  final otherUser = UserModel.fromJson(modelMap);
                  final otherUserName = otherUser.name;
                  final otherUserProfile = otherUser.profileImageUrl;

                  print('✅ [ChatListScreen] Ready to show chat with: $otherUserName ($otherUserId)');

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: otherUserProfile != null
                          ? NetworkImage(otherUserProfile)
                          : null,
                      child: otherUserProfile == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(
                      otherUserName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      data['lastMessage'] as String? ?? 'No messages yet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: data['lastMessageTime'] != null
                        ? Text(
                            _formatTimestamp(data['lastMessageTime'] as Timestamp?),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          )
                        : null,
                    onTap: () {
                      print('➡️ [ChatListScreen] Opening chat with $otherUserName (ID: $chatId)');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            chatId: chat.id,
                            tutor: otherUser,
                            currentUserId: user.uid,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
