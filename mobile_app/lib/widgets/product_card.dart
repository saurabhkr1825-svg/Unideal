import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/product_model.dart';
import '../utils/app_theme.dart';
import 'custom_card.dart';
import 'item_badge.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({
    Key? key,
    required this.product,
    required this.onTap,
  }) : super(key: key);

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: 200.ms,
        transform: _isHovered ? Matrix4.translationValues(0, -8, 0) : Matrix4.identity(),
        child: ClickableStandardCard(
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: widget.product.imageUrl != null
                        ? Image.network(
                            widget.product.imageUrl!,
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
                  if (_isHovered)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.4),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildHoverAction(Icons.visibility),
                              const SizedBox(width: 8),
                              _buildHoverAction(Icons.favorite_border),
                              const SizedBox(width: 8),
                              _buildHoverAction(Icons.shopping_cart_outlined),
                            ],
                          ).animate().fadeIn(duration: 200.ms).scale(begin: const Offset(0.8, 0.8)),
                        ),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.title,
                      style: AppTheme.bodyStyle.copyWith(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      widget.product.category,
                      style: AppTheme.smallInfoStyle.copyWith(
                        color: AppTheme.primaryColor, 
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.product.price > 0 ? '₹${widget.product.price.toStringAsFixed(0)}' : 'FREE',
                          style: AppTheme.priceStyle.copyWith(
                            color: widget.product.price > 0 ? AppTheme.textPrimaryColor : AppTheme.primaryColor,
                            fontSize: 14,
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
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }

  Widget _buildHoverAction(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: Colors.black87),
    );
  }

  Widget _buildBadge() {
    if (widget.product.status == 'sold') {
      return ItemBadge.sold();
    } else if (widget.product.status == 'pending_approval') {
      return ItemBadge.pendingClaim();
    } else if (!widget.product.isAvailable) {
       return ItemBadge.claimed();
    } else if (widget.product.isAuction) {
      return ItemBadge.auction();
    } else if (widget.product.price > 0) {
      return ItemBadge.forSale();
    } else {
      return ItemBadge.available();
    }
  }
}
