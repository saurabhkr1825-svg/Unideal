import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_chat_service.dart';
import '../providers/auth_provider.dart';
import '../models/chat_model.dart';
import 'package:intl/intl.dart';
import 'membership_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserEmail;
  final String donationId;
  final String? donationTitle;

  const ChatDetailScreen({
    Key? key,
    required this.otherUserId,
    required this.otherUserEmail,
    required this.donationId,
    this.donationTitle,
  }) : super(key: key);

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final SupabaseChatService _chatService = SupabaseChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _chatId;
  static const int _messageLimit = 10;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    try {
      final id = await _chatService.getOrCreateChat(widget.otherUserId, widget.donationId);
      if (mounted) {
        setState(() {
          _chatId = id;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chat is unavailable: $e')));
        Navigator.pop(context);
      }
    }
  }

  void _sendMessage(int sentCount, bool isMember) async {
    if (_chatId == null) return;
    if (!isMember && sentCount >= _messageLimit) {
      _showLimitReachedDialog();
      return;
    }

    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    try {
      await _chatService.sendMessage(_chatId!, content);
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final myId = user?.id;
    final isMember = user?.membershipStatus ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.otherUserEmail, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            if (widget.donationTitle != null)
              Text(
                'Regarding: ${widget.donationTitle}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal, color: Colors.white70),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _chatId == null 
              ? Center(child: CircularProgressIndicator())
              : StreamBuilder<List<ChatMessage>>(
                  stream: _chatService.getMessagesStream(_chatId!),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    final messages = snapshot.data!;
                    final sentCount = messages.where((m) => m.senderId == myId).length;
                    
                    if (messages.isEmpty) {
                      return Center(child: Text('No messages yet. Say Hi!'));
                    }

                    // Schedule scroll to bottom after build
                    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.all(16),
                            itemCount: messages.length,
                            itemBuilder: (ctx, i) {
                              final msg = messages[i];
                              return _buildMessageBubble(msg, myId);
                            },
                          ),
                        ),
                        if (!isMember) _buildLimitIndicator(sentCount),
                        _buildMessageInput(sentCount, isMember),
                      ],
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitIndicator(int sentCount) {
    final remaining = _messageLimit - sentCount;
    final isLocked = remaining <= 0;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      color: isLocked ? Colors.red[50] : Colors.amber[50],
      width: double.infinity,
      child: Text(
        isLocked 
            ? 'Message limit reached for this item.' 
            : 'Remaining free messages for this item: $remaining',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12, 
          fontWeight: FontWeight.bold,
          color: isLocked ? Colors.red[900] : Colors.amber[900],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, String? myId) {
    final isMe = msg.senderId == myId;
    final time = DateFormat('h:mm a').format(msg.sentAt);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(
              top: 8,
              bottom: 2,
              left: isMe ? 50 : 0,
              right: isMe ? 0 : 50,
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMe ? Colors.indigo : Colors.grey[200],
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: isMe ? Radius.circular(16) : Radius.circular(0),
                bottomRight: isMe ? Radius.circular(0) : Radius.circular(16),
              ),
            ),
            child: Text(
              msg.message,
              style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              time,
              style: TextStyle(fontSize: 10, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(int sentCount, bool isMember) {
    final isLocked = !isMember && sentCount >= _messageLimit;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, -2))
        ]
      ),
      child: SafeArea(
        child: isLocked 
          ? SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => MembershipScreen()));
                },
                icon: Icon(Icons.star, size: 18),
                label: Text('Unlock Unlimited Chats (₹99/mo)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      fillColor: Colors.grey[100],
                      filled: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(sentCount, isMember),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(color: Colors.indigo, shape: BoxShape.circle),
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: () => _sendMessage(sentCount, isMember),
                  ),
                ),
              ],
            ),
      ),
    );
  }

  void _showLimitReachedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Limit Reached'),
        content: Text('You have reached the free message limit for this chat. Upgrade to Premium for unlimited communication!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Maybe Later')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => MembershipScreen()));
            }, 
            child: Text('Upgrade Now')
          ),
        ],
      ),
    );
  }
}
