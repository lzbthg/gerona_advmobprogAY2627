import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/message.dart';

// Lab Activity 6 (Firebase Part II):
// All Firestore reads/writes for chat live here, kept separate from
// UserService (which owns authentication and the local session cache).
class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Enhancement 1: every registered user, for the Chat List. Filtering out
  // the current user happens in ChatScreen, since that's where we know who
  // is signed in.
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection('Users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // Sends a message and files it under a chat room shared by exactly these
  // two users (their uids sorted, so both people land on the same room id
  // regardless of who started the conversation).
  Future<void> sendMessage(String receiverId, String message) async {
    final currentUser = _firebaseAuth.currentUser;
    if (currentUser == null) {
      throw Exception('You must be signed in with Firebase to send messages.');
    }

    final currentUserId = currentUser.uid;
    final currentUserEmail = currentUser.email ?? '';
    final timestamp = Timestamp.now();

    final newMessage = Message(
      senderId: currentUserId,
      senderEmail: currentUserEmail,
      receiverId: receiverId,
      message: message,
      timestamp: timestamp,
      isSeen: false,
    );

    final ids = [currentUserId, receiverId]..sort();
    final chatRoomId = ids.join('_');

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(newMessage.toMap());
  }

  /// Marks unread messages sent by [otherUserId] as seen by [userId].
  /// Older documents without an `isSeen` field are treated as unread.
  Future<void> markMessagesAsSeen(String userId, String otherUserId) async {
    final ids = [userId, otherUserId]..sort();
    final messages = await _firestore
        .collection('chat_rooms')
        .doc(ids.join('_'))
        .collection('messages')
        .where('receiverId', isEqualTo: userId)
        .where('senderId', isEqualTo: otherUserId)
        .get();

    final unread = messages.docs.where((doc) => doc.data()['isSeen'] != true);
    final batch = _firestore.batch();
    for (final doc in unread) {
      batch.update(doc.reference, {'isSeen': true});
    }
    if (unread.isNotEmpty) await batch.commit();
  }

  // Enhancement 3 (sending states):
  // includeMetadataChanges: true makes this stream also fire when a
  // message's metadata changes from "pending write" to "confirmed", which
  // is what lets the chat detail screen show a live sending -> sent state
  // without any manual timers.
  Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    final ids = [userId, otherUserId]..sort();
    final chatRoomId = ids.join('_');

    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots(includeMetadataChanges: true);
  }

  Future<String?> getUidByEmail(String email) async {
    final q = await _firestore
        .collection('Users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (q.docs.isEmpty) return null;
    return (q.docs.first.data()['uid'] ?? '').toString();
  }
}
