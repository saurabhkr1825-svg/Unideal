import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/supabase_chat_service.dart';
import '../models/chat_model.dart';
import 'chat_detail_screen.dart';
import 'search_user_screen.dart';

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
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF), // Extremely light blue backdrop
      body: Stack(
        children: [
          // Background Gradient Array Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF8faaff), // Vibrant blue top
                    Color(0xFFC7D6FF), // Lighter blue middle
                    Color(0xFFF4F7FF), // Fade to scaffold bg
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Minimal Header Name
                const Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 20),
                  child: Center(
                    child: Text(
                      'Chat',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                
                // White Top-Rounding Container
                Expanded(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias, // Ensures internal list stays in rounded corners
                    child: _chatRooms.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadChatRooms,
                            child: ListView.separated(
                              padding: const EdgeInsets.only(top: 24, bottom: 100), // padding for FAB
                              itemCount: _chatRooms.length,
                              separatorBuilder: (context, index) => const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 24),
                                child: Divider(height: 1, color: Color(0xFFF0F0F0)),
                              ),
                              itemBuilder: (ctx, i) {
                                return _buildChatTile(_chatRooms[i]);
                              },
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
     return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.indigo.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              'No conversations yet',
              style: TextStyle(color: Colors.grey[800], fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Start chatting from product details!',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
  }

  Widget _buildChatTile(ChatRoom room) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: Hero(
        tag: 'chat-avatar-${room.id}',
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.indigo[50],
                image: room.donationImageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(room.donationImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: room.donationImageUrl == null
                  ? const Icon(Icons.person, color: Colors.indigo, size: 26)
                  : null,
            ),
            if (room.otherUserStatus == 'online')
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: const Color(0xFF4ade80),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
          ],
        ),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              room.otherUserName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.verified, color: Color(0xFF4F85F6), size: 14),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 3),
          Text(
            room.donationTitle ?? 'Item Discussion',
            style: const TextStyle(color: Color(0xFF4F85F6), fontSize: 12, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          if (room.lastMessage != null)
            Text(
              room.lastMessage!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            room.lastMessageAt != null ? DateFormat('h:mm a').format(room.lastMessageAt!) : '',
            style: TextStyle(color: Colors.grey[500], fontSize: 11, fontWeight: FontWeight.w600)
          ),
          if (room.unreadCount > 0) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: const BoxDecoration(
                color: Color(0xFF4F85F6),
                shape: BoxShape.circle,
              ),
              child: Text('${room.unreadCount}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ]
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
  }
}
