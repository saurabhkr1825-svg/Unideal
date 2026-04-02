import 'package:flutter/material.dart';
import '../services/supabase_chat_service.dart';
import 'chat_detail_screen.dart';

class SearchUserScreen extends StatefulWidget {
  const SearchUserScreen({super.key});

  @override
  _SearchUserScreenState createState() => _SearchUserScreenState();
}

class _SearchUserScreenState extends State<SearchUserScreen> {
  final SupabaseChatService _chatService = SupabaseChatService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  void _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final results = await _chatService.searchUsers(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error searching users: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search users...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white, fontSize: 18),
          textInputAction: TextInputAction.search,
          onSubmitted: _searchUsers,
          onChanged: (val) {
            // Optional: debounce this for real-time search
            // For now, require enter or search button
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _searchUsers(_searchController.text),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _searchResults.isEmpty
              ? Center(
                  child: Text(
                    _searchController.text.isEmpty
                        ? 'Type a name to search'
                        : 'No users found',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.indigo[100],
                        child: Text(
                          (user['full_name'] != null && user['full_name'].toString().isNotEmpty)
                              ? user['full_name'].toString()[0].toUpperCase()
                              : 'U',
                          style: const TextStyle(color: Colors.indigo),
                        ),
                      ),
                      title: Text(user['full_name'] ?? 'Unknown User'),
                      subtitle: Text(
                        user['online_status'] == 'online' ? 'Online' : 'Offline',
                        style: TextStyle(
                            color: user['online_status'] == 'online' ? Colors.green : Colors.grey),
                      ),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatDetailScreen(
                              otherUserId: user['id'],
                              otherUserEmail: user['full_name'] ?? 'User',
                              donationId: null, // General chat
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
