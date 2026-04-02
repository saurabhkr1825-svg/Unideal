import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_model.dart';
import 'supabase_notification_service.dart';

class SupabaseChatService {
  final SupabaseClient _client = Supabase.instance.client;
  RealtimeChannel? _presenceChannel;

  // Manage Presence (Online/Offline)
  void updatePresence() {
    final user = _client.auth.currentUser;
    if (user == null) return;

    _presenceChannel = _client.channel('presence:online_users');

    _presenceChannel!.onPresenceSync((payload) {
      // Local sync if needed
    }).onPresenceJoin((payload) {
      // User joined
    }).onPresenceLeave((payload) async {
      // User left - we can update the profiles table here or via a Hook
    }).subscribe((status, [error]) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await _presenceChannel!.track({
          'user_id': user.id,
          'online_at': DateTime.now().toIso8601String(),
        });
        
        // Update profiles table for persistence
        await _client.from('profiles').update({
          'online_status': 'online',
          'last_seen': DateTime.now().toIso8601String(),
        }).eq('id', user.id);
      }
    });
  }

  void stopPresence() async {
    final user = _client.auth.currentUser;
    if (user != null) {
      await _client.from('profiles').update({
        'online_status': 'offline',
        'last_seen': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
    }
    await _presenceChannel?.unsubscribe();
  }

  // Typing Indicators
  RealtimeChannel subscribeToTyping(String chatId, Function(String userId, bool isTyping) onTyping) {
    final channel = _client.channel('chat:$chatId');
    
    channel.onBroadcast(event: 'typing', callback: (payload) {
      onTyping(payload['user_id'], payload['is_typing']);
    }).subscribe();

    return channel;
  }

  void sendTypingIndicator(String chatId, bool isTyping) {
    final user = _client.auth.currentUser;
    if (user == null) return;

    _client.channel('chat:$chatId').sendBroadcastMessage(
      event: 'typing',
      payload: {'user_id': user.id, 'is_typing': isTyping},
    );
  }

  // Find or create a chat between two users for a specific donation or general chat
  Future<String> getOrCreateChat(String otherUserId, {String? donationId}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');
    if (user.id == otherUserId) throw Exception('Cannot chat with yourself');

    // Try to find existing chat
    var query = _client.from('chats').select('id');
    if (donationId != null) {
      query = query.eq('donation_id', donationId);
    } else {
      query = query.isFilter('donation_id', null);
    }

    final existingChat = await query
        .or('and(sender_id.eq.${user.id},receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.${user.id})')
        .maybeSingle();

    if (existingChat != null) {
      return existingChat['id'] as String;
    }

    // Create new chat
    final newChat = await _client.from('chats').insert({
      if (donationId != null) 'donation_id': donationId,
      'sender_id': user.id,
      'receiver_id': otherUserId,
    }).select('id').single();

    return newChat['id'] as String;
  }

  // Search for users to start a chat with
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final user = _client.auth.currentUser;
    if (user == null || query.trim().isEmpty) return [];

    final response = await _client
        .from('profiles')
        .select('id, full_name, email, online_status, last_seen')
        .ilike('full_name', '%${query.trim()}%')
        .neq('id', user.id)
        .limit(20);

    return List<Map<String, dynamic>>.from(response);
  }

  // Send a message
  Future<void> sendMessage(String chatId, String content, {String type = 'text', String? imageUrl}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    await _client.from('messages').insert({
      'chat_id': chatId,
      'sender_id': user.id,
      'message': content,
      'message_type': type,
      'image_url': imageUrl,
      'status': 'sent',
    });

    await _client.from('chats').update({
      'last_message': type == 'image' ? '[Image]' : content,
      'last_message_at': DateTime.now().toIso8601String(),
    }).eq('id', chatId);

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

  // Mark messages as read
  Future<void> markAsRead(String chatId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client
        .from('messages')
        .update({'status': 'read', 'read_at': DateTime.now().toIso8601String()})
        .eq('chat_id', chatId)
        .neq('sender_id', user.id)
        .neq('status', 'read');
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
          last_message,
          last_message_at,
          donations:donation_id(title, image_url),
          profiles_sender:sender_id(full_name, online_status, last_seen),
          profiles_receiver:receiver_id(full_name, online_status, last_seen)
        ''')
        .or('sender_id.eq.${user.id},receiver_id.eq.${user.id}')
        .order('created_at', ascending: false);

    final rooms = (response as List).map((map) => ChatRoom.fromMap(map, user.id)).toList();
    for (var room in rooms) {
      try {
        final unreadRes = await _client.from('messages')
            .select('id')
            .eq('chat_id', room.id)
            .neq('sender_id', user.id)
            .neq('status', 'read');
        room.unreadCount = unreadRes.length;
      } catch (e) {
        print('Error getting unread count: $e');
        room.unreadCount = 0;
      }
    }
    return rooms;
  }
}
