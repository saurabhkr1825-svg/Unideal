import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction_model.dart';
import 'supabase_notification_service.dart';

class SupabaseTransactionService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<TransactionModel> createTransaction({
    required String userId,
    String? donationId,
    required double amount,
    required String type, // DB compliant: membership, auction, donation_request
    required String paymentRef,
    String? utrNumber,
    String? sellerId,
  }) async {
    try {
      final response = await _client.from('transactions').insert({
        'user_id': userId,
        'donation_id': donationId,
        'amount': amount,
        'type': type,
        'payment_ref': paymentRef,
        'utr_number': utrNumber,
        'seller_id': sellerId,
        'status': 'payment_verifying', // Wait for admin to approve the UTR/payment proof
        'escrow_status': (donationId != null && type == 'donation_request') ? 'held' : 'pending',
      }).select().single();
      
      return TransactionModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create transaction: $e');
    }
  }

  Future<bool> verifyOTP(String transactionId, String otp) async {
    try {
      final response = await _client
          .from('transactions')
          .select('otp, user_id, donations(title)')
          .eq('id', transactionId)
          .single();
      
      if (response['otp'] == otp) {
        // Mark OTP as verified instead of completed
        await _client.from('transactions').update({
          'otp_verified': true,
        }).eq('id', transactionId);

        // Notify Buyer
        final itemName = response['donations'] != null ? response['donations']['title'] : 'your item';
        await SupabaseNotificationService().createNotification(
          userId: response['user_id'],
          title: 'Delivery Confirmed',
          message: 'Delivery of "$itemName" has been confirmed. Thank you for using Unideal!',
          type: 'bid',
        );
        
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('OTP verification failed: $e');
    }
  }

  Future<void> updateSellerPaymentDetails(String transactionId, String paymentMethod, {String? upi, String? phone}) async {
    try {
      await _client.from('transactions').update({
        'seller_payment_method': paymentMethod,
        'seller_upi': upi,
        'seller_phone': phone,
        'status': 'waiting_admin_approval'
      }).eq('id', transactionId);
    } catch (e) {
      throw Exception('Failed to update seller payment details: $e');
    }
  }

  Future<List<TransactionModel>> getMyTransactions(String userId) async {
    try {
      final List<dynamic> response = await _client
          .from('transactions')
          .select()
          .or('user_id.eq.$userId,seller_id.eq.$userId')
          .order('created_at', ascending: false);
      
      return response.map((item) => TransactionModel.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to fetch transactions: $e');
    }
  }

  // Admin Methods
  Future<List<TransactionModel>> getAllPendingTransactions() async {
    try {
      final List<dynamic> response = await _client
          .from('transactions')
          .select('*, profiles(full_name), donations(title)')
          .eq('status', 'payment_verifying')
          .order('created_at', ascending: true);
      
      return response.map((item) => TransactionModel.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to fetch pending transactions: $e');
    }
  }

  Future<List<TransactionModel>> getFundReleaseRequests() async {
    try {
      final List<dynamic> response = await _client
          .from('transactions')
          .select('*, profiles(full_name), donations(title)')
          .eq('status', 'waiting_admin_approval')
          .order('created_at', ascending: true);
      
      return response.map((item) => TransactionModel.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to fetch fund release requests: $e');
    }
  }

  Future<void> releaseFunds(String transactionId, String sellerId, String title) async {
    await updateTransactionStatus(transactionId, 'completed', sellerId, title, isSellerNotification: true);
  }

  Future<void> rejectFunds(String transactionId, String sellerId, String title) async {
    await updateTransactionStatus(transactionId, 'rejected', sellerId, title, isSellerNotification: true);
  }

  Future<void> updateTransactionStatus(String transactionId, String status, String userId, String title, {bool isSellerNotification = false}) async {
    try {
      // 1. Update status
      await _client.from('transactions').update({
        'status': status,
        'escrow_status': status == 'completed' ? 'held' : (status == 'pending' ? 'verified' : 'refunded'),
      }).eq('id', transactionId);

      // 2. Create Notification for the user
      String notifTitle = 'Payment Update';
      String notifMsg = 'Your payment status was updated.';
      
      if (status == 'completed') {
        notifTitle = isSellerNotification ? 'Funds Released' : 'Transaction Completed';
        notifMsg = isSellerNotification ? 'Your funds for "$title" have been successfully released by the admin.' : 'Your transaction for "$title" is fully complete.';
      } else if (status == 'pending') {
        notifTitle = 'Payment Verified';
        notifMsg = 'Your payment for "$title" has been verified. Your delivery OTP is now visible in My Orders.';
      } else if (status == 'rejected' || status == 'failed') {
        notifTitle = 'Payment Rejected';
        notifMsg = 'Your payment for "$title" was rejected by admin. Please contact support.';
      }

      await SupabaseNotificationService().createNotification(
        userId: userId,
        title: notifTitle,
        message: notifMsg,
        type: 'bid',
      );
    } catch (e) {
      throw Exception('Failed to update transaction status: $e');
    }
  }

  Future<void> updateEscrowStatus(String transactionId, String status) async {
    try {
      await _client.from('transactions').update({
        'escrow_status': status
      }).eq('id', transactionId);
    } catch (e) {
      throw Exception('Failed to update escrow status: $e');
    }
  }

  Future<List<TransactionModel>> getEscrowTransactions() async {
    try {
      final List<dynamic> response = await _client
          .from('transactions')
          .select('*, profiles(full_name), donations(title)')
          .inFilter('escrow_status', ['held', 'completed'])
          .order('created_at', ascending: false);
      
      return response.map((item) => TransactionModel.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to fetch escrow transactions: $e');
    }
  }
}
