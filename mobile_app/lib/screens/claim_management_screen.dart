import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/claim_request_model.dart';
import '../services/supabase_claim_service.dart';
import '../providers/auth_provider.dart';
import 'chat_detail_screen.dart';

class ClaimManagementScreen extends StatefulWidget {
  final bool isAdminView;

  const ClaimManagementScreen({Key? key, this.isAdminView = false}) : super(key: key);

  @override
  _ClaimManagementScreenState createState() => _ClaimManagementScreenState();
}

class _ClaimManagementScreenState extends State<ClaimManagementScreen> {
  final SupabaseClaimService _claimService = SupabaseClaimService();
  List<ClaimRequest> _claims = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchClaims();
  }

  Future<void> _fetchClaims() async {
    setState(() => _isLoading = true);
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user == null) return;

      if (widget.isAdminView) {
        _claims = await _claimService.getPendingClaimsForAdmin();
      } else {
        _claims = await _claimService.getPendingClaimsForDonor(user.id);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAction(ClaimRequest claim, bool isApprove) async {
    try {
       if (isApprove) {
         await _claimService.approveClaim(claim.id, claim.itemId);
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Claim request approved.'), backgroundColor: Colors.green));
       } else {
         await _claimService.rejectClaim(claim.id);
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Claim request rejected.'), backgroundColor: Colors.orange));
       }
       _fetchClaims(); // Refresh list
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error processing claim: $e'), backgroundColor: Colors.red));
    }
  }

  void _openChat(ClaimRequest claim) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ChatDetailScreen(
        otherUserId: claim.userId,
        otherUserEmail: claim.name,
        donationId: claim.itemId,
        donationTitle: claim.itemTitle,
      )
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdminView ? 'All Pending Claims' : 'My Item Claims'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchClaims,
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _claims.isEmpty
              ? Center(child: Text('No pending claim requests found.', style: TextStyle(fontSize: 16, color: Colors.grey)))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _claims.length,
                  itemBuilder: (context, index) {
                    final claim = _claims[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (claim.itemImage != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(claim.itemImage!, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(width: 50, height: 50, color: Colors.grey[200])),
                                  ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    claim.itemTitle ?? 'Unknown Item',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                                ),
                              ],
                            ),
                            Divider(height: 30),
                            Text('Requester: ${claim.name}', style: TextStyle(fontWeight: FontWeight.w600)),
                            SizedBox(height: 4),
                            Text('Phone: ${claim.phone}', style: TextStyle(color: Colors.grey[700])),
                             SizedBox(height: 4),
                            Text('Time Pref: ${claim.pickupTimePreference}', style: TextStyle(color: Colors.indigo[700], fontWeight: FontWeight.w500)),
                            if (claim.pickupReason != null && claim.pickupReason!.isNotEmpty) ...[
                               SizedBox(height: 8),
                               Container(
                                 padding: EdgeInsets.all(8),
                                 width: double.infinity,
                                 decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                                 child: Text('Reason: ${claim.pickupReason}', style: TextStyle(fontStyle: FontStyle.italic)),
                               )
                            ],
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  onPressed: () => _openChat(claim),
                                  icon: Icon(Icons.chat_bubble_outline),
                                  color: Colors.blue,
                                  tooltip: 'Chat with Requester',
                                ),
                                Row(
                                  children: [
                                    OutlinedButton(
                                      onPressed: () => _handleAction(claim, false),
                                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                      child: Text('Reject'),
                                    ),
                                    SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => _handleAction(claim, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                      child: Text('Approve'),
                                    ),
                                  ],
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
