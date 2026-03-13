import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/product_model.dart';
import '../providers/auction_provider.dart';
import '../screens/product_detail_screen.dart';
import '../utils/app_theme.dart';
import 'item_badge.dart';

class LiveAuctionCard extends StatelessWidget {
  final Product product;
  const LiveAuctionCard({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Provider.of<AuctionProvider>(context, listen: false).getAuctionStream(product.id),
      builder: (context, snapshot) {
         if (!snapshot.hasData || snapshot.data!.isEmpty) {
           return SizedBox(
             width: 160, 
             child: Card(
               margin: const EdgeInsets.only(right: AppTheme.spacingMd, bottom: AppTheme.spacingSm), 
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusM)),
               child: const Center(child: CircularProgressIndicator())
             )
           );
         }
         final auctionRaw = snapshot.data!.first;
         final currentPrice = (auctionRaw['current_price'] as num).toDouble();
         final endTime = DateTime.parse(auctionRaw['end_time']).toLocal();
         final isEnded = auctionRaw['status'] != 'active' || DateTime.now().isAfter(endTime);
         final Duration remaining = isEnded ? Duration.zero : endTime.difference(DateTime.now());
         
         if (isEnded) return const SizedBox.shrink();
         
         return GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product))),
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: AppTheme.spacingMd, bottom: AppTheme.spacingSm),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor,
                borderRadius: BorderRadius.circular(AppTheme.radiusM),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Stack(
                     children: [
                       ClipRRect(
                         borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusM)),
                         child: product.imageUrl != null 
                            ? Image.network(product.imageUrl!, height: 110, width: 160, fit: BoxFit.cover)
                            : Container(height: 110, width: 160, color: Colors.indigo[50], child: Icon(Icons.image_not_supported, color: Colors.indigo[200])),
                       ),
                       Positioned(
                         top: AppTheme.spacingSm, left: AppTheme.spacingSm,
                         child: ItemBadge.auction(),
                       )
                     ],
                   ),
                   Padding(
                     padding: const EdgeInsets.all(AppTheme.spacingMd),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(product.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTheme.bodyStyle.copyWith(fontWeight: FontWeight.bold)),
                         const SizedBox(height: AppTheme.spacingXs),
                         Text('Bid: ₹${currentPrice.toStringAsFixed(0)}', style: AppTheme.smallInfoStyle.copyWith(color: Colors.purple, fontWeight: FontWeight.bold)),
                         const SizedBox(height: AppTheme.spacingXs),
                         Row(
                           children: [
                             Icon(Icons.timer, size: 12, color: Colors.red[700]),
                             const SizedBox(width: AppTheme.spacingXs),
                             Text('${remaining.inHours}h ${remaining.inMinutes.remainder(60)}m left', style: AppTheme.smallInfoStyle.copyWith(color: Colors.red[700], fontWeight: FontWeight.bold)),
                           ],
                         ),
                       ]
                     )
                   )
                ]
              )
            ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1), duration: 500.ms, curve: Curves.easeOutBack),
         );
      }
    );
  }
}
