class PurchaseRequest {
  final String id;
  final String productId;
  final String productTitle;
  final String? productImageUrl;
  final String buyerId;
  final String? buyerName;
  final String sellerId;
  final String hostelName;
  final String roomNo;
  final String meetingPoint;
  final String? phone;
  final String status; // pending, accepted, rejected
  final DateTime createdAt;

  PurchaseRequest({
    required this.id,
    required this.productId,
    required this.productTitle,
    this.productImageUrl,
    required this.buyerId,
    this.buyerName,
    required this.sellerId,
    required this.hostelName,
    required this.roomNo,
    required this.meetingPoint,
    this.phone,
    this.status = 'pending',
    required this.createdAt,
  });

  factory PurchaseRequest.fromJson(Map<String, dynamic> json) {
    // Check for nested structure if using JOINs
    final product = json['donations'] ?? {};
    final buyer = json['profiles_buyer'] ?? {};

    return PurchaseRequest(
      id: json['id'],
      productId: json['product_id'],
      productTitle: product['title'] ?? 'Unknown Item',
      productImageUrl: product['image_url'],
      buyerId: json['buyer_id'],
      buyerName: buyer['full_name'],
      sellerId: json['seller_id'],
      hostelName: json['hostel_name'],
      roomNo: json['room_no'],
      meetingPoint: json['meeting_point'],
      phone: json['phone'],
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
