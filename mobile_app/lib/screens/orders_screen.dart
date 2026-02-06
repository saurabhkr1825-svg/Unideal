import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Add dependency if missed or format manually
import '../providers/order_provider.dart';
import '../providers/auth_provider.dart';

class OrdersScreen extends StatefulWidget {
  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        Provider.of<OrderProvider>(context, listen: false).fetchOrders(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Orders')),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, _) {
          if (orderProvider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (orderProvider.orders.isEmpty) {
            return Center(child: Text('No orders yet.', style: TextStyle(color: Colors.white)));
          }

          return ListView.builder(
            padding: EdgeInsets.all(10),
            itemCount: orderProvider.orders.length,
            itemBuilder: (ctx, i) {
              final order = orderProvider.orders[i];
              final product = order['product'];
              // Assuming populated product
              
              return Card(
                color: Colors.grey[900],
                margin: EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Icon(Icons.shopping_bag, color: Colors.purpleAccent),
                  title: Text(product != null ? product['name'] : 'Unknown Item', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${order['type'].toUpperCase()} - ₹${order['amount']}\nStatus: ${order['status']}', 
                    style: TextStyle(color: Colors.white70)
                  ),
                  trailing: Text(
                     product != null ? DateFormat('MM/dd/yyyy').format(DateTime.parse(order['createdAt'])) : '',
                     style: TextStyle(color: Colors.grey, fontSize: 12),
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
