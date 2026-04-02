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
  String _currentFilter = 'all';

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<ProductProvider>(context, listen: false).fetchProducts());
  }

  void _onTabTapped(int index) {
    if (index == 3) {
      Provider.of<AuthProvider>(context, listen: false).reloadUser();
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;
    switch (_currentIndex) {
      case 0:
        bodyContent = BrowseTab(filter: _currentFilter);
        break;
      case 1:
        bodyContent = ChatListScreen();
        break;
      case 2:
        bodyContent = OrdersScreen();
        break;
      case 3:
        bodyContent = ProfileTab();
        break;
      default:
        bodyContent = BrowseTab(filter: _currentFilter);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: bodyContent),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.blueAccent.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))
          ]
        ),
        child: FloatingActionButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SellItemScreen())),
          backgroundColor: Colors.blueAccent[700],
          elevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.add, color: Colors.white, size: 32),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 10.0,
        color: Colors.white,
        elevation: 10,
        child: SizedBox(
          height: 65,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(Icons.home_outlined, Icons.home, 'Home', 0),
              _buildNavItem(Icons.chat_bubble_outline, Icons.chat_bubble, 'Chats', 1),
              const SizedBox(width: 48), // Space for FAB
              _buildNavItem(Icons.receipt_long_outlined, Icons.receipt_long, 'Orders', 2),
              _buildNavItem(Icons.person_outline, Icons.person, 'Account', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData outlineIcon, IconData filledIcon, String label, int index) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? filledIcon : outlineIcon,
              color: isSelected ? Colors.blueAccent[700] : Colors.grey[400],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.blueAccent[700] : Colors.grey[500],
              ),
            )
          ],
        ),
      ),
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
    final user = Provider.of<AuthProvider>(context).user;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.location_on, color: Colors.blueAccent[700], size: 24),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Location', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                      Text(user?.fullName ?? 'Campus Marketplace', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ],
              ),
              _buildNotificationIconDark(),
            ],
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                      _applyFilters();
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search items...',
                      hintStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.search, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => _showFilterBottomSheet(),
                child: Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(Icons.tune, color: Colors.white, size: 24),
                ),
              ),
            ],
          ),
        ),

        // Categories
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: _categories.length,
            itemBuilder: (ctx, i) {
              final cat = _categories[i];
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategory = cat);
                    _applyFilters();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blueAccent[700] : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isSelected ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : null,
                      border: isSelected ? null : Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text('Recommended For You', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),

        Expanded(
          child: Consumer<ProductProvider>(
            builder: (context, productProvider, _) {
              if (productProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final products = productProvider.products;
              
              if (products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('No items found', style: TextStyle(fontSize: 18, color: Colors.grey[500], fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
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
                       rootHomeScreenState._onTabTapped(2);
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
