import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import 'payment_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({Key? key, required this.product}) : super(key: key);

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _handleBuy(BuildContext context) async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please login to buy')));
      return;
    }

    try {
      await Provider.of<ProductProvider>(context, listen: false).lockProduct(widget.product.id, user.id);
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaymentScreen(product: widget.product, type: 'buy'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: Colors.red,
      ));
    }
  }

  Future<void> _handleRent(BuildContext context) async {
     final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please login to rent')));
      return;
    }

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });

      // Calculate logic happens in Payment Screen or here?
      // Passing dates to Payment Screen.
      
      try {
        // We might want to lock it too? 
        await Provider.of<ProductProvider>(context, listen: false).lockProduct(widget.product.id, user.id);
        
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PaymentScreen(
              product: widget.product, 
              type: 'rent',
              startDate: _startDate,
              endDate: _endDate,
            ),
          ),
        );
      } catch (e) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to lock: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.product.name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel (Simplified)
            Container(
              height: 300,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.product.images.length,
                itemBuilder: (ctx, i) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Image.network(
                      widget.product.images[i],
                      fit: BoxFit.cover,
                      width: MediaQuery.of(context).size.width,
                      errorBuilder: (ctx, err, _) => Container(
                        width: MediaQuery.of(context).size.width,
                        color: Colors.grey, 
                        child: Icon(Icons.broken_image, size: 50)
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${widget.product.price}',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                      ),
                      if (widget.product.allowRent)
                        Text(
                          'Rent: ₹${widget.product.rentPrice}/day',
                          style: TextStyle(fontSize: 16, color: Colors.orangeAccent),
                        ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    widget.product.name,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                   SizedBox(height: 5),
                  Chip(
                    label: Text(widget.product.category),
                    backgroundColor: Colors.indigo,
                  ),
                  SizedBox(height: 5),
                  Text('Condition: ${widget.product.condition}', style: TextStyle(color: Colors.grey)),
                  if (widget.product.status == 'sold')
                    Container(
                      margin: EdgeInsets.symmetric(vertical: 10),
                      padding: EdgeInsets.all(8),
                      color: Colors.red,
                      child: Text('SOLD OUT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  SizedBox(height: 20),
                  Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 5),
                  Text(
                    widget.product.description,
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                  SizedBox(height: 30),
                  
                  // Action Buttons
                  if (widget.product.status != 'sold')
                  Row(
                    children: [
                      if (widget.product.allowBuy)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _handleBuy(context),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: Text('BUY'),
                          ),
                        ),
                      SizedBox(width: 10),
                      if (widget.product.allowRent)
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _handleRent(context),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                            child: Text('RENT'),
                          ),
                        ),
                    ],
                  ),

                  if (widget.product.allowAuction)
                     Center(
                       child: Padding(
                         padding: const EdgeInsets.only(top: 10.0),
                         child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bidding Feature Coming Soon! Starting Bid: ₹${widget.product.price}')));
                          },
                          icon: Icon(Icons.gavel),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                          label: Text('Place Bid (Auction)'),
                         ),
                       ),
                     ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
