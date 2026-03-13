import 'package:intl/intl.dart';

class MembershipRequest {
  final String id;
  final String userId;
  final String planName;
  final double amount;
  final String? transactionId;
  final String? utrNumber;
  final String? screenshotUrl;
  final String status;
  final DateTime createdAt;

  MembershipRequest({
    required this.id,
    required this.userId,
    required this.planName,
    required this.amount,
    this.transactionId,
    this.utrNumber,
    this.screenshotUrl,
    required this.status,
    required this.createdAt,
  });

  factory MembershipRequest.fromJson(Map<String, dynamic> json) {
    return MembershipRequest(
      id: json['id'],
      userId: json['user_id'],
      planName: json['plan_name'] ?? 'Premium Monthly',
      amount: (json['amount'] ?? 0.0).toDouble(),
      transactionId: json['transaction_id'],
      utrNumber: json['utr_number'],
      screenshotUrl: json['screenshot_url'],
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  String get formattedDate => DateFormat('dd MMM yyyy, hh:mm a').format(createdAt);
  
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}
