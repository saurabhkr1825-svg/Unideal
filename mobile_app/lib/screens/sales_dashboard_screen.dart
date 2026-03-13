import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/auth_provider.dart';
import 'package:intl/intl.dart';

class SalesDashboardScreen extends StatefulWidget {
  @override
  _SalesDashboardScreenState createState() => _SalesDashboardScreenState();
}

class _SalesDashboardScreenState extends State<SalesDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        Provider.of<TransactionProvider>(context, listen: false).fetchTransactions(user.id);
      }
    });
  }

  Future<void> _handleAction(String txId, String action) async {
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      // Map action to status
      String newStatus = action == 'approve' ? 'completed' : 'failed';
      
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
        title: Text('Seller Dashboard', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: transactionData.isLoading
          ? Center(child: CircularProgressIndicator())
          : transactions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[300]),
                      SizedBox(height: 16),
                      Text('No Sales Activity Yet', style: TextStyle(color: Colors.grey, fontSize: 18, fontWeight: FontWeight.w500)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  itemCount: transactions.length,
                  itemBuilder: (ctx, i) {
                    final tx = transactions[i];
                    
                    return Container(
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Theme(
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.all(16),
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
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                            ),
                            trailing: Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                                    Divider(),
                                    _buildDetailRow('Transaction ID', tx.id.substring(0, 8)),
                                    _buildDetailRow('Reference', tx.paymentRef),
                                    _buildDetailRow('Date', DateFormat('MMM dd, yyyy • hh:mm a').format(tx.createdAt)),
                                    if (tx.status == 'pending') ...[
                                      SizedBox(height: 20),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () => _handleAction(tx.id, 'reject'),
                                              child: Text('REJECT'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.red,
                                                side: BorderSide(color: Colors.red[200]!),
                                                padding: EdgeInsets.symmetric(vertical: 12),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () => _handleAction(tx.id, 'approve'),
                                              child: Text('APPROVE'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                padding: EdgeInsets.symmetric(vertical: 12),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                              ),
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
                  },
                ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 13)),
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
