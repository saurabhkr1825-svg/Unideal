import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';

class AdminFundReleasePanel extends StatefulWidget {
  @override
  _AdminFundReleasePanelState createState() => _AdminFundReleasePanelState();
}

class _AdminFundReleasePanelState extends State<AdminFundReleasePanel> {
  late Future<List<TransactionModel>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() {
    setState(() {
      _requestsFuture = Provider.of<TransactionProvider>(context, listen: false).getFundReleaseRequests();
    });
  }

  Future<void> _handleAction(TransactionModel tx, bool approve) async {
    try {
      final provider = Provider.of<TransactionProvider>(context, listen: false);
      if (approve) {
        await provider.releaseFunds(tx.id, tx.sellerId!, tx.itemTitle ?? tx.type);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Funds Released!'), backgroundColor: Colors.green));
      } else {
        await provider.rejectFunds(tx.id, tx.sellerId!, tx.itemTitle ?? tx.type);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Request Rejected.'), backgroundColor: Colors.red));
      }
      _loadRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Action failed: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fund Release Requests'),
        backgroundColor: Colors.indigo[900],
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<TransactionModel>>(
        future: _requestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red)));
          }
          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.green[200]),
                  SizedBox(height: 16),
                  Text('All Caught Up!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo[900])),
                  Text('No pending fund release requests.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final tx = requests[index];
              return Card(
                margin: EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 3,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('Item: ${tx.itemTitle ?? tx.type.toUpperCase()}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          Text('₹${tx.amount.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.indigo)),
                        ],
                      ),
                      Divider(height: 24),
                      Text('Transaction ID: ${tx.id}', style: TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'monospace')),
                      SizedBox(height: 8),
                      Text('Buyer ID: ${tx.userId}', style: TextStyle(fontSize: 12, color: Colors.black87)),
                      Text('Seller ID: ${tx.sellerId}', style: TextStyle(fontSize: 12, color: Colors.black87)),
                      SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.indigo[50], borderRadius: BorderRadius.circular(10)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Seller Payment Details:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo[900])),
                            SizedBox(height: 4),
                            Text('Method: ${tx.sellerPaymentMethod ?? "Unknown"}'),
                            if (tx.sellerUpi != null && tx.sellerUpi!.isNotEmpty) Text('UPI / Account: ${tx.sellerUpi}'),
                            if (tx.sellerPhone != null && tx.sellerPhone!.isNotEmpty) Text('Phone: ${tx.sellerPhone}'),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.verified_user, color: Colors.green, size: 16),
                                SizedBox(width: 4),
                                Text('OTP Verified', style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _handleAction(tx, false),
                              child: Text('Reject'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _handleAction(tx, true),
                              child: Text('Approve Payment'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
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
          );
        },
      ),
    );
  }
}
