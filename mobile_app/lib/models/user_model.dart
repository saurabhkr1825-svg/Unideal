class User {
  final String id;
  final String userId;
  final String email;
  final String role;
  final int walletBalance;

  User({
    required this.id,
    required this.userId,
    required this.email,
    required this.role,
    this.walletBalance = 0,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      walletBalance: json['walletBalance'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'email': email,
      'role': role,
      'walletBalance': walletBalance,
    };
  }
}
