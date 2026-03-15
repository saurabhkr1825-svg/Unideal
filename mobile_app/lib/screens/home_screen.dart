import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product_model.dart';
import 'product_detail_screen.dart';
import 'sell_item_screen.dart';
import 'login_screen.dart';
import '../widgets/product_card.dart';
import 'sales_dashboard_screen.dart';
import '../providers/auth_provider.dart';
import 'chat_list_screen.dart';
import 'chat_list_screen.dart';
import 'payment_screen.dart';
import 'edit_profile_screen.dart';
import 'my_donations_screen.dart';
import 'orders_screen.dart';
import 'membership_screen.dart';
import 'admin_membership_panel.dart';
import 'admin_donation_panel.dart';
import 'admin_fund_release_panel.dart';
import 'notifications_screen.dart';
import '../services/supabase_notification_service.dart';
import '../models/notification_model.dart';
import '../providers/auction_provider.dart';
import '../widgets/live_auction_card.dart';
import 'claim_management_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  String _currentFilter = 'all'; // all, buy, donate, auction, rent

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<ProductProvider>(context, listen: false).fetchProducts());
  }

  void _onTabTapped(int index) {
    if (index == 4) { // Profile Tab
      Provider.of<AuthProvider>(context, listen: false).reloadUser();
    }
    setState(() {
      _currentIndex = index;
      if (index == 1) {
        _currentFilter = 'all'; // Reset filter when tapping Browse manually
      }
    });
  }

  void _navigateToBrowse(String filter) {
    setState(() {
      _currentFilter = filter;
      _currentIndex = 1; // Switch to Browse tab
    });
  }

  @override
  Widget build(BuildContext context) {
    // We can use a switch or list of widgets. Since we need to pass state (filter) to BrowseTab,
    // a switch or method is better than a const list.
    Widget bodyContent;
    switch (_currentIndex) {
      case 0:
        // Changed "Home" button to always browse
        bodyContent = HomeDashboard(onNavigate: _navigateToBrowse, onSellTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => SellItemScreen()));
        });
        break;
      case 1:
        bodyContent = BrowseTab(filter: _currentFilter ?? 'All');
        break;
      case 2:
        bodyContent = ChatListScreen();
        break;
      case 3:
        bodyContent = OrdersScreen();
        break;
      case 4:
        bodyContent = ProfileTab();
        break;
      default:
        bodyContent = HomeDashboard(onNavigate: _navigateToBrowse, onSellTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => SellItemScreen()));
        });
    }

    return Scaffold(
      body: SafeArea(child: bodyContent),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.indigo[700],
          unselectedItemColor: Colors.grey[400],
          showUnselectedLabels: true,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: TextStyle(fontSize: 12),
          elevation: 0,
          backgroundColor: Colors.white,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.search_outlined), activeIcon: Icon(Icons.search), label: 'Browse'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'Messages'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Orders'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}

class HomeDashboard extends StatelessWidget {
  final Function(String) onNavigate;
  final VoidCallback onSellTap;

  HomeDashboard({required this.onNavigate, required this.onSellTap});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium Hero Section
          Container(
            padding: EdgeInsets.fromLTRB(24, 60, 24, 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo[900]!, Colors.indigo[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
              boxShadow: [
                 BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 20, offset: Offset(0, 10))
              ]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hello, ${user?.fullName ?? "there"}!', style: TextStyle(color: Colors.white70, fontSize: 16)),
                        Text('Welcome Back 👋', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    _buildNotificationIcon(),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Explore Services', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                SizedBox(height: 20),
                
                // Primary Actions Grid
                Row(
                  children: [
                    _buildServiceCard(
                      context,
                      'Donate',
                      'Give away items',
                      Icons.favorite_border,
                      Colors.pink[400]!,
                      () => onNavigate('donate'),
                    ),
                    SizedBox(width: 16),
                    _buildServiceCard(
                      context,
                      'Auction',
                      'Bid to win',
                      Icons.gavel_outlined,
                      Colors.orange[400]!,
                      () => onNavigate('auction'),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    _buildServiceCard(
                      context,
                      'List Item',
                      'Start selling',
                      Icons.add_shopping_cart,
                      Colors.blue[400]!,
                      onSellTap,
                    ),
                    SizedBox(width: 16),
                     _buildServiceCard(
                      context,
                      'Browse',
                      'Find items',
                      Icons.search,
                      Colors.indigo[400]!,
                      () => onNavigate('all'),
                    ),
                  ],
                ),
                
                Consumer<ProductProvider>(
                  builder: (context, productProvider, _) {
                    final auctionProducts = productProvider.products.where((p) => p.isAuction).toList();
                    if (auctionProducts.isEmpty) return SizedBox.shrink();
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 35),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Live Auctions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            TextButton(onPressed: () => onNavigate('auction'), child: Text('View All'))
                          ],
                        ),
                        SizedBox(height: 10),
                        SizedBox(
                          height: 220,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: auctionProducts.length,
                            itemBuilder: (ctx, i) {
                               return LiveAuctionCard(product: auctionProducts[i]);
                            }
                          )
                        )
                      ]
                    );
                  }
                ),

                SizedBox(height: 35),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Community Activity', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    TextButton(onPressed: () => onNavigate('all'), child: Text('View All'))
                  ],
                ),
                Consumer<ProductProvider>(
                  builder: (context, productProvider, _) {
                    if (productProvider.isLoading) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (productProvider.products.isEmpty) {
                      return Center(child: Text('No recent activity.'));
                    }
                    final recentProducts = productProvider.products.take(3).toList();
                    return Column(
                      children: recentProducts.map((product) {
                        return _buildActivityCard(
                          product.isAuction ? 'Auction: ${product.title}' : (product.price == 0 ? 'Donation: ${product.title}' : 'Sale: ${product.title}'),
                          '${product.category} • ₹${product.price}',
                          product.isAuction ? Icons.gavel_outlined : (product.price == 0 ? Icons.favorite_border : Icons.shopping_bag_outlined),
                          product.isAuction ? Colors.purple : (product.price == 0 ? Colors.green : Colors.blue),
                          onTap: () {
                             Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)));
                          }
                        );
                      }).toList(),
                    );
                  },
                ),
                SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: Offset(0, 4))
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                child: Icon(icon, color: color, size: 28),
              ),
              SizedBox(height: 16),
              Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityCard(String title, String subtitle, IconData icon, Color iconColor, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
              child: Icon(icon, color: iconColor),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: Colors.grey, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
  Widget _buildNotificationIcon() {
    return StreamBuilder<List<NotificationModel>>(
      stream: SupabaseNotificationService().getNotificationStream(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data?.where((n) => !n.isRead).length ?? 0;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsScreen())),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.indigo[900]!, width: 1.5),
                  ),
                  constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class BrowseTab extends StatefulWidget {
  final String filter;
  BrowseTab({required this.filter});

  @override
  _BrowseTabState createState() => _BrowseTabState();
}

class _BrowseTabState extends State<BrowseTab> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  double? _minPrice;
  double? _maxPrice;
  String? _condition;
  String? _itemType;
  
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All', 'Books', 'Electronics', 'Furniture', 'Clothes', 'Hostel Essentials', 'Others'
  ];

  @override
  void initState() {
    super.initState();
    _applyIncomingFilter();
    Future.microtask(() => _applyFilters());
  }

  @override
  void didUpdateWidget(BrowseTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filter != oldWidget.filter) {
      _applyIncomingFilter();
      _applyFilters();
    }
  }

  void _applyIncomingFilter() {
    if (widget.filter == 'auction') {
      _itemType = 'auction';
    } else if (widget.filter == 'donate') {
      _itemType = 'donate';
    } else {
      _itemType = null;
    }
    // Also reset categories when coming from quick links
    _selectedCategory = 'All';
    _searchQuery = '';
    _searchController.clear();
  }

  void _applyFilters() {
    Provider.of<ProductProvider>(context, listen: false).fetchProducts(
      category: _selectedCategory == 'All' ? '' : _selectedCategory,
      search: _searchQuery,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      condition: _condition,
      itemType: _itemType,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Premium Search & Filter Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                      _applyFilters();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search items...',
                      prefixIcon: Icon(Icons.search, color: Colors.indigo),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              _buildNotificationIconDark(),
              SizedBox(width: 12),
              GestureDetector(
                onTap: () => _showFilterBottomSheet(),
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.indigo,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 8, offset: Offset(0, 4))],
                  ),
                  child: Icon(Icons.tune, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ),

        // Quick ItemType Chips
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            children: [
              _buildQuickTypeChip('All Items', null),
              _buildQuickTypeChip('Donations', 'donate'),
              _buildQuickTypeChip('Auctions', 'auction'),
              _buildQuickTypeChip('Selling', 'sale'),
            ],
          ),
        ),
        
        // Category Chips
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _categories.length,
            itemBuilder: (ctx, i) {
              final cat = _categories[i];
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = cat;
                    });
                    _applyFilters();
                  },
                  selectedColor: Colors.indigo[100],
                  checkmarkColor: Colors.indigo,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.indigo[900] : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: isSelected ? Colors.indigo : Colors.grey.shade200),
                  ),
                ),
              );
            },
          ),
        ),

        Expanded(
          child: Consumer<ProductProvider>(
            builder: (context, productProvider, _) {
              if (productProvider.isLoading) {
                return Center(child: CircularProgressIndicator());
              }

              final products = productProvider.products;
              
              if (products.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.05), shape: BoxShape.circle),
                        child: Icon(Icons.search_off_rounded, size: 80, color: Colors.indigo[200]),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'No matches found',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo[900]),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'We couldn\'t find any items matching your current filters. Try adjusting them or clearing everything.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600], height: 1.5),
                      ),
                      SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _selectedCategory = 'All';
                              _minPrice = null;
                              _maxPrice = null;
                              _condition = null;
                              _itemType = null;
                              _searchController.clear();
                            });
                            _applyFilters();
                          },
                          icon: Icon(Icons.refresh),
                          label: Text('Clear All Filters'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: products.length,
                itemBuilder: (ctx, i) {
                  final product = products[i];
                  return ProductCard(
                    product: product,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }



  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _FilterBottomSheet(
        initialMinPrice: _minPrice,
        initialMaxPrice: _maxPrice,
        initialCondition: _condition,
        initialItemType: _itemType,
        onApply: (min, max, cond, type) {
          setState(() {
            _minPrice = min;
            _maxPrice = max;
            _condition = cond;
            _itemType = type;
          });
          _applyFilters();
        },
      ),
    );
  }

  Widget _buildNotificationIconDark() {
    return StreamBuilder<List<NotificationModel>>(
      stream: SupabaseNotificationService().getNotificationStream(),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data?.where((n) => !n.isRead).length ?? 0;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.notifications_none_rounded, color: Colors.indigo[900], size: 28),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NotificationsScreen())),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
  Widget _buildQuickTypeChip(String label, String? typeValue) {
    final isSelected = _itemType == typeValue;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _itemType = typeValue;
          });
          _applyFilters();
        },
        selectedColor: Colors.pink[100],
        checkmarkColor: Colors.pink[800],
        labelStyle: TextStyle(
          color: isSelected ? Colors.pink[900] : Colors.grey[800],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isSelected ? Colors.pink[300]! : Colors.grey.shade300),
        ),
      ),
    );
  }
}

class _FilterBottomSheet extends StatefulWidget {
  final double? initialMinPrice;
  final double? initialMaxPrice;
  final String? initialCondition;
  final String? initialItemType;
  final Function(double?, double?, String?, String?) onApply;

  _FilterBottomSheet({
    this.initialMinPrice,
    this.initialMaxPrice,
    this.initialCondition,
    this.initialItemType,
    required this.onApply,
  });

  @override
  __FilterBottomSheetState createState() => __FilterBottomSheetState();
}

class __FilterBottomSheetState extends State<_FilterBottomSheet> {
  RangeValues _priceRange = RangeValues(0, 10000);
  String? _selectedCondition;
  String? _itemType;

  @override
  void initState() {
    super.initState();
    _priceRange = RangeValues(widget.initialMinPrice ?? 0, widget.initialMaxPrice ?? 10000);
    _selectedCondition = widget.initialCondition;
    _itemType = widget.initialItemType;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filters', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              IconButton(icon: Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          SizedBox(height: 24),
          
          Text('Price Range', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 10000,
            divisions: 20,
            labels: RangeLabels('₹${_priceRange.start.round()}', '₹${_priceRange.end.round()}'),
            onChanged: (values) => setState(() => _priceRange = values),
            activeColor: Colors.indigo,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('₹0'),
              Text('₹10,000+'),
            ],
          ),
          
          SizedBox(height: 24),
          Text('Condition', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Row(
            children: ['New', 'Good', 'Fair'].map((cond) {
              final isSelected = _selectedCondition == cond;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(cond),
                  selected: isSelected,
                  onSelected: (selected) => setState(() => _selectedCondition = selected ? cond : null),
                  selectedColor: Colors.indigo[100],
                ),
              );
            }).toList(),
          ),
          
          SizedBox(height: 24),
          Text('Item Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Row(
            children: [
              _buildTypeChip('Selling', 'sale'),
              SizedBox(width: 8),
              _buildTypeChip('Donations', 'donate'),
              SizedBox(width: 8),
              _buildTypeChip('Auctions', 'auction'),
            ],
          ),
          
          SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onApply(null, null, null, null);
                    Navigator.pop(context);
                  },
                  child: Text('Reset'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply(
                      _priceRange.start == 0 ? null : _priceRange.start,
                      _priceRange.end == 10000 ? null : _priceRange.end,
                      _selectedCondition,
                      _itemType,
                    );
                    Navigator.pop(context);
                  },
                  child: Text('Apply Filters'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, String value) {
    final isSelected = _itemType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => setState(() => _itemType = selected ? value : null),
      selectedColor: Colors.indigo[100],
    );
  }
}



class ProfileTab extends StatelessWidget {
   @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    return SingleChildScrollView(
      child: Column(
        children: [
          // Premium Header Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, 60, 24, 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo[900]!, Colors.indigo[700]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Text(user?.fullName[0].toUpperCase() ?? 'U', style: TextStyle(fontSize: 40, color: Colors.indigo[900], fontWeight: FontWeight.bold)),
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                        child: Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      ),
                    )
                  ],
                ),
                SizedBox(height: 20),
                Text(user?.fullName ?? 'Guest User', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('User ID: ${user?.uniqueCode}', style: TextStyle(color: Colors.white70, fontSize: 14)),
                SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    user?.role.toUpperCase() ?? 'USER',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ),
                SizedBox(height: 24),
                
                // Membership Badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: user?.membershipStatus == true ? Colors.green[400] : Colors.orange[400],
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(user?.membershipStatus == true ? Icons.verified : Icons.stars, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        user?.membershipStatus == true ? 'VERIFIED PREMIUM MEMBER' : 'REGULAR MEMBER',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (user?.membershipStatus == true && user?.membershipExpiry != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('Valid till: ${user!.membershipExpiry!.day}/${user.membershipExpiry!.month}/${user.membershipExpiry!.year}', style: TextStyle(color: Colors.white60, fontSize: 11)),
                  ),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Account Settings'),
                SizedBox(height: 16),
                _buildProfileItem(Icons.person_outline, 'Edit Profile', 'Update your personal info', () {
                   Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditProfileScreen()));
                }),
                _buildProfileItem(Icons.receipt_long_outlined, 'My Orders', 'Items you\'ve purchased', () {
                   Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrdersScreen()));
                }),
                _buildProfileItem(Icons.shopping_bag_outlined, 'Seller\'s Dashboard', 'Manage your marketplace items', () {
                   Navigator.of(context).push(MaterialPageRoute(builder: (_) => SalesDashboardScreen()));
                }),
                _buildProfileItem(Icons.favorite_outline, 'My Listings', 'Items you\'ve given away', () {
                   Navigator.of(context).push(MaterialPageRoute(builder: (_) => MyDonationsScreen()));
                }),
                _buildProfileItem(Icons.how_to_reg, 'Manage Claim Requests', 'Approve/Reject requests for your items', () {
                   Navigator.of(context).push(MaterialPageRoute(builder: (_) => ClaimManagementScreen(isAdminView: false)));
                }),
                // Admin-specific option
                if (user?.role == 'admin') ...[
                  _buildProfileItem(Icons.card_membership_rounded, 'Admin: Membership Requests', 'Approve/Reject premium plans', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AdminMembershipPanel()));
                  }),
                  _buildProfileItem(Icons.inventory_2_outlined, 'Admin: Donation Claims', 'Manage unified pending claims', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ClaimManagementScreen(isAdminView: true)));
                  }),
                  _buildProfileItem(Icons.account_balance_wallet_outlined, 'Admin: Fund Release', 'Approve/Reject seller fund releases', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AdminFundReleasePanel()));
                  }),
                ],
                _buildProfileItem(Icons.chat_bubble_outline, 'My Chats', 'Recent conversations', () {
                   // Navigate to Messages tab (Index 2 in the bottom nav bar is MessagesTab)
                   final rootHomeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
                   if (rootHomeScreenState != null) {
                       rootHomeScreenState.setState(() {
                         rootHomeScreenState._selectedIndex = 2;
                       });
                   }
                }),
                
                SizedBox(height: 32),
                _buildSectionTitle('Support & Others'),
                SizedBox(height: 16),
                _buildProfileItem(Icons.card_membership, 'Membership Details', 'View plan benefits', () {
                   Navigator.of(context).push(MaterialPageRoute(builder: (_) => MembershipScreen()));
                }),
                _buildProfileItem(Icons.help_outline, 'Help & Support', 'FAQs and contact us', () {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Help Center coming soon!')));
                }),
                _buildProfileItem(Icons.policy_outlined, 'Privacy Policy', 'Data usage and security', () {
                   ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Privacy Policy loaded.')));
                }),
                
                SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Provider.of<AuthProvider>(context, listen: false).logout();
                      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LoginScreen()));
                    },
                    icon: Icon(Icons.logout),
                    label: Text('LOGOUT ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
                SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87));
  }

  Widget _buildProfileItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.indigo, size: 24),
        ),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
