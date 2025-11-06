import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create or get an existing chat between student & tutor
  Future<String> getOrCreateChat(String studentId, String tutorId) async {
    print(
      '🔍 [ChatService] Checking for existing chat between $studentId and $tutorId',
    );

    try {
      final chatQuery = await _firestore
          .collection('chats')
          .where('participants', arrayContains: studentId)
          .get();

      print(
        '📦 [ChatService] Found ${chatQuery.docs.length} chats for $studentId',
      );

      for (var doc in chatQuery.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);
        print('➡️ Checking chat ${doc.id} with participants: $participants');

        if (participants.contains(tutorId)) {
          print('✅ [ChatService] Existing chat found: ${doc.id}');
          return doc.id;
        }
      }

      print('🆕 [ChatService] Creating new chat document...');
      final newChatRef = await _firestore.collection('chats').add({
        'participants': [studentId, tutorId],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      print('✅ [ChatService] New chat created: ${newChatRef.id}');
      return newChatRef.id;
    } catch (e) {
      print('❌ [ChatService] Error creating chat: $e');
      rethrow;
    }
  }

  /// Send a message and update chat metadata
  Future<void> sendMessage(
    String chatId,
    String senderId,
    String message,
  ) async {
    print(
      '💬 [ChatService] Sending message to chatId=$chatId by senderId=$senderId',
    );
    print('Message content: "$message"');

    try {
      final timestamp = FieldValue.serverTimestamp();

      final messageRef = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
            'senderId': senderId,
            'message': message,
            'timestamp': timestamp,
            'read': false,
          });

      print('✅ [ChatService] Message sent: ${messageRef.id}');

      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': message,
        'lastMessageTime': timestamp,
      });

      print('🕒 [ChatService] Updated chat metadata for chatId=$chatId');
    } catch (e) {
      print('❌ [ChatService] Error sending message: $e');
      rethrow;
    }
  }

  /// Stream messages in real-time (typed)
  Stream<QuerySnapshot<Map<String, dynamic>>> getMessages(String chatId) {
    print('📡 [ChatService] Subscribing to messages for chatId=$chatId');

    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Stream all chats where current user is a participant (typed)
  Stream<QuerySnapshot<Map<String, dynamic>>> getUserChats(String userId) {
    print('📡 [ChatService] Fetching chat list for userId=$userId');

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  /// Get unread message count for a specific chat
  Future<int> getUnreadCount(String chatId, String userId) async {
    try {
      // Simplified query to avoid composite index requirement
      final messagesQuery = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('read', isEqualTo: false)
          .get();

      // Filter by senderId in code instead of query
      final unreadMessages = messagesQuery.docs.where((doc) {
        final data = doc.data();
        return data['senderId'] != userId;
      }).length;

      return unreadMessages;
    } catch (e) {
      print('❌ [ChatService] Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    try {
      final batch = _firestore.batch();

      // Simplified query to avoid composite index requirement
      final messagesQuery = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('read', isEqualTo: false)
          .get();

      // Filter by senderId in code and update
      for (var doc in messagesQuery.docs) {
        final data = doc.data();
        if (data['senderId'] != userId) {
          batch.update(doc.reference, {'read': true});
        }
      }

      await batch.commit();
      print('✅ [ChatService] Marked messages as read for chatId=$chatId');
    } catch (e) {
      print('❌ [ChatService] Error marking messages as read: $e');
    }
  }
}
