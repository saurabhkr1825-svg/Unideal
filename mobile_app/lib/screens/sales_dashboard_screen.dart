import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/auth_provider.dart';
import '../models/transaction_model.dart';
import '../models/purchase_request_model.dart';
import '../services/supabase_purchase_service.dart';
import 'package:intl/intl.dart';

class SalesDashboardScreen extends StatefulWidget {
  const SalesDashboardScreen({super.key});

  @override
  _SalesDashboardScreenState createState() => _SalesDashboardScreenState();
}

class _SalesDashboardScreenState extends State<SalesDashboardScreen> {
  List<PurchaseRequest> _incomingRequests = [];
  bool _isRequestsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    setState(() => _isRequestsLoading = true);
    
    // Fetch legacy transactions
    Provider.of<TransactionProvider>(context, listen: false).fetchTransactions(user.id);
    
    // Fetch new purchase requests
    try {
      final requests = await SupabasePurchaseService().getIncomingRequests(user.id);
      if (mounted) {
        setState(() {
          _incomingRequests = requests;
          _isRequestsLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isRequestsLoading = false);
    }
  }

  Future<void> _handleRequestAction(PurchaseRequest req, String status) async {
    try {
      await SupabasePurchaseService().updateRequestStatus(req.id, req.productId, req.buyerId, status);
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Request ${status}ed successfully'),
        backgroundColor: status == 'accepted' ? Colors.green : Colors.orange,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Action failed: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _handleAction(String txId, String action) async {
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      String newStatus = action == 'approve' ? 'completed' : 'rejected_by_donor';
      final tx = Provider.of<TransactionProvider>(context, listen: false).transactions.firstWhere((t) => t.id == txId);
      await Provider.of<TransactionProvider>(context, listen: false).updateTransactionStatus(
        transactionId: txId,
        status: newStatus,
        userId: user!.id,
        itemTitle: tx.itemTitle ?? 'Sale Item',
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Transaction ${action}ed successfully'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Action failed: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionData = Provider.of<TransactionProvider>(context);
    final transactions = transactionData.transactions;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Seller Dashboard', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: transactionData.isLoading || _isRequestsLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                children: [
                  if (_incomingRequests.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('NEW BUY REQUESTS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                    ),
                    ..._incomingRequests.map((req) => _buildRequestItem(req)),
                    const SizedBox(height: 24),
                  ],
                  if (transactions.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('TRANSACTION HISTORY', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                    ...transactions.map((tx) => _buildTransactionItem(tx, transactionData, context)),
                  ],
                  if (_incomingRequests.isEmpty && transactions.isEmpty)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 100),
                          Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text('No Sales Activity Yet', style: TextStyle(color: Colors.grey[400], fontSize: 18, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildRequestItem(PurchaseRequest req) {
    bool isPending = req.status == 'pending';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50, height: 50,
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.shopping_cart_checkout, color: Colors.indigo),
        ),
        title: Text(req.buyerName ?? 'Campus Student', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('Requested: ${req.productTitle}', maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: (req.status == 'accepted' ? Colors.green : (req.status == 'rejected' ? Colors.red : Colors.orange)).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            req.status.toUpperCase(),
            style: TextStyle(color: req.status == 'accepted' ? Colors.green : (req.status == 'rejected' ? Colors.red : Colors.orange), fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                _buildDetailRow('Hostel', req.hostelName),
                _buildDetailRow('Room', req.roomNo),
                _buildDetailRow('Meeting Point', req.meetingPoint),
                if (req.phone != null) _buildDetailRow('Contact', req.phone!),
                _buildDetailRow('Date', DateFormat('MMM dd, hh:mm a').format(req.createdAt)),
                if (isPending) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _handleRequestAction(req, 'rejected'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: BorderSide(color: Colors.red[200]!),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('REJECT'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _handleRequestAction(req, 'accepted'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('ACCEPT'),
                        ),
                      ),
                    ],
                  )
                ]
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel tx, TransactionProvider transactionData, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.all(16),
            leading: Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: _getStatusColor(tx.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_getStatusIcon(tx.status), color: _getStatusColor(tx.status)),
            ),
            title: Text(
              tx.type.replaceAll('_', ' ').toUpperCase(),
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey[600]),
            ),
            subtitle: Text(
              '₹${tx.amount.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(tx.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tx.status.toUpperCase(),
                style: TextStyle(color: _getStatusColor(tx.status), fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    const Divider(),
                    _buildDetailRow('Transaction ID', tx.id.substring(0, 8)),
                    _buildDetailRow('Reference', tx.paymentRef),
                    _buildDetailRow('Date', DateFormat('MMM dd, yyyy • hh:mm a').format(tx.createdAt)),
                    if (tx.status == 'pending') ...[
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _handleAction(tx.id, 'reject'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: BorderSide(color: Colors.red[200]!),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                              ),
                              child: const Text('REJECT'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _handleAction(tx.id, 'approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                              ),
                              child: const Text('APPROVE'),
                            ),
                          ),
                        ],
                      )
                    ]
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'pending': return Colors.orange;
      case 'failed': return Colors.red;
      default: return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed': return Icons.check_circle_outline;
      case 'pending': return Icons.hourglass_empty;
      case 'failed': return Icons.error_outline;
      default: return Icons.info_outline;
    }
  }
}
