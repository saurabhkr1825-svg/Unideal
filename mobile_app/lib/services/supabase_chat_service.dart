import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_model.dart';
import 'supabase_notification_service.dart';

class SupabaseChatService {
  final SupabaseClient _client = Supabase.instance.client;

  // Find or create a chat between two users for a specific donation
  Future<String> getOrCreateChat(String otherUserId, String donationId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    if (user.id == otherUserId) throw Exception('Cannot chat with yourself');

    // Try to find existing chat
    final existingChat = await _client
        .from('chats')
        .select('id')
        .eq('donation_id', donationId)
        .or('and(sender_id.eq.${user.id},receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.${user.id})')
        .maybeSingle();

    if (existingChat != null) {
      return existingChat['id'] as String;
    }

    // Create new chat
    final newChat = await _client.from('chats').insert({
      'donation_id': donationId,
      'sender_id': user.id,
      'receiver_id': otherUserId,
    }).select('id').single();

    return newChat['id'] as String;
  }

  // Send a message
  Future<void> sendMessage(String chatId, String content) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _client.from('messages').insert({
      'chat_id': chatId,
      'sender_id': user.id,
      'message': content,
    });

    // 2. Create Notification for the receiver
    try {
      final chatData = await _client.from('chats').select('sender_id, receiver_id').eq('id', chatId).single();
      final receiverId = chatData['sender_id'] == user.id ? chatData['receiver_id'] : chatData['sender_id'];
      
      final senderData = await _client.from('profiles').select('full_name').eq('id', user.id).single();
      final senderName = senderData['full_name'] ?? 'Someone';

      await SupabaseNotificationService().createNotification(
        userId: receiverId,
        title: 'New Message',
        message: '$senderName: "$content"',
        type: 'chat',
        relatedId: chatId,
      );
    } catch (e) {
      print('Failed to send notification: $e');
    }
  }

  // Get messages for a specific chat (realtime stream)
  Stream<List<ChatMessage>> getMessagesStream(String chatId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('sent_at', ascending: true)
        .map((list) => list.map((map) => ChatMessage.fromMap(map)).toList());
  }

  // Get chat rooms for the current user
  Future<List<ChatRoom>> getChatRooms() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    // Fetch chats with donation and participant info
    // We join with profiles twice (sender and receiver) to ensure we get the other person's name
    final response = await _client
        .from('chats')
        .select('''
          id,
          donation_id,
          sender_id,
          receiver_id,
          created_at,
          donations:donation_id(title, image_url),
          profiles_sender:sender_id(full_name),
          profiles_receiver:receiver_id(full_name)
        ''')
        .or('sender_id.eq.${user.id},receiver_id.eq.${user.id}')
        .order('created_at', ascending: false);

    return (response as List).map((map) => ChatRoom.fromMap(map, user.id)).toList();
  }
}
