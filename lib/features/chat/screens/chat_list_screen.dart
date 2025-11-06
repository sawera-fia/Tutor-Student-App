import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../services/chat_service.dart';
import '../../../shared/models/user_model.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } else if (messageDate == yesterday) {
      return "Yesterday";
    } else if (date.year == now.year) {
      return "${_getMonthName(date.month)} ${date.day}";
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    print('💬 [ChatListScreen] Building ChatListScreen...');
    final user = FirebaseAuth.instance.currentUser;

    // 🧩 SAFETY CHUNK — prevent null user crash
    if (user == null) {
      print('❌ [ChatListScreen] No user is currently signed in!');
      return const Scaffold(
        body: Center(
          child: Text(
            'Please sign in to view your chats.',
            style: TextStyle(fontSize: 16, color: Colors.red),
          ),
        ),
      );
    }

    if (user.uid.isEmpty) {
      print(
        '⚠️ [ChatListScreen] User UID is empty. Something is wrong with Firebase Auth.',
      );
      return const Scaffold(
        body: Center(
          child: Text('Invalid user session. Please sign in again.'),
        ),
      );
    }

    print('👤 [ChatListScreen] Logged-in user UID: ${user.uid}');

    // 🧩 Get user chats stream
    final userChatsStream = _chatService.getUserChats(user.uid);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Chats',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 24,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Add new chat functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('New chat feature coming soon!')),
              );
            },
            icon: const Icon(Icons.edit, color: Colors.black54),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search chats...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.clear, color: Colors.grey),
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
          // Chat List
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: userChatsStream,
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
                  print(
                    '📭 [ChatListScreen] No chats found for user: ${user.uid}',
                  );
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No chats yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start a conversation with a tutor',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                final chats = snapshot.data!.docs;
                print('💬 [ChatListScreen] Loaded ${chats.length} chat(s).');

                // Filter chats based on search query
                final filteredChats = chats.where((chat) {
                  if (_searchQuery.isEmpty) return true;
                  // We'll filter by tutor name after we fetch the user data
                  return true; // For now, we'll filter in the ListTile
                }).toList();

                return ListView.builder(
                  itemCount: filteredChats.length,
                  itemBuilder: (context, index) {
                    final chat = filteredChats[index];
                    final data = chat.data();
                    final chatId = chat.id;

                    print(
                      '📦 [ChatListScreen] Chat $index → ID: $chatId | Data: $data',
                    );

                    final participants = List<String>.from(
                      data['participants'] ?? [],
                    );
                    print('👥 [ChatListScreen] Participants: $participants');

                    if (participants.isEmpty) {
                      print(
                        '⚠️ [ChatListScreen] No participants found for chat: $chatId',
                      );
                      return const ListTile(
                        leading: CircleAvatar(child: Icon(Icons.warning)),
                        title: Text('Corrupted chat data'),
                      );
                    }

                    final otherUserId = participants.firstWhere(
                      (id) => id != user.uid,
                      orElse: () => '',
                    );

                    if (otherUserId.isEmpty) {
                      print(
                        '⚠️ [ChatListScreen] Could not determine other participant in chat: $chatId',
                      );
                      return const ListTile(
                        leading: CircleAvatar(child: Icon(Icons.person)),
                        title: Text('Unknown chat'),
                      );
                    }

                    print(
                      '🔍 [ChatListScreen] Fetching profile for other user: $otherUserId',
                    );

                    return FutureBuilder<
                      DocumentSnapshot<Map<String, dynamic>>
                    >(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(otherUserId)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          print(
                            '⏳ [ChatListScreen] Waiting for user data: $otherUserId',
                          );
                          return const ListTile(
                            leading: CircleAvatar(child: Icon(Icons.person)),
                            title: Text('Loading user...'),
                          );
                        }

                        if (userSnapshot.hasError) {
                          print(
                            '❌ [ChatListScreen] Error fetching user $otherUserId: ${userSnapshot.error}',
                          );
                          return const ListTile(
                            leading: CircleAvatar(child: Icon(Icons.error)),
                            title: Text('Error loading user'),
                          );
                        }

                        if (!userSnapshot.hasData ||
                            !userSnapshot.data!.exists) {
                          print(
                            '❌ [ChatListScreen] User not found in Firestore: $otherUserId',
                          );
                          return const ListTile(
                            leading: CircleAvatar(child: Icon(Icons.error)),
                            title: Text('User not found'),
                          );
                        }

                        final userDoc = userSnapshot.data;
                        final userData = userDoc?.data() ?? <String, dynamic>{};
                        print(
                          '📄 [ChatListScreen] Firestore user data for $otherUserId: $userData',
                        );

                        final Map<String, dynamic> modelMap = {
                          ...userData,
                          'id': otherUserId,
                          'email':
                              userData['email'] ?? '${otherUserId}@example.com',
                          'createdAt':
                              userData['createdAt'] ??
                              Timestamp.fromDate(DateTime.now()),
                          'updatedAt':
                              userData['updatedAt'] ??
                              Timestamp.fromDate(DateTime.now()),
                          'role': userData['role'] ?? 'teacher',
                        };

                        late UserModel otherUser;
                        try {
                          otherUser = UserModel.fromJson(modelMap);
                          print(
                            '✅ [ChatListScreen] Built UserModel for ${otherUser.name}',
                          );
                        } catch (e) {
                          print(
                            '❌ [ChatListScreen] Error parsing UserModel for $otherUserId: $e',
                          );
                          return const ListTile(
                            leading: CircleAvatar(child: Icon(Icons.error)),
                            title: Text('Invalid user data'),
                          );
                        }

                        // Apply search filter
                        if (_searchQuery.isNotEmpty &&
                            !otherUser.name.toLowerCase().contains(
                              _searchQuery,
                            )) {
                          return const SizedBox.shrink();
                        }

                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundImage:
                                      otherUser.profileImageUrl != null
                                      ? NetworkImage(otherUser.profileImageUrl!)
                                      : null,
                                  backgroundColor: Colors.grey[300],
                                  child: otherUser.profileImageUrl == null
                                      ? const Icon(Icons.person, size: 28)
                                      : null,
                                ),
                                // Online indicator (you can implement this based on your needs)
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            title: Text(
                              otherUser.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                data['lastMessage'] as String? ??
                                    'No messages yet',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (data['lastMessageTime'] != null)
                                  Text(
                                    _formatTimestamp(
                                      data['lastMessageTime'] as Timestamp?,
                                    ),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                const SizedBox(height: 4),
                                // Unread count indicator
                                FutureBuilder<int>(
                                  future: _chatService.getUnreadCount(
                                    chatId,
                                    user.uid,
                                  ),
                                  builder: (context, unreadSnapshot) {
                                    final unreadCount =
                                        unreadSnapshot.data ?? 0;
                                    if (unreadCount > 0) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          unreadCount > 99
                                              ? '99+'
                                              : unreadCount.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ],
                            ),
                            onTap: () {
                              print(
                                '➡️ [ChatListScreen] Opening chat with ${otherUser.name} (Chat ID: $chatId)',
                              );
                              context.go(
                                '/chatScreen',
                                extra: {
                                  'chatId': chat.id,
                                  'tutor': otherUser,
                                  'currentUserId': user.uid,
                                },
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
