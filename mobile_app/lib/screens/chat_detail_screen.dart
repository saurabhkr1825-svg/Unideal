import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_chat_service.dart';
import '../providers/auth_provider.dart';
import '../models/chat_model.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'membership_screen.dart';
import '../widgets/custom_card.dart';

class ChatDetailScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserEmail;
  final String? donationId;
  final String? donationTitle;
  final String? donationImageUrl;

  const ChatDetailScreen({
    Key? key,
    required this.otherUserId,
    required this.otherUserEmail,
    this.donationId,
    this.donationTitle,
    this.donationImageUrl,
  }) : super(key: key);

  @override
  _ChatDetailScreenState createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final SupabaseChatService _chatService = SupabaseChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  
  String? _chatId;
  String _otherUserStatus = 'offline';
  DateTime? _otherUserLastSeen;
  bool _isOtherTyping = false;
  RealtimeChannel? _typingChannel;
  static const int _messageLimit = 10;

  @override
  void initState() {
    super.initState();
    _initChat();
    _chatService.updatePresence();
    _subscribeToUserStatus();
  }

  @override
  void dispose() {
    _chatService.stopPresence();
    _typingChannel?.unsubscribe();
    super.dispose();
  }

  void _subscribeToUserStatus() {
    Supabase.instance.client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', widget.otherUserId)
        .listen((data) {
          if (data.isNotEmpty && mounted) {
            setState(() {
              _otherUserStatus = data.first['online_status'] ?? 'offline';
              _otherUserLastSeen = data.first['last_seen'] != null 
                  ? DateTime.parse(data.first['last_seen']) 
                  : null;
            });
          }
        });
  }

  Future<void> _initChat() async {
    try {
      final id = await _chatService.getOrCreateChat(widget.otherUserId, donationId: widget.donationId);
      if (mounted) {
        setState(() {
          _chatId = id;
        });
        _setupTypingIndicator(id);
        _chatService.markAsRead(id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chat is unavailable: $e')));
        Navigator.pop(context);
      }
    }
  }

  void _setupTypingIndicator(String chatId) {
    _typingChannel = _chatService.subscribeToTyping(chatId, (userId, isTyping) {
      if (userId == widget.otherUserId && mounted) {
        setState(() {
          _isOtherTyping = isTyping;
        });
      }
    });
  }

  void _onTypingChanged(String text) {
    if (_chatId != null) {
      _chatService.sendTypingIndicator(_chatId!, text.isNotEmpty);
    }
  }

  Future<void> _pickImage(int sentCount, bool isMember) async {
    if (!isMember && sentCount >= _messageLimit) {
      _showLimitReachedDialog();
      return;
    }

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null || _chatId == null) return;

    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Uploading image...')));
      
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = 'chat_images/$_chatId/$fileName';
      
      final bytes = await image.readAsBytes();
      await Supabase.instance.client.storage.from('item-images').uploadBinary(path, bytes);
      
      final imageUrl = Supabase.instance.client.storage.from('item-images').getPublicUrl(path);
      
      await _chatService.sendMessage(_chatId!, '[Image]', type: 'image', imageUrl: imageUrl);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload: $e')));
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
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white24,
              child: Text(widget.otherUserEmail[0].toUpperCase(), style: TextStyle(color: Colors.white)),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.otherUserEmail, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  _otherUserStatus == 'online'
                    ? Text('🟢 Online', style: TextStyle(fontSize: 11, color: Colors.greenAccent))
                    : Text(
                        _otherUserLastSeen != null 
                          ? 'Last seen ${DateFormat('h:mm a').format(_otherUserLastSeen!)}'
                          : 'Offline',
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                      ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'report') {
                _showReportDialog();
              } else if (value == 'block') {
                _showBlockDialog();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'report', child: Text('Report User')),
              PopupMenuItem(value: 'block', child: Text('Block User')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildProductContext(),
          Container(
            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            width: double.infinity,
            color: Colors.indigo[50],
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              children: [
                Text('Your ID: ${myId ?? "N/A"}', style: TextStyle(fontSize: 10, color: Colors.indigo[900])),
                Text('Other ID: ${widget.otherUserId}', style: TextStyle(fontSize: 10, color: Colors.indigo[900])),
              ],
            ),
          ),
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
                    
                    // Schedule scroll to bottom after build
                    if (messages.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: messages.isEmpty
                            ? Center(child: Text('No messages yet. Say Hi!'))
                            : ListView.builder(
                                controller: _scrollController,
                                padding: EdgeInsets.all(16),
                                itemCount: messages.length,
                                itemBuilder: (ctx, i) {
                                  final msg = messages[i];
                                  return _buildMessageBubble(msg, myId);
                                },
                              ),
                        ),
                        if (_isOtherTyping)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'typing...',
                                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.indigo),
                              ),
                            ),
                          ),
                        _buildQuickReplies(sentCount, isMember),
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

  Widget _buildProductContext() {
    if (widget.donationTitle == null) return SizedBox.shrink();
    return Container(
      padding: EdgeInsets.all(8),
      color: Colors.grey[100],
      child: Row(
        children: [
          if (widget.donationImageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(widget.donationImageUrl!, width: 40, height: 40, fit: BoxFit.cover),
            ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.donationTitle!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('Interested in this item', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              // Navigate back to product detail or show dialog
            },
            child: Text('View Item', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReplies(int sentCount, bool isMember) {
    if (!isMember && sentCount >= _messageLimit) return SizedBox.shrink();
    final replies = ['Is this available?', 'Final price?', 'Where can we meet?'];
    return Container(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12),
        itemCount: replies.length,
        itemBuilder: (context, i) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(replies[i], style: TextStyle(fontSize: 12)),
              onPressed: () {
                _messageController.text = replies[i];
                _sendMessage(sentCount, isMember);
              },
            ),
          );
        },
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
            child: msg.messageType == 'image' && msg.imageUrl != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(msg.imageUrl!, width: 200, fit: BoxFit.contain),
                    ),
                    if (msg.message != '[Image]')
                      Text(
                        msg.message,
                        style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 16),
                      ),
                  ],
                )
              : Text(
                  msg.message,
                  style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 16),
                ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
                if (isMe) ...[
                  SizedBox(width: 4),
                  Icon(
                    msg.status == 'read' ? Icons.done_all : Icons.done,
                    size: 12,
                    color: msg.status == 'read' ? Colors.blue : Colors.grey[500],
                  ),
                ],
              ],
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
                    onChanged: _onTypingChanged,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      prefixIcon: IconButton(
                        icon: Icon(Icons.attach_file, color: Colors.indigo),
                        onPressed: () => _pickImage(sentCount, isMember),
                      ),
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

  void _showReportDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report User'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Reason for reporting...'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final user = Supabase.instance.client.auth.currentUser;
              if (user != null && controller.text.isNotEmpty) {
                await Supabase.instance.client.from('user_reports').insert({
                  'reporter_id': user.id,
                  'reported_id': widget.otherUserId,
                  'reason': controller.text,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Report submitted.')));
              }
            },
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block User?'),
        content: Text('You will no longer receive messages from this user.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final user = Supabase.instance.client.auth.currentUser;
              if (user != null) {
                await Supabase.instance.client.from('blocked_users').insert({
                  'blocker_id': user.id,
                  'blocked_id': widget.otherUserId,
                });
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User blocked.')));
              }
            },
            child: Text('Block', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
