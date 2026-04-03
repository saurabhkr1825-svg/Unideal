import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../utils/app_theme.dart';
import 'product_detail_screen.dart';
import 'sell_item_screen.dart';
import 'login_screen.dart';
import '../widgets/product_card.dart';
import 'sales_dashboard_screen.dart';
import '../providers/auth_provider.dart';
import 'chat_list_screen.dart';
import 'edit_profile_screen.dart';
import 'my_donations_screen.dart';
import 'orders_screen.dart';
import 'membership_screen.dart';
import 'admin_membership_panel.dart';
import 'admin_fund_release_panel.dart';
import 'notifications_screen.dart';
import '../services/supabase_notification_service.dart';
import '../models/notification_model.dart';
import '../widgets/live_auction_card.dart';
import 'claim_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SellItemScreen()));
        });
        break;
      case 1:
        bodyContent = BrowseTab(filter: _currentFilter ?? 'All');
        break;
      case 2:
        bodyContent = const ChatListScreen();
        break;
      case 3:
        bodyContent = const OrdersScreen();
        break;
      case 4:
        bodyContent = const ProfileTab();
        break;
      default:
        bodyContent = HomeDashboard(onNavigate: _navigateToBrowse, onSellTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SellItemScreen()));
        });
    }

    return Scaffold(
      body: SafeArea(child: bodyContent),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.indigo[700],
          unselectedItemColor: Colors.grey[400],
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          elevation: 0,
          backgroundColor: Colors.white,
          items: const [
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

  const HomeDashboard({super.key, required this.onNavigate, required this.onSellTap});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Premium Hero Section
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo[900]!, Colors.indigo[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
              boxShadow: [
                 BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
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
                        Text('Hello, ${user?.fullName ?? "there"}!', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                        const Text('Welcome Back 👋', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
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
                const Text('Explore Services', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                const SizedBox(height: 20),
                
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
                    const SizedBox(width: 16),
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
                const SizedBox(height: 16),
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
                    const SizedBox(width: 16),
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
                    if (auctionProducts.isEmpty) return const SizedBox.shrink();
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 35),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Live Auctions', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            TextButton(onPressed: () => onNavigate('auction'), child: const Text('View All'))
                          ],
                        ),
                        const SizedBox(height: 10),
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

                const SizedBox(height: 35),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Community Activity', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    TextButton(onPressed: () => onNavigate('all'), child: const Text('View All'))
                  ],
                ),
                Consumer<ProductProvider>(
                  builder: (context, productProvider, _) {
                    if (productProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (productProvider.products.isEmpty) {
                      return const Center(child: Text('No recent activity.'));
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
                const SizedBox(height: 30),
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
            ],
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
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
              icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.indigo[900]!, width: 1.5),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
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
  const BrowseTab({super.key, required this.filter});

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

  int getCrossAxisCount(double width) {
    if (width > 1200) return 4;
    if (width > 900) return 3;
    if (width > 600) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width > 900;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1300),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(isDesktop),
                Expanded(
                  child: Consumer<ProductProvider>(
                    builder: (context, productProvider, _) {
                      if (productProvider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final products = productProvider.products;
                      if (products.isEmpty) {
                        return _buildNoResultsPlaceholder();
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: getCrossAxisCount(width),
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
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
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(bool isDesktop) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() => _searchQuery = val);
                    _applyFilters();
                  },
                  decoration: InputDecoration(
                    hintText: "Search items...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              if (isDesktop) const SizedBox(width: 16),
              if (isDesktop) _buildNotificationIconDark(),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _showFilterBottomSheet(),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Icon(Icons.tune, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip("All", null),
                const SizedBox(width: 8),
                _buildFilterChip("Donations", 'donate'),
                const SizedBox(width: 8),
                _buildFilterChip("Auctions", 'auction'),
                const SizedBox(width: 8),
                _buildFilterChip("Selling", 'sale'),
                const SizedBox(width: 16),
                Container(width: 1, height: 24, color: Colors.grey.shade300),
                const SizedBox(width: 16),
                ..._categories.map((cat) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildCategoryChip(cat),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? typeValue) {
    final isSelected = _itemType == typeValue;
    return GestureDetector(
      onTap: () {
        setState(() => _itemType = typeValue);
        _applyFilters();
      },
      child: Chip(
        label: Text(label),
        backgroundColor: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey.shade100,
        labelStyle: TextStyle(
          color: isSelected ? AppTheme.primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  Widget _buildCategoryChip(String cat) {
    final isSelected = _selectedCategory == cat;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = cat);
        _applyFilters();
      },
      child: Chip(
        label: Text(cat),
        backgroundColor: isSelected ? Colors.indigo.shade50 : Colors.grey.shade100,
        labelStyle: TextStyle(
          color: isSelected ? Colors.indigo : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
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
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$unreadCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildNoResultsPlaceholder() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.indigo[100]),
          const SizedBox(height: 16),
          Text(
            'No matches found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo[900]),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search query.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          TextButton(
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
            child: const Text('Clear all filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanTypeChip(String label, String? typeValue) {
    final isSelected = _itemType == typeValue;
    return GestureDetector(
      onTap: () {
        setState(() => _itemType = typeValue);
        _applyFilters();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo[50] : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? Colors.indigo : Colors.grey.shade200),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.indigo[800] : Colors.grey[800],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
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
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    unreadCount > 9 ? '9+' : '$unreadCount',
                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
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

  const _FilterBottomSheet({
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
  RangeValues _priceRange = const RangeValues(0, 10000);
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
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
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
              const Text('Filters', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 24),
          
          const Text('Price Range', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 10000,
            divisions: 20,
            labels: RangeLabels('₹${_priceRange.start.round()}', '₹${_priceRange.end.round()}'),
            onChanged: (values) => setState(() => _priceRange = values),
            activeColor: Colors.indigo,
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('₹0'),
              Text('₹10,000+'),
            ],
          ),
          
          const SizedBox(height: 24),
          const Text('Condition', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
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
          
          const SizedBox(height: 24),
          const Text('Item Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildTypeChip('Selling', 'sale'),
              const SizedBox(width: 8),
              _buildTypeChip('Donations', 'donate'),
              const SizedBox(width: 8),
              _buildTypeChip('Auctions', 'auction'),
            ],
          ),
          
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    widget.onApply(null, null, null, null);
                    Navigator.pop(context);
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('Reset'),
                ),
              ),
              const SizedBox(width: 16),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
  const ProfileTab({super.key});

   @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    return SingleChildScrollView(
      child: Column(
        children: [
          // Premium Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.indigo[900]!, Colors.indigo[700]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Text(user?.fullName[0].toUpperCase() ?? 'U', style: TextStyle(fontSize: 40, color: Colors.indigo[900], fontWeight: FontWeight.bold)),
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                Text(user?.fullName ?? 'Guest User', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('User ID: ${user?.uniqueCode}', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    user?.role.toUpperCase() ?? 'USER',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Membership Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: user?.membershipStatus == true ? Colors.green[400] : Colors.orange[400],
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(user?.membershipStatus == true ? Icons.verified : Icons.stars, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        user?.membershipStatus == true ? 'VERIFIED PREMIUM MEMBER' : 'REGULAR MEMBER',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (user?.membershipStatus == true && user?.membershipExpiry != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('Valid till: ${user!.membershipExpiry!.day}/${user.membershipExpiry!.month}/${user.membershipExpiry!.year}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
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
                const SizedBox(height: 16),
                _buildProfileItem(Icons.person_outline, 'Edit Profile', 'Update your personal info', () {
                   Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                }),
                _buildProfileItem(Icons.receipt_long_outlined, 'My Orders', 'Items you\'ve purchased', () {
                   Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OrdersScreen()));
                }),
                _buildProfileItem(Icons.shopping_bag_outlined, 'Seller\'s Dashboard', 'Manage your marketplace items', () {
                   Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SalesDashboardScreen()));
                }),
                _buildProfileItem(Icons.favorite_outline, 'My Listings', 'Items you\'ve given away', () {
                   Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MyDonationsScreen()));
                }),
                _buildProfileItem(Icons.how_to_reg, 'Manage Claim Requests', 'Approve/Reject requests for your items', () {
                   Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ClaimManagementScreen(isAdminView: false)));
                }),
                // Admin-specific option
                if (user?.role == 'admin') ...[
                  _buildProfileItem(Icons.card_membership_rounded, 'Admin: Membership Requests', 'Approve/Reject premium plans', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminMembershipPanel()));
                  }),
                  _buildProfileItem(Icons.inventory_2_outlined, 'Admin: Donation Claims', 'Manage unified pending claims', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ClaimManagementScreen(isAdminView: true)));
                  }),
                  _buildProfileItem(Icons.account_balance_wallet_outlined, 'Admin: Fund Release', 'Approve/Reject seller fund releases', () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminFundReleasePanel()));
                  }),
                ],
                _buildProfileItem(Icons.chat_bubble_outline, 'My Chats', 'Recent conversations', () {
                   // Navigate to Messages tab (Index 2 in the bottom nav bar is MessagesTab)
                   final rootHomeScreenState = context.findAncestorStateOfType<_HomeScreenState>();
                   if (rootHomeScreenState != null) {
                       rootHomeScreenState._onTabTapped(2);
                   }
                }),
                
                const SizedBox(height: 32),
                _buildSectionTitle('Support & Others'),
                const SizedBox(height: 16),
                _buildProfileItem(Icons.card_membership, 'Membership Details', 'View plan benefits', () {
                   Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MembershipScreen()));
                }),
                _buildProfileItem(Icons.help_outline, 'Help & Support', 'FAQs and contact us', () {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Help Center coming soon!')));
                }),
                _buildProfileItem(Icons.policy_outlined, 'Privacy Policy', 'Data usage and security', () {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Privacy Policy loaded.')));
                }),
                
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Provider.of<AuthProvider>(context, listen: false).logout();
                      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('LOGOUT ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87));
  }

  Widget _buildProfileItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.indigo.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.indigo, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
