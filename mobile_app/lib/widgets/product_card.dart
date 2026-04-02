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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Expanded(
              child: Stack(
                children: [
                   Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: product.imageUrl != null
                            ? Image.network(
                                product.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Center(child: Icon(Icons.image, color: Colors.grey[400])),
                              )
                            : Center(child: Icon(Icons.image, color: Colors.grey[400])),
                      ),
                    ),
                  ),
                  // Floating Status Badge (Featured / Sold )
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _buildStatusBadge(),
                  ),
                ],
              ),
            ),
            // Details Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        product.price > 0 ? '₹${product.price.toStringAsFixed(0)}' : 'FREE',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: product.price > 0 ? Colors.black : AppTheme.primaryColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.condition != null && product.condition!.isNotEmpty 
                              ? product.condition! 
                              : product.category,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
    );
  }

  Widget _buildStatusBadge() {
    if (product.status == 'sold') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(12)),
        child: const Text('Sold', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      );
    } else if (product.status == 'pending_approval') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(12)),
        child: const Text('Pending', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      );
    } else if (!product.isAvailable) {
       return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
        child: const Text('Claimed', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      );
    } else if (product.isAuction) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: Colors.amber[700], borderRadius: BorderRadius.circular(12)),
        child: const Text('Featured', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      );
    } 
    return const SizedBox.shrink(); // No badge for standard available items to stay clean
  }
}
