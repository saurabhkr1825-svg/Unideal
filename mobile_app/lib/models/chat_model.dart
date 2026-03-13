import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRoom {
  final String id;
  final String donationId;
  final String? donationTitle;
  final String? donationImageUrl;
  final String otherUserId;
  final String otherUserName;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String otherUserStatus;
  final DateTime? otherUserLastSeen;

  ChatRoom({
    required this.id,
    required this.donationId,
    this.donationTitle,
    this.donationImageUrl,
    required this.otherUserId,
    required this.otherUserName,
    this.lastMessage,
    this.lastMessageAt,
    this.otherUserStatus = 'offline',
    this.otherUserLastSeen,
  });

  factory ChatRoom.fromMap(Map<String, dynamic> map, String currentUserId) {
    final sender = map['sender_id'] as String;
    final receiver = map['receiver_id'] as String;
    
    // The "other" user is the one who is NOT the current user
    final otherUserId = sender == currentUserId ? receiver : sender;
    
    // Handle nested profiles and donations if they exist in the join
    final otherUserProfile = map['profiles_receiver'] ?? map['profiles_sender'] ?? {};
    final otherUserName = otherUserProfile['full_name'] ?? 'User';
    
    final donation = map['donations'] ?? {};
    
    return ChatRoom(
      id: map['id'],
      donationId: map['donation_id'],
      donationTitle: donation['title'],
      donationImageUrl: donation['image_url'],
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      lastMessage: map['last_message'],
      lastMessageAt: map['last_message_at'] != null ? DateTime.parse(map['last_message_at']) : null,
      otherUserStatus: otherUserProfile['online_status'] ?? 'offline',
      otherUserLastSeen: otherUserProfile['last_seen'] != null ? DateTime.parse(otherUserProfile['last_seen']) : null,
    );
  }
}

class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String message;
  final DateTime sentAt;
  final String status; // sent, delivered, read
  final String messageType; // text, image
  final String? imageUrl;

  ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.message,
    required this.sentAt,
    this.status = 'sent',
    this.messageType = 'text',
    this.imageUrl,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      chatId: map['chat_id'],
      senderId: map['sender_id'],
      message: map['message'] ?? '',
      sentAt: DateTime.parse(map['sent_at']),
      status: map['status'] ?? 'sent',
      messageType: map['message_type'] ?? 'text',
      imageUrl: map['image_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'chat_id': chatId,
      'sender_id': senderId,
      'message': message,
      'status': status,
      'message_type': messageType,
      'image_url': imageUrl,
    };
  }
}
