import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import 'product_detail_screen.dart';

class MyDonationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = Provider.of<AuthProvider>(context).user?.id;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('My Listings', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.white,
      body: FutureBuilder(
        // We filter products by donor_id in UI since provider doesn't have a specific user filter method yet
        future: Provider.of<ProductProvider>(context, listen: false).fetchProducts(),
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          final allProducts = Provider.of<ProductProvider>(context).products;
          final myDonations = allProducts.where((p) => p.donorId == userId).toList();

          if (myDonations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey[300]),
                  SizedBox(height: 16),
                  Text('No donations yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: myDonations.length,
            itemBuilder: (ctx, i) {
              final product = myDonations[i];
              return Container(
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                  border: Border.all(color: Colors.grey[100]!),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: product.imageUrl != null 
                      ? Image.network(product.imageUrl!, width: 60, height: 60, fit: BoxFit.cover)
                      : Container(color: Colors.indigo[50], width: 60, height: 60, child: Icon(Icons.image_outlined, color: Colors.indigo)),
                  ),
                  title: Text(product.title, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(product.category, style: TextStyle(fontSize: 12)),
                  trailing: Text(product.isAvailable ? 'AVAILABLE' : 'CLAIMED', 
                    style: TextStyle(color: product.isAvailable ? Colors.green : Colors.grey, fontWeight: FontWeight.bold, fontSize: 10)),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
