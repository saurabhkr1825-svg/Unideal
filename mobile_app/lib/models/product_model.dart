class Product {
  final String id;
  final String donorId;
  final String title;
  final String description;
  final String category;
  final String? imageUrl;
  final String condition;
  final bool isAvailable;
  final bool isAuction;
  final double price;
  final String status; // available, reserved, sold
  final DateTime createdAt;

  Product({
    required this.id,
    required this.donorId,
    required this.title,
    required this.description,
    required this.category,
    this.imageUrl,
    required this.condition,
    this.isAvailable = true,
    this.isAuction = false,
    this.price = 0.0,
    this.status = 'available',
    required this.createdAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      donorId: json['donor_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      imageUrl: json['image_url'],
      condition: json['condition'] ?? '',
      isAvailable: json['is_available'] ?? true,
      isAuction: json['is_auction'] ?? false,
      price: (json['price'] ?? 0).toDouble(),
      status: json['status'] ?? 'available',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}
