import 'package:flutter/material.dart';
import '../services/supabase_transaction_service.dart';
import '../models/transaction_model.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';

class AdminDonationPanel extends StatefulWidget {
  @override
  _AdminDonationPanelState createState() => _AdminDonationPanelState();
}

class _AdminDonationPanelState extends State<AdminDonationPanel> {
  final SupabaseTransactionService _transactionService = SupabaseTransactionService();
  bool _isLoading = true;
  List<TransactionModel> _requests = [];

  @override
  void initState() {
    super.initState();
    _fetchRequests();
  }

  Future<void> _fetchRequests() async {
    setState(() => _isLoading = true);
    try {
      final requests = await _transactionService.getAllPendingTransactions();
      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error fetching requests: $e')));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(String id, String status, String userId, String itemTitle, {String? donationId}) async {
    try {
      await _transactionService.updateTransactionStatus(id, status, userId, itemTitle);
      
      if (donationId != null) {
        if (status == 'pending') {
          // Transaction approved by admin, reserve the item
          await Provider.of<ProductProvider>(context, listen: false).updateProductStatus(donationId, 'reserved');
        } else if (status == 'failed') {
          // Transaction rejected, make the item available again
          await Provider.of<ProductProvider>(context, listen: false).updateProductStatus(donationId, 'available');
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request $status successfully!'), backgroundColor: status == 'completed' ? Colors.green : Colors.red));
      _fetchRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    }
  }

  void _showImageDialog(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(url),
            TextButton(onPressed: () => Navigator.pop(context), child: Text('Close'))
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Donation Requests', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _requests.isEmpty
              ? Center(child: Text('No pending requests found.'))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _requests.length,
                  itemBuilder: (context, index) {
                    final req = _requests[index];
                    final formattedDate = DateFormat('dd MMM, hh:mm a').format(req.createdAt);

                    return Card(
                      margin: EdgeInsets.only(bottom: 16),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(req.itemTitle ?? 'Unknown Item', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo))),
                                Text(formattedDate, style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text('User: ${req.userName ?? "N/A"}', style: TextStyle(fontWeight: FontWeight.w500)),
                            Text('Type: ${req.type.toUpperCase()}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            if (req.amount > 0)
                              Text('Amount: ₹${req.amount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold)),
                            
                            SizedBox(height: 12),
                            SizedBox(height: 12),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Escrow Status:', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(10)),
                                        child: Text(req.escrowStatus.toUpperCase(), style: TextStyle(fontSize: 10, color: Colors.blue[800], fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4),
                                  Text('UTR: ${req.utrNumber ?? "NOT PROVIDED"}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo)),
                                  if (req.sellerPaymentDetails != null) ...[
                                    Divider(height: 20),
                                    Text('Seller Payment Details:', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                                    SizedBox(height: 4),
                                    Text('UPI: ${req.sellerPaymentDetails!['upi_id']}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                    Text('Phone: ${req.sellerPaymentDetails!['phone']}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                  ],
                                ],
                              ),
                            ),
                            
                            SizedBox(height: 16),
                            // Screenshot Preview
                            if (req.paymentRef.startsWith('http'))
                              GestureDetector(
                                onTap: () => _showImageDialog(req.paymentRef),
                                child: Container(
                                  height: 120,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(req.paymentRef, fit: BoxFit.cover),
                                  ),
                                ),
                              ),
                            
                            SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _updateStatus(req.id, 'rejected_by_admin', req.userId, req.itemTitle ?? 'Item', donationId: req.donationId),
                                    child: Text('Reject'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: BorderSide(color: Colors.red),
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _updateStatus(req.id, 'pending', req.userId, req.itemTitle ?? 'Item', donationId: req.donationId),
                                    child: Text('Approve'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
