import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/supabase_notification_service.dart';
import 'membership_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final SupabaseNotificationService _notificationService = SupabaseNotificationService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () async {
              await _notificationService.markAllAsRead();
              setState(() {});
            },
            child: const Text('Mark all as read', style: TextStyle(color: Colors.indigo)),
          ),
        ],
      ),
      body: StreamBuilder<List<NotificationModel>>(
        stream: _notificationService.getNotificationStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final notifications = snapshot.data ?? [];
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('No notifications yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (ctx, i) {
              final n = notifications[i];
              return _buildNotificationTile(n);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationTile(NotificationModel n) {
    return InkWell(
      onTap: () => _handleNotificationTap(n),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: n.isRead ? Colors.white : Colors.indigo.withOpacity(0.03),
          border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcon(n.type),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(n.title, style: TextStyle(fontWeight: n.isRead ? FontWeight.w500 : FontWeight.bold, fontSize: 15)),
                      Text(n.timeAgo, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n.message,
                    style: TextStyle(color: Colors.grey[700], fontSize: 14, height: 1.3),
                  ),
                ],
              ),
            ),
            if (!n.isRead)
              Container(
                margin: const EdgeInsets.only(left: 8, top: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Colors.indigo, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'chat':
        icon = Icons.chat_bubble_rounded;
        color = Colors.blue;
        break;
      case 'membership':
        icon = Icons.card_membership_rounded;
        color = Colors.amber;
        break;
      case 'bid':
        icon = Icons.gavel_rounded;
        color = Colors.deepOrange;
        break;
      default:
        icon = Icons.notifications_rounded;
        color = Colors.indigo;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color, size: 22),
    );
  }

  void _handleNotificationTap(NotificationModel n) async {
    if (!n.isRead) {
      await _notificationService.markAsRead(n.id);
    }

    switch (n.type) {
      case 'chat':
        if (n.relatedId != null) {
          // Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(chatRoomId: n.relatedId!)));
        }
        break;
      case 'membership':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MembershipScreen()));
        break;
      case 'bid':
        // Navigate to product detail
        break;
    }
  }
}
