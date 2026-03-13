class Auction {
  final String id;
  final String itemId;
  final String sellerId;
  final double startingPrice;
  final double currentPrice;
  final DateTime endTime;
  final String status;
  final String? winnerId;
  final DateTime createdAt;

  Auction({
    required this.id,
    required this.itemId,
    required this.sellerId,
    required this.startingPrice,
    required this.currentPrice,
    required this.endTime,
    required this.status,
    this.winnerId,
    required this.createdAt,
  });

  factory Auction.fromJson(Map<String, dynamic> json) {
    return Auction(
      id: json['id']?.toString() ?? '',
      itemId: json['item_id']?.toString() ?? '',
      sellerId: json['seller_id']?.toString() ?? '',
      startingPrice: (json['starting_price'] ?? 0).toDouble(),
      currentPrice: (json['current_price'] ?? 0).toDouble(),
      endTime: DateTime.parse(json['end_time']),
      status: json['status'] ?? 'active',
      winnerId: json['winner_id']?.toString(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class Bid {
  final String id;
  final String auctionId;
  final String bidderId;
  final double bidAmount;
  final DateTime createdAt;

  Bid({
    required this.id,
    required this.auctionId,
    required this.bidderId,
    required this.bidAmount,
    required this.createdAt,
  });

  factory Bid.fromJson(Map<String, dynamic> json) {
    return Bid(
      id: json['id']?.toString() ?? '',
      auctionId: json['auction_id']?.toString() ?? '',
      bidderId: json['bidder_id']?.toString() ?? '',
      bidAmount: (json['bid_amount'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
