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
      backgroundColor: const Color(0xFFF4F7FF), // Extremely light blue backdrop
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Row(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.indigo[50], // Very light blue
                  child: Text(widget.otherUserEmail[0].toUpperCase(), style: const TextStyle(color: Color(0xFF4F85F6), fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                if (_otherUserStatus == 'online')
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ade80),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                         child: Text(widget.otherUserEmail, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, color: Color(0xFF4F85F6), size: 14),
                    ],
                  ),
                  _otherUserStatus == 'online'
                    ? const Text('Online', style: TextStyle(fontSize: 11, color: Color(0xFF4F85F6), fontWeight: FontWeight.w600))
                    : Text(
                        _otherUserLastSeen != null 
                          ? 'Last seen ${DateFormat('h:mm a').format(_otherUserLastSeen!)}'
                          : 'Offline',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onSelected: (value) async {
              if (value == 'report') {
                _showReportDialog();
              } else if (value == 'block') {
                _showBlockDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'report', child: Text('Report User')),
              const PopupMenuItem(value: 'block', child: Text('Block User')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildProductContext(),
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
    if (widget.donationTitle == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (widget.donationImageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(widget.donationImageUrl!, width: 48, height: 48, fit: BoxFit.cover),
            ),
          if (widget.donationImageUrl == null)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: Colors.indigo[50], borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.inventory_2, color: Color(0xFF4F85F6), size: 24),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.donationTitle!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text('Listed Item', style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500)),
              ],
            ),
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
              top: 6,
              bottom: 2,
              left: isMe ? 60 : 0,
              right: isMe ? 0 : 60,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: isMe ? const LinearGradient(
                colors: [Color(0xFF759DFF), Color(0xFF4F85F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ) : null,
              color: isMe ? null : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
              ),
              boxShadow: !isMe ? [
                 BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))
              ] : [],
            ),
            child: msg.messageType == 'image' && msg.imageUrl != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(msg.imageUrl!, width: 220, fit: BoxFit.contain),
                    ),
                    if (msg.message != '[Image]') ...[
                      const SizedBox(height: 8),
                      Text(
                        msg.message,
                        style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 14),
                      ),
                    ]
                  ],
                )
              : Text(
                  msg.message,
                  style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 14),
                ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(fontSize: 10, color: Colors.grey[500], fontWeight: FontWeight.w600),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    msg.status == 'read' ? Icons.done_all : Icons.check, // Double checkmark logic
                    size: 14,
                    color: msg.status == 'read' ? const Color(0xFF4ade80) : Colors.grey[400],
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF4F7FF), // Matches scaffold background
      ),
      child: SafeArea(
        child: isLocked 
          ? SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => MembershipScreen()));
                },
                icon: const Icon(Icons.star, size: 18),
                label: const Text('Unlock Unlimited Chats (₹99/mo)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F85F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 6,
                ),
              ),
            )
          : Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                         BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
                      ]
                    ),
                    child: TextField(
                      controller: _messageController,
                      onChanged: _onTypingChanged,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Message',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: IconButton(
                          icon: Icon(Icons.attach_file, color: Colors.grey[500], size: 22),
                          onPressed: () => _pickImage(sentCount, isMember),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.camera_alt_outlined, color: Colors.grey[500], size: 22),
                          onPressed: () => _pickImage(sentCount, isMember),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        fillColor: Colors.transparent,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      onSubmitted: (_) => _sendMessage(sentCount, isMember),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _messageController,
                  builder: (context, value, child) {
                    final hasText = value.text.trim().isNotEmpty;
                    return Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F85F6), 
                        shape: BoxShape.circle,
                        boxShadow: [
                           BoxShadow(color: const Color(0xFF4F85F6).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                        ]
                      ),
                      child: IconButton(
                        icon: Icon(hasText ? Icons.send : Icons.mic, color: Colors.white, size: 22),
                        onPressed: () {
                          if (hasText) {
                             _sendMessage(sentCount, isMember);
                          }
                        },
                      ),
                    );
                  },
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
