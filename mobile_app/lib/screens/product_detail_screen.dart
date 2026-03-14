import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import 'payment_screen.dart';
import 'chat_detail_screen.dart';
import 'membership_screen.dart';
import '../services/supabase_auth_service.dart';
import '../providers/auction_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_buttons.dart';
import '../widgets/item_badge.dart';
import '../services/supabase_claim_service.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please login to continue')));
      return;
    }

    try {
      // For donations, we update availability after successful payment intent
      // For now, we navigate to payment
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaymentScreen(product: widget.product, type: 'buy', finalPriceOverride: overridePrice),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll('Exception: ', '')),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.product.title, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
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
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: Offset(0, 5))
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                  child: widget.product.imageUrl != null
                      ? Image.network(
                          widget.product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, _) => Container(
                            color: Colors.grey[100], 
                            child: Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey))
                          ),
                        )
                      : Container(
                          color: Colors.grey[100],
                          child: Center(child: Icon(Icons.image_not_supported, size: 60, color: Colors.grey)),
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
                        style: TextStyle(color: Colors.indigo, fontStyle: FontStyle.italic),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.title,
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
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
                  SizedBox(height: 10),
                  Text(
                    widget.product.description,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5),
                  ),
                  SizedBox(height: 24),
                  
                  if (widget.product.isAuction)
                    _buildAuctionStream(context),
                  
                  // Action Section
                  if (widget.product.status == 'pending_approval')
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.orange[50], 
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.orange.withOpacity(0.3))
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.hourglass_empty, color: Colors.orange, size: 30),
                          SizedBox(height: 8),
                          Text('PENDING ADMIN APPROVAL', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    )
                  else if (widget.product.isAvailable)
                  Column(
                    children: [
                       SizedBox(
                         width: double.infinity,
                         child: SecondaryButton(
                             onPressed: () async {
                               // Removed hard membership gating. Free users can now chat with limits.
                               String? chatUserId = widget.product.donorId;
                               String userName = 'Donor';

                               // If donor is missing or null, route to Admin
                               if (chatUserId == null || chatUserId.isEmpty) {
                                  final adminId = await SupabaseAuthService().getAdminId();
                                  if (adminId != null) {
                                    chatUserId = adminId;
                                    userName = 'Admin';
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Support is currently unavailable.')));
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
                        SizedBox(height: 12),
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
                  else
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red[50], 
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.red.withOpacity(0.3))
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.lock_clock, color: Colors.red, size: 30),
                          SizedBox(height: 8),
                          Text('THIS ITEM HAS BEEN CLAIMED', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                  
                  SizedBox(height: 30),
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
          return Center(child: CircularProgressIndicator());
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
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.symmetric(vertical: 16),
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
                    SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        onPressed: () => _showBidDialog(context, auctionId, currentPrice),
                        icon: Icons.gavel,
                        text: 'PLACE BID (Min ₹${currentPrice + 50})',
                      ),
                    ),
                  ] else if (auctionData['winner_id'] != null && Provider.of<AuthProvider>(context, listen: false).user?.id == auctionData['winner_id']) ...[
                     SizedBox(height: 20),
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
          return Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 20),
            child: Text('No bids yet. Be the first!', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
          );
        }
        
        final bids = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Recent Bids (${bids.length})', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: bids.length > 5 ? 5 : bids.length,
              itemBuilder: (ctx, i) {
                final bid = bids[i];
                final amt = (bid['bid_amount'] as num).toDouble();
                final time = DateTime.parse(bid['created_at']).toLocal();
                
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(backgroundColor: Colors.grey[200], child: Icon(Icons.person, color: Colors.grey)),
                  title: Text('₹${amt.toStringAsFixed(0)}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[700])),
                  subtitle: Text('${time.hour}:${time.minute.toString().padLeft(2, '0')} - Bidder ${bid['bidder_id'].toString().substring(0, 4)}'),
                );
              },
            ),
            SizedBox(height: 20),
          ],
        );
      },
    );
  }

  void _showBidDialog(BuildContext context, String auctionId, double currentPrice) {
    final TextEditingController _bidController = TextEditingController();
    final double minBid = currentPrice + 50;
    _bidController.text = minBid.toStringAsFixed(0);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Place Your Bid'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Minimum next bid: ₹$minBid'),
            SizedBox(height: 16),
            TextField(
              controller: _bidController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Bid Amount',
                prefixText: '₹ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(_bidController.text);
              if (val == null || val < minBid) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bid must be at least ₹$minBid')));
                return;
              }
              Navigator.pop(ctx);
              final user = Provider.of<AuthProvider>(context, listen: false).user;
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please login')));
                return;
              }
              try {
                await Provider.of<AuctionProvider>(context, listen: false).placeBid(
                  auctionId: auctionId,
                  bidderId: user.id,
                  bidAmount: val,
                  minimumIncrement: 50.0,
                );
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bid placed successfully!'), backgroundColor: Colors.green));
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
              }
            },
            child: Text('Confirm Bid'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
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
        padding: EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.amber[50], shape: BoxShape.circle),
              child: Icon(Icons.stars_rounded, color: Colors.amber, size: 40),
            ),
            SizedBox(height: 20),
            Text(
              'Premium Only Feature',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            SizedBox(height: 12),
            Text(
              'Direct chat with donors is exclusive to Premium Members. Upgrade now to start saving lives.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 15, height: 1.4),
            ),
            SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => MembershipScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                  shadowColor: Colors.indigo.withOpacity(0.3),
                ),
                child: Text('UPGRADE TO PREMIUM', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
              ),
            ),
            SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Maybe Later', style: TextStyle(color: Colors.grey)),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showClaimDialog(BuildContext context) {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please login')));
      return;
    }

    final _nameController = TextEditingController(text: user.fullName);
    final _phoneController = TextEditingController(text: user.phone ?? '');
    final _reasonController = TextEditingController();
    final _timeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
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
                  Text('Claim Item', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  IconButton(icon: Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              ),
              SizedBox(height: 12),
               TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder()),
              ),
              SizedBox(height: 12),
               TextField(
                controller: _reasonController,
                maxLines: 2,
                decoration: InputDecoration(labelText: 'Pickup Reason (Optional)', border: OutlineInputBorder()),
              ),
               SizedBox(height: 12),
               TextField(
                controller: _timeController,
                decoration: InputDecoration(labelText: 'Pickup Time Preference (e.g. 5-7 PM)', border: OutlineInputBorder()),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  onPressed: () async {
                    if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _timeController.text.isEmpty) {
                       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please fill all required fields.')));
                       return;
                    }

                    Navigator.pop(ctx);
                    try {
                      await SupabaseClaimService().submitClaim(
                        itemId: widget.product.id,
                        userId: user.id,
                        name: _nameController.text,
                        phone: _phoneController.text,
                        pickupReason: _reasonController.text.isNotEmpty ? _reasonController.text : null,
                        pickupTimePreference: _timeController.text,
                      );
                      // Update UI state
                      Provider.of<ProductProvider>(context, listen: false).updateProductStatus(widget.product.id, 'pending_approval');
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Claim request submitted successfully!'), backgroundColor: Colors.green));
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
    if (widget.product.isAuction) {
      return ItemBadge.auction();
    } else if (widget.product.price > 0) {
      return ItemBadge.forSale();
    } else {
      return ItemBadge.donation();
    }
  }
}
