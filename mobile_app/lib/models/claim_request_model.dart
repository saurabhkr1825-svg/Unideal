class ClaimRequest {
  final String id;
  final String itemId;
  final String userId;
  final String name;
  final String phone;
  final String? pickupReason;
  final String pickupTimePreference;
  final String status; // pending_approval, approved, rejected
  final DateTime createdAt;
  
  // Joined properties from related tables
  final String? itemTitle;
  final String? itemImage;
  final String? donorId;

  ClaimRequest({
    required this.id,
    required this.itemId,
    required this.userId,
    required this.name,
    required this.phone,
    this.pickupReason,
    required this.pickupTimePreference,
    this.status = 'pending_approval',
    required this.createdAt,
    this.itemTitle,
    this.itemImage,
    this.donorId,
  });

  factory ClaimRequest.fromJson(Map<String, dynamic> json) {
    return ClaimRequest(
      id: json['id'] ?? '',
      itemId: json['item_id'] ?? '',
      userId: json['user_id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      pickupReason: json['pickup_reason'],
      pickupTimePreference: json['pickup_time_preference'] ?? '',
      status: json['status'] ?? 'pending_approval',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      itemTitle: json['donations'] != null ? json['donations']['title'] : null,
      itemImage: json['donations'] != null ? json['donations']['image_url'] : null,
      donorId: json['donations'] != null ? json['donations']['donor_id'] : null,
    );
  }
}
