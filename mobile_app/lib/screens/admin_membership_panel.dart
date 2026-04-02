import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/supabase_membership_service.dart';
import '../models/membership_request_model.dart';
import '../providers/auth_provider.dart';

class AdminMembershipPanel extends StatefulWidget {
  const AdminMembershipPanel({super.key});

  @override
  _AdminMembershipPanelState createState() => _AdminMembershipPanelState();
}

class _AdminMembershipPanelState extends State<AdminMembershipPanel> {
  final SupabaseMembershipService _membershipService = SupabaseMembershipService();

  void _updateStatus(String requestId, String status, String userId) async {
    try {
      await _membershipService.updateRequestStatus(requestId, status, userId);
      
      // If the admin is approving themselves (for testing), refresh their local profile
      final currentAuth = Provider.of<AuthProvider>(context, listen: false);
      if (currentAuth.user?.id == userId) {
        await currentAuth.reloadUser();
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Membership $status successfully!')));
      setState(() {}); // Refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin: Membership Requests')),
      body: FutureBuilder<List<MembershipRequest>>(
        future: _membershipService.getAllPendingRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error loading requests:\n${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            ));
          }
          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return const Center(child: Text('No pending membership requests.'));
          }

          return ListView.builder(
            itemCount: requests.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (ctx, i) {
              final req = requests[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(req.planName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                          Text(req.formattedDate, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('User ID: ${req.userId}', style: const TextStyle(fontSize: 12)),
                      Text('Amount: ₹${req.amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Txn ID: ${req.transactionId ?? "N/A"}', style: const TextStyle(fontWeight: FontWeight.w500)),
                      if (req.utrNumber != null && req.utrNumber != req.transactionId)
                        Text('UTR: ${req.utrNumber}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                      const SizedBox(height: 16),
                      
                      // Screenshot Preview
                      if (req.screenshotUrl != null)
                        GestureDetector(
                          onTap: () => _showImageDialog(req.screenshotUrl!),
                          child: Container(
                            height: 120,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(req.screenshotUrl!, fit: BoxFit.cover),
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _updateStatus(req.id, 'rejected', req.userId),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Reject'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _updateStatus(req.id, 'approved', req.userId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Approve'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showImageDialog(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(url),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ],
        ),
      ),
    );
  }
}
