import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class ItemBadge extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;

  const ItemBadge({
    Key? key,
    required this.text,
    required this.color,
    this.textColor = Colors.white,
  }) : super(key: key);

  factory ItemBadge.auction() => const ItemBadge(text: "AUCTION", color: AppTheme.auctionColor);
  factory ItemBadge.donation() => const ItemBadge(text: "DONATION", color: AppTheme.primaryColor);
  factory ItemBadge.forSale() => const ItemBadge(text: "FOR SALE", color: AppTheme.forSaleColor);
  factory ItemBadge.sold() => const ItemBadge(text: "SOLD", color: Colors.grey);
  
  factory ItemBadge.available() => const ItemBadge(text: "🟢 AVAILABLE", color: Colors.green);
  factory ItemBadge.pendingClaim() => const ItemBadge(text: "🟡 PENDING CLAIM", color: Colors.orange);
  factory ItemBadge.claimed() => const ItemBadge(text: "🔴 CLAIMED", color: Colors.red);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.spacingXs),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 10,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
