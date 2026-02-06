import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product_model.dart';
import 'product_detail_screen.dart';
import 'sell_item_screen.dart';
import 'login_screen.dart';
import 'sales_dashboard_screen.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Fetch products on load
    Future.microtask(() => 
      Provider.of<ProductProvider>(context, listen: false).fetchProducts()
    );
  }

  final List<Widget> _pages = [
    HomeTab(),
    Container(), // Placeholder for Sell - we push a new screen for Sell instead or use a tab. Let's use a tab logic but maybe push screen.
    Center(child: Text('Orders Screen', style: TextStyle(color: Colors.white))),
    Center(child: Text('Wallet Screen', style: TextStyle(color: Colors.white))),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Unideal Market'),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: () {
             Provider.of<ProductProvider>(context, listen: false).fetchProducts();
          })
        ],
      ),
      body: _currentIndex == 1 ? Container() : _pages[_currentIndex], // 1 is Sell, we handle differently
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.purpleAccent,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 1) {
            // Navigate to Sell Screen
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => SellItemScreen())).then((_) {
               // Refresh products when returning
               Provider.of<ProductProvider>(context, listen: false).fetchProducts();
            });
          } else {
            setState(() {
              _currentIndex = index;
            });
          }
        },
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Sell'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_bag), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, _) {
        if (productProvider.isLoading && productProvider.products.isEmpty) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (productProvider.products.isEmpty) {
          return Center(child: Text('No products found.', style: TextStyle(color: Colors.white)));
        }

        return RefreshIndicator(
          onRefresh: () => productProvider.fetchProducts(),
          child: GridView.builder(
            padding: EdgeInsets.all(10),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: productProvider.products.length,
            itemBuilder: (ctx, i) {
              final product = productProvider.products[i];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
                  );
                },
                child: Card(
                  color: Colors.grey[900],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                          child: product.images.isNotEmpty
                              ? Image.network(
                                  product.images[0], 
                                  fit: BoxFit.cover, 
                                  width: double.infinity,
                                  errorBuilder: (ctx, err, _) => Icon(Icons.image, color: Colors.grey),
                                )
                              : Icon(Icons.image, color: Colors.grey),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.name, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                            SizedBox(height: 4),
                            Text('₹${product.price}', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class ProfileTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.purpleAccent,
            child: Text(user?.email[0].toUpperCase() ?? 'U', style: TextStyle(fontSize: 40, color: Colors.white)),
          ),
          SizedBox(height: 20),
          Text(user?.email ?? 'Guest', style: TextStyle(color: Colors.white, fontSize: 20)),
          Text('ID: ${user?.userId}', style: TextStyle(color: Colors.grey)),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
               Navigator.of(context).push(MaterialPageRoute(builder: (_) => SalesDashboardScreen()));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: Text('My Sales (Seller Dashboard)'),
          ),
          SizedBox(height: 20),
          ElevatedButton.icon(
             style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
             icon: Icon(Icons.logout),
             label: Text('Logout'),
             onPressed: () {
               Provider.of<AuthProvider>(context, listen: false).logout();
               Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
             },
          )
        ],
      ),
    );
  }
}
