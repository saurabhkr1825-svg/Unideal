import 'package:flutter/material.dart';
import '../services/supabase_chat_service.dart';
import '../models/chat_model.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final SupabaseChatService _chatService = SupabaseChatService();
  List<ChatRoom> _chatRooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
  }

  Future<void> _loadChatRooms() async {
    try {
      final rooms = await _chatService.getChatRooms();
      if (mounted) {
        setState(() {
          _chatRooms = rooms;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading chats: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_chatRooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
            SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: TextStyle(color: Colors.grey[600], fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Start chatting from product details!',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadChatRooms,
      child: ListView.separated(
        itemCount: _chatRooms.length,
        separatorBuilder: (context, index) => Divider(height: 1, indent: 80),
        itemBuilder: (ctx, i) {
          final room = _chatRooms[i];
          return ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Hero(
              tag: 'chat-avatar-${room.id}',
              child: Stack(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: room.donationImageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(room.donationImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: Colors.indigo[50],
                    ),
                    child: room.donationImageUrl == null
                        ? Icon(Icons.volunteer_activism, color: Colors.indigo)
                        : null,
                  ),
                  if (room.otherUserStatus == 'online')
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            title: Text(
              room.donationTitle ?? 'Item Chat',
              style: TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'With: ${room.otherUserName}',
                  style: TextStyle(color: Colors.indigo, fontSize: 13),
                ),
                Text(
                  'ID: ${room.otherUserId}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 10),
                ),
                if (room.lastMessage != null)
                  Text(
                    room.lastMessage!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
              ],
            ),
            onTap: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatDetailScreen(
                    otherUserId: room.otherUserId,
                    otherUserEmail: room.otherUserName,
                    donationId: room.donationId,
                    donationTitle: room.donationTitle,
                    donationImageUrl: room.donationImageUrl,
                  ),
                ),
              );
              _loadChatRooms(); // Refresh when coming back
            },
          );
        },
      ),
    );
  }
}
