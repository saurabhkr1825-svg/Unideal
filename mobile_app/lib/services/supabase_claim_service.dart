import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/claim_request_model.dart';
import 'supabase_notification_service.dart';

class SupabaseClaimService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> submitClaim({
    required String itemId,
    required String userId,
    required String name,
    required String phone,
    String? pickupReason,
    required String pickupTimePreference,
  }) async {
    try {
      // 1. Insert claim
      await _client.from('claim_requests').insert({
        'item_id': itemId,
        'user_id': userId,
        'name': name,
        'phone': phone,
        'pickup_reason': pickupReason,
        'pickup_time_preference': pickupTimePreference,
      });

      // 2. Mark item as pending_approval
      await _client.from('donations').update({
        'status': 'pending_approval'
      }).eq('id', itemId);

    } catch (e) {
      if (e.toString().contains('duplicate key')) {
         throw Exception('You have already submitted a claim for this item.');
      }
      throw Exception('Failed to submit claim: $e');
    }
  }

  Future<List<ClaimRequest>> getPendingClaimsForDonor(String donorId) async {
    try {
      final List<dynamic> response = await _client
          .from('claim_requests')
          .select('*, donations!inner(title, image_url, donor_id)')
          .eq('status', 'pending_approval')
          .eq('donations.donor_id', donorId)
          .order('created_at', ascending: false);

      return response.map((json) => ClaimRequest.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch claims: $e');
    }
  }

  Future<List<ClaimRequest>> getPendingClaimsForAdmin() async {
    try {
      final List<dynamic> response = await _client
          .from('claim_requests')
          .select('*, donations!inner(title, image_url, donor_id)')
          .eq('status', 'pending_approval')
          .order('created_at', ascending: false);

      return response.map((json) => ClaimRequest.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch claims: $e');
    }
  }

  Future<void> approveClaim(String claimId, String itemId) async {
    try {
      // 0. Fetch the claim and the donation details
      final claimRes = await _client.from('claim_requests').select('*, donations!inner(donor_id, title)').eq('id', claimId).single();
      final donorId = claimRes['donations']['donor_id'];
      final itemTitle = claimRes['donations']['title'];
      final userId = claimRes['user_id'];

      // 1. Approve chosen claim
      await _client
          .from('claim_requests')
          .update({'status': 'approved'})
          .eq('id', claimId);

      // 2. Reject all other claims for same item
      await _client
          .from('claim_requests')
          .update({'status': 'rejected'})
          .eq('item_id', itemId)
          .neq('id', claimId);

      // 3. Update donation status
      await _client
          .from('donations')
          .update({
            'status': 'reserved', 
            'is_available': false
          })
          .eq('id', itemId);

      // 4. Create a transaction for tracking OTP and Delivery
      final randomOtp = DateTime.now().millisecondsSinceEpoch % 1000000;
      final otpString = randomOtp.toString().padLeft(6, '0');

      await _client.from('transactions').insert({
        'user_id': userId,
        'donation_id': itemId,
        'amount': 0, // Free claim
        'type': 'donation_request',
        'payment_ref': 'CLAIM_APPROVED_${DateTime.now().millisecondsSinceEpoch}',
        'seller_id': donorId,
        'status': 'pending', // Bypasses payment_verifying since it's free
        'otp': otpString,
        'escrow_status': 'verified', 
      });

      // 5. Notify the user
      await SupabaseNotificationService().createNotification(
        userId: userId,
        title: 'Claim Approved',
        message: 'Your claim for "$itemTitle" was approved! Check My Orders for your pickup OTP.',
        type: 'bid'
      );

    } catch (e) {
      throw Exception('Failed to approve claim: $e');
    }
  }

  Future<void> rejectClaim(String claimId) async {
    try {
      await _client
          .from('claim_requests')
          .update({'status': 'rejected'})
          .eq('id', claimId);

      // Check if there are any other pending claims. If none, revert product to available.
      // Easiest handled by admin panel logic or trigger, 
      // but let's do a quick check here for robustness if needed, 
      // or rely on AdminPanel explicitly marking it pending if claims.
    } catch (e) {
      throw Exception('Failed to reject claim: $e');
    }
  }
}
