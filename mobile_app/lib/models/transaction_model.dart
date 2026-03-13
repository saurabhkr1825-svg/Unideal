class TransactionModel {
  final String id;
  final String userId;
  final String? donationId;
  final double amount;
  final String type; // membership, auction, donation_request
  final String paymentRef;
  final String? utrNumber;
  final String status; // pending, completed, failed
  final String? otp;
  final String? sellerId;
  final Map<String, dynamic>? sellerPaymentDetails;
  final String escrowStatus; // pending, held, completed, refunded
  final DateTime createdAt;
  final String? userName; // Join from profiles
  final String? itemTitle; // Join from donations
  final bool otpVerified;
  final String? sellerPaymentMethod;
  final String? sellerUpi;
  final String? sellerPhone;

  TransactionModel({
    required this.id,
    required this.userId,
    this.donationId,
    required this.amount,
    required this.type,
    required this.paymentRef,
    this.utrNumber,
    required this.status,
    this.otp,
    this.sellerId,
    this.sellerPaymentDetails,
    this.escrowStatus = 'pending',
    required this.createdAt,
    this.userName,
    this.itemTitle,
    this.otpVerified = false,
    this.sellerPaymentMethod,
    this.sellerUpi,
    this.sellerPhone,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      donationId: json['donation_id'],
      amount: (json['amount'] ?? 0).toDouble(),
      type: json['type'] ?? 'donation_request',
      paymentRef: json['payment_ref'] ?? '',
      utrNumber: json['utr_number'],
      status: json['status'] ?? 'pending',
      otp: json['otp'],
      sellerId: json['seller_id'],
      sellerPaymentDetails: json['seller_payment_details'],
      escrowStatus: json['escrow_status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      userName: json['profiles'] != null ? json['profiles']['full_name'] : null,
      itemTitle: json['donations'] != null ? json['donations']['title'] : null,
      otpVerified: json['otp_verified'] ?? false,
      sellerPaymentMethod: json['seller_payment_method'],
      sellerUpi: json['seller_upi'],
      sellerPhone: json['seller_phone'],
    );
  }
}
