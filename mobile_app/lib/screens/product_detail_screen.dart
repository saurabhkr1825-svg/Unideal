import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import 'chat_detail_screen.dart';
import 'membership_screen.dart';
import '../services/supabase_auth_service.dart';
import '../providers/auction_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_buttons.dart';
import '../widgets/item_badge.dart';
import '../services/supabase_claim_service.dart';
import '../services/supabase_purchase_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({Key? key, required this.product}) : super(key: key);

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  Future<void> _handleBuy(BuildContext context, {double? overridePrice}) async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login to continue')));
      return;
    }

    _showPurchaseRequestDialog(context);
  }

  void _showPurchaseRequestDialog(BuildContext context) {
    final user = Provider.of<AuthProvider>(context, listen: false).user!;
    final hostelController = TextEditingController();
    final roomNoController = TextEditingController();
    final meetingPointController = TextEditingController();
    final phoneController = TextEditingController(text: user.phone ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
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
                  const Text('Buy Request', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 8),
              Text('Request to buy "${widget.product.title}" for ₹${widget.product.price.toStringAsFixed(0)}', 
                  style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              const SizedBox(height: 20),
              
              TextField(
                controller: hostelController,
                decoration: const InputDecoration(labelText: 'Hostel Name (e.g. Aryabhatt)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: roomNoController,
                decoration: const InputDecoration(labelText: 'Room No (e.g. 203)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: meetingPointController,
                decoration: const InputDecoration(labelText: 'Meeting Point (e.g. Hostel Gate)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Contact No (Optional)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  onPressed: () async {
                    if (hostelController.text.isEmpty || roomNoController.text.isEmpty || meetingPointController.text.isEmpty) {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill Hostel, Room, and Meeting Point.')));
                       return;
                    }

                    Navigator.pop(ctx);
                    try {
                      await SupabasePurchaseService().submitPurchaseRequest(
                        productId: widget.product.id,
                        buyerId: user.id,
                        sellerId: widget.product.donorId,
                        hostelName: hostelController.text,
                        roomNo: roomNoController.text,
                        meetingPoint: meetingPointController.text,
                        phone: phoneController.text.isNotEmpty ? phoneController.text : null,
                      );
                      
                      // Notification to user
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Purchase request sent! Seller will accept/reject.'), 
                        backgroundColor: Colors.green
                      ));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(e.toString().replaceAll('Exception: ', '')), 
                        backgroundColor: Colors.red
                      ));
                    }
                  },
                  icon: Icons.send_rounded,
                  text: 'SEND REQUEST',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.product.title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image Section
            Hero(
              tag: 'product-${widget.product.id}',
              child: Container(
                height: 350,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
                  child: widget.product.imageUrl != null
                      ? Image.network(
                          widget.product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, _) => Container(
                            color: Colors.grey[100], 
                            child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey))
                          ),
                        )
                      : Container(
                          color: Colors.grey[100],
                          child: const Center(child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey)),
                       ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBadge(),
                      Text(
                        'Category: ${widget.product.category}',
                        style: const TextStyle(color: Colors.indigo, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.title,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      ),
                      if (widget.product.price > 0 && !widget.product.isAuction)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${widget.product.price.toStringAsFixed(0)}',
                              style: AppTheme.priceStyle.copyWith(fontSize: 24),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.product.description,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  
                  if (widget.product.isAuction)
                    _buildAuctionStream(context),
                  
                  // Action Section
                  if (widget.product.status == 'pending_approval')
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.orange[50], 
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.orange.withOpacity(0.3))
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.hourglass_empty, color: Colors.orange, size: 30),
                          SizedBox(height: 8),
                          Text('PENDING ADMIN APPROVAL', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                  // Chat Button (Always available to interact with donor)
                  SizedBox(
                    width: double.infinity,
                    child: SecondaryButton(
                        onPressed: () async {
                          // Removed hard membership gating. Free users can now chat with limits.
                          String? chatUserId = widget.product.donorId;
                          String userName = 'Donor';

                          // If donor is missing or null, route to Admin
                          if (chatUserId.isEmpty) {
                             final adminId = await SupabaseAuthService().getAdminId();
                             if (adminId != null) {
                               chatUserId = adminId;
                               userName = 'Admin';
                             } else {
                               if (mounted) {
                                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Support is currently unavailable.')));
                               }
                               return;
                             }
                          }

                          if (!mounted) return;
                          
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ChatDetailScreen(
                              otherUserId: chatUserId!, 
                              otherUserEmail: userName,
                              donationId: widget.product.id,
                              donationTitle: widget.product.title,
                            )
                          ));
                        },
                       icon: Icons.chat_bubble_outline,
                       text: 'Chat with Donor',
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (widget.product.isAvailable)
                  Column(
                    children: [
                        if (!widget.product.isAuction)
                        SizedBox(
                          width: double.infinity,
                          child: PrimaryButton(
                            onPressed: () {
                              if (widget.product.price > 0) {
                                _handleBuy(context);
                              } else {
                                _showClaimDialog(context);
                              }
                            },
                            text: widget.product.price > 0 ? 'BUY NOW' : 'CLAIM ITEM',
                          ),
                        ),
                    ],
                  )
                  else if (widget.product.status == 'sold')
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[200], 
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.withOpacity(0.3))
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle, color: Colors.grey[700], size: 30),
                          const SizedBox(height: 8),
                          Text('THIS ITEM HAS BEEN SOLD', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red[50], 
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.red.withOpacity(0.3))
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.lock_clock, color: Colors.red, size: 30),
                          SizedBox(height: 8),
                          Text('THIS ITEM HAS BEEN CLAIMED', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuctionStream(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Provider.of<AuctionProvider>(context, listen: false).getAuctionStream(widget.product.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final auctionData = snapshot.data!.first;
        final auctionId = auctionData['id'];
        final currentPrice = (auctionData['current_price'] as num).toDouble();
        final endTime = DateTime.parse(auctionData['end_time']).toLocal();
        final status = auctionData['status'];
        
        final isEnded = status != 'active' || DateTime.now().isAfter(endTime);
        final Duration remaining = isEnded ? Duration.zero : endTime.difference(DateTime.now());

        if (status == 'active' && DateTime.now().isAfter(endTime)) {
          // Trigger lazy finalization for expired auctions
          WidgetsBinding.instance.addPostFrameCallback((_) {
             Provider.of<AuctionProvider>(context, listen: false).checkAndFinalizeAuction(auctionId);
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Current Bid', style: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.bold)),
                          Text('₹${currentPrice.toStringAsFixed(0)}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.orange[900])),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(isEnded ? 'Auction Ended' : 'Ends In', style: TextStyle(color: Colors.red[900], fontWeight: FontWeight.bold)),
                          Text(
                            isEnded ? 'Closed' : '${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m', 
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red[700])
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (!isEnded) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        onPressed: () => _showBidDialog(context, auctionId, currentPrice),
                        icon: Icons.gavel,
                        text: 'PLACE BID (Min ₹${currentPrice + 50})',
                      ),
                    ),
                  ] else if (auctionData['winner_id'] != null && Provider.of<AuthProvider>(context, listen: false).user?.id == auctionData['winner_id']) ...[
                     const SizedBox(height: 20),
                     SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        onPressed: () => _handleBuy(context, overridePrice: currentPrice),
                        icon: Icons.payment,
                        text: 'PAY NOW FOR ITEM',
                      ),
                    ),
                  ]
                ],
              ),
            ),
            _buildBidsList(auctionId),
          ],
        );
      },
    );
  }

  Widget _buildBidsList(String auctionId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Provider.of<AuctionProvider>(context, listen: false).getBidsStream(auctionId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.only(top: 8.0, bottom: 20),
            child: Text('No bids yet. Be the first!', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
          );
        }
        
        final bids = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Bids (${bids.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bids.length > 5 ? 5 : bids.length,
              itemBuilder: (ctx, i) {
                final bid = bids[i];
                final amt = (bid['bid_amount'] as num).toDouble();
                final time = DateTime.parse(bid['created_at']).toLocal();
                
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(backgroundColor: Colors.grey[200], child: const Icon(Icons.person, color: Colors.grey)),
                  title: Text('₹${amt.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700])),
                  subtitle: Text('${time.hour}:${time.minute.toString().padLeft(2, '0')} - Bidder ${bid['bidder_id'].toString().substring(0, 4)}'),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }

  void _showBidDialog(BuildContext context, String auctionId, double currentPrice) {
    final TextEditingController bidController = TextEditingController();
    final double minBid = currentPrice + 50;
    bidController.text = minBid.toStringAsFixed(0);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Place Your Bid'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Minimum next bid: ₹$minBid'),
            const SizedBox(height: 16),
            TextField(
              controller: bidController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Bid Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(bidController.text);
              if (val == null || val < minBid) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bid must be at least ₹$minBid')));
                return;
              }
              Navigator.pop(ctx);
              final user = Provider.of<AuthProvider>(context, listen: false).user;
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login')));
                return;
              }
              try {
                await Provider.of<AuctionProvider>(context, listen: false).placeBid(
                  auctionId: auctionId,
                  bidderId: user.id,
                  bidAmount: val,
                  minimumIncrement: 50.0,
                );
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bid placed successfully!'), backgroundColor: Colors.green));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
            child: const Text('Confirm Bid'),
          ),
        ],
      ),
    );
  }

  void _showPremiumDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.amber[50], shape: BoxShape.circle),
              child: const Icon(Icons.stars_rounded, color: Colors.amber, size: 40),
            ),
            const SizedBox(height: 20),
            const Text(
              'Premium Only Feature',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            Text(
              'Direct chat with donors is exclusive to Premium Members. Upgrade now to start saving lives.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const MembershipScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                  shadowColor: Colors.indigo.withOpacity(0.3),
                ),
                child: const Text('UPGRADE TO PREMIUM', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Maybe Later', style: TextStyle(color: Colors.grey)),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showClaimDialog(BuildContext context) {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please login')));
      return;
    }

    final nameController = TextEditingController(text: user.fullName);
    final phoneController = TextEditingController(text: user.phone ?? '');
    final reasonController = TextEditingController();
    final timeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
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
                  const Text('Claim Item', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
               TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
               TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Pickup Reason (Optional)', border: OutlineInputBorder()),
              ),
               const SizedBox(height: 12),
               TextField(
                controller: timeController,
                decoration: const InputDecoration(labelText: 'Pickup Time Preference (e.g. 5-7 PM)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty || phoneController.text.isEmpty || timeController.text.isEmpty) {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields.')));
                       return;
                    }

                    Navigator.pop(ctx);
                    try {
                      await SupabaseClaimService().submitClaim(
                        itemId: widget.product.id,
                        userId: user.id,
                        name: nameController.text,
                        phone: phoneController.text,
                        pickupReason: reasonController.text.isNotEmpty ? reasonController.text : null,
                        pickupTimePreference: timeController.text,
                      );
                      // Update UI state
                      Provider.of<ProductProvider>(context, listen: false).updateProductStatus(widget.product.id, 'pending_approval');
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Claim request submitted successfully!'), backgroundColor: Colors.green));
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
                    }
                  },
                  icon: Icons.check_circle_outline,
                  text: 'Submit Claim Request',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge() {
    if (widget.product.status == 'sold') {
      return ItemBadge.sold();
    } else if (widget.product.isAuction) {
      return ItemBadge.auction();
    } else if (widget.product.price > 0) {
      return ItemBadge.forSale();
    } else {
      return ItemBadge.donation();
    }
  }
}
