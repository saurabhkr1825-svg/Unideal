import 'package:flutter/material.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Messages', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black)),
              InkWell(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SearchUserScreen()),
                  );
                  _loadChatRooms();
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_search, color: Colors.black),
                ),
              ),
            ],
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(25),
            ),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search messages...',
                hintStyle: TextStyle(color: Colors.grey),
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (val) {
                // Implement local search on chats if desired
              },
            ),
          ),
        ),

        // Filter Pills
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              _buildFilterPill('All', true),
              const SizedBox(width: 10),
              _buildFilterPill('Buying', false),
              const SizedBox(width: 10),
              _buildFilterPill('Selling', false),
            ],
          ),
        ),

        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _chatRooms.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'No conversations yet',
                            style: TextStyle(color: Colors.grey[500], fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadChatRooms,
                      child: ListView.separated(
                        padding: const EdgeInsets.only(top: 10),
                        itemCount: _chatRooms.length,
                        separatorBuilder: (context, index) => Divider(height: 1, indent: 90, color: Colors.grey[200]),
                        itemBuilder: (ctx, i) {
                          final room = _chatRooms[i];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            leading: Hero(
                              tag: 'chat-avatar-${room.id}',
                              child: Stack(
                                children: [
                                  Container(
                                    width: 55,
                                    height: 55,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(18),
                                      image: room.donationImageUrl != null
                                          ? DecorationImage(
                                              image: NetworkImage(room.donationImageUrl!),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                      color: Colors.blue[50],
                                    ),
                                    child: room.donationImageUrl == null
                                        ? Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Icon(Icons.inventory_2_outlined, color: Colors.blueAccent[700]),
                                          )
                                        : null,
                                  ),
                                  if (room.otherUserStatus == 'online')
                                    Positioned(
                                      right: -2,
                                      bottom: -2,
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 3),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    room.donationTitle ?? 'Item Chat',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  '12:30 PM', // Placeholder for actual timestamp
                                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(
                                '${room.otherUserName}: ${room.lastMessage ?? "Active"}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.grey[600], fontSize: 14),
                              ),
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
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterPill(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.black87 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isSelected ? null : Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[600],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
        ),
      ),
    );
  }
}
