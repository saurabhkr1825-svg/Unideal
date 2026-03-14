class User {
  final String id;
  final String uniqueCode;
  final String fullName;
  final String? phone;
  final String email;
  final String role;
  final bool membershipStatus;
  final DateTime? membershipExpiry;
  final int claimScore;

  User({
    required this.id,
    required this.uniqueCode,
    required this.fullName,
    this.phone,
    required this.email,
    required this.role,
    this.membershipStatus = false,
    this.membershipExpiry,
    this.claimScore = 5,
  });

  factory User.fromJson(Map<String, dynamic> json, String email) {
    return User(
      id: json['id'] ?? '',
      uniqueCode: json['unique_code'] ?? '',
      fullName: json['full_name'] ?? '',
      phone: json['phone'],
      email: email,
      role: json['role'] ?? 'user',
      membershipStatus: json['membership_status'] ?? false,
      membershipExpiry: json['membership_expiry'] != null 
          ? DateTime.parse(json['membership_expiry']) 
          : null,
      claimScore: json['claim_score'] ?? 5,
    );
  }
}
