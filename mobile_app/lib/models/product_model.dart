class Product {
  final String id;
  final String name;
  final String description;
  final String category;
  final String condition;
  final double price;
  final double rentPrice;
  final bool allowBuy;
  final bool allowRent;
  final bool allowDonate;
  final bool allowAuction;
  final List<String> images;
  final String video;
  final String status;
  final String sellerId;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.condition,
    required this.price,
    required this.rentPrice,
    required this.allowBuy,
    required this.allowRent,
    required this.allowDonate,
    required this.allowAuction,
    required this.images,
    required this.video,
    required this.status,
    required this.sellerId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      condition: json['condition'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      rentPrice: (json['rentPrice'] ?? 0).toDouble(),
      allowBuy: json['allowBuy'] ?? false,
      allowRent: json['allowRent'] ?? false,
      allowDonate: json['allowDonate'] ?? false,
      allowAuction: json['allowAuction'] ?? false,
      images: List<String>.from(json['images'] ?? []),
      video: json['video'] ?? '',
      status: json['status'] ?? 'pending',
      sellerId: json['seller'] is Map ? json['seller']['_id'] : (json['seller'] ?? ''),
    );
  }
}
