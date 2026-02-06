import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
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
        Provider.of<OrderProvider>(context, listen: false).fetchOrders(user.id, role: 'seller');
      }
    });
  }

  Future<void> _handleAction(String orderId, String action) async {
    try {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      await Provider.of<OrderProvider>(context, listen: false).approveOrder(orderId, action, user!.id);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order ${action}ed successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderData = Provider.of<OrderProvider>(context);
    final orders = orderData.orders;

    return Scaffold(
      appBar: AppBar(title: Text('My Sales')),
      body: orderData.isLoading
          ? Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? Center(child: Text('No sales yet', style: TextStyle(color: Colors.white)))
              : ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (ctx, i) {
                    final order = orders[i];
                    final product = order['product'];
                    final buyer = order['buyer'];
                    
                    return Card(
                      color: Colors.grey[900],
                      margin: EdgeInsets.all(10),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product != null ? product['name'] : 'Unknown Product', 
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                            SizedBox(height: 5),
                            Text('Buyer: ${buyer != null ? buyer['name'] : 'Unknown'}', style: TextStyle(color: Colors.white70)),
                            Text('Amount: ₹${order['amount']}', style: TextStyle(color: Colors.greenAccent)),
                            Text('Type: ${order['type']}', style: TextStyle(color: Colors.orangeAccent)),
                             if (order['type'] == 'rent')
                              Text('Dates: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(order['startDate']))} to ${DateFormat('yyyy-MM-dd').format(DateTime.parse(order['endDate']))}', style: TextStyle(color: Colors.white70)),
                            
                            SizedBox(height: 10),
                            Text('Status: ${order['status'].toUpperCase()}', 
                                style: TextStyle(fontWeight: FontWeight.bold, 
                                color: order['status'] == 'completed' || order['status'] == 'rented' ? Colors.green : Colors.yellow)),
                            
                            if (order['proofImage'] != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10.0),
                                child: Image.network(
                                    order['proofImage'], 
                                    height: 150, 
                                    width: double.infinity, 
                                    fit: BoxFit.cover,
                                    errorBuilder: (_,__,___) => Text('Proof Image Validation Failed or Mock URL', style: TextStyle(color: Colors.red)),
                                ),
                              ),

                            if (order['status'] == 'pending_approval')
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton(
                                    onPressed: () => _handleAction(order['_id'], 'reject'),
                                    child: Text('Reject', style: TextStyle(color: Colors.red)),
                                  ),
                                  SizedBox(width: 10),
                                  ElevatedButton(
                                    onPressed: () => _handleAction(order['_id'], 'approve'),
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                    child: Text('Approve'),
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
