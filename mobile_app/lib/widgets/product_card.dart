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
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: _isHovered ? Matrix4.translationValues(0, -8, 0) : Matrix4.identity(),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                blurRadius: _isHovered ? 12 : 8,
                color: Colors.black12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔹 IMAGE
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: widget.product.imageUrl != null
                            ? Image.network(
                                widget.product.imageUrl!,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(
                                  color: Colors.grey[100],
                                  child: const Icon(Icons.image, color: Colors.grey),
                                ),
                              )
                            : Container(
                                color: Colors.grey[100],
                                child: const Icon(Icons.image, color: Colors.grey),
                              ),
                      ),
                    ),

                    /// 🔹 BADGE (User's Style)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _buildBadge(),
                    ),

                    /// 🔹 HOVER OVERLAY
                    if (_isHovered)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                          ),
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
              ),

              /// 🔹 DETAILS
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Title
                    Text(
                      widget.product.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),

                    const SizedBox(height: 4),

                    /// Category
                    Text(
                      widget.product.category,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),

                    const SizedBox(height: 8),

                    /// Price
                    Text(
                      widget.product.price == 0 ? "FREE" : "₹${widget.product.price.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: widget.product.price == 0 ? Colors.green : Colors.indigo,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
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
    // Using User's badge style for the containers but keeping my status logic
    String label = "AVAILABLE";
    Color color = Colors.green;

    if (widget.product.status == 'sold') {
      label = "SOLD";
      color = Colors.red;
    } else if (widget.product.status == 'pending_approval') {
      label = "PENDING";
      color = Colors.orange;
    } else if (widget.product.isAuction) {
      label = "AUCTION";
      color = Colors.indigo;
    } else if (widget.product.price > 0) {
      label = "FOR SALE";
      color = Colors.blue;
    } else {
      label = "FREE";
      color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
