import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/product_model.dart';
import '../utils/app_theme.dart';
import 'custom_card.dart';
import 'item_badge.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({
    Key? key,
    required this.product,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClickableStandardCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: product.imageUrl != null
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image),
                        ),
                      )
                    : Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.image),
                      ),
              ),
              Positioned(
                top: AppTheme.spacingSm,
                left: AppTheme.spacingSm,
                child: _buildBadge(),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: AppTheme.bodyStyle.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  product.category,
                  style: AppTheme.smallInfoStyle.copyWith(color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product.price > 0 ? '₹${product.price.toStringAsFixed(0)}' : 'FREE',
                      style: AppTheme.priceStyle.copyWith(
                        color: product.price > 0 ? AppTheme.textPrimaryColor : AppTheme.primaryColor,
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.textSecondaryColor),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad);
  }

  Widget _buildBadge() {
    if (product.status == 'sold') {
      return ItemBadge.sold();
    } else if (product.status == 'pending_approval') {
      return ItemBadge.pendingClaim();
    } else if (!product.isAvailable) {
       return ItemBadge.claimed();
    } else if (product.isAuction) {
      return ItemBadge.auction();
    } else if (product.price > 0) {
      return ItemBadge.forSale();
    } else {
      return ItemBadge.available();
    }
  }
}
