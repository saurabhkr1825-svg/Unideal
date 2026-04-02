import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/membership_request_model.dart';
import 'supabase_notification_service.dart';
import '../services/supabase_storage_service.dart';

class SupabaseMembershipService {
  final SupabaseClient _client = Supabase.instance.client;
  final SupabaseStorageService _storageService = SupabaseStorageService();

  Future<void> submitMembershipRequest({
    required String planName,
    required double amount,
    required String txnId,
    String? utrNumber,
    required File screenshot,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      // 1. Upload screenshot
      final screenshotUrl = await _storageService.uploadDonationImage(screenshot);

      // 2. Insert request record
      await _client.from('membership_requests').insert({
        'user_id': userId,
        'plan_name': planName,
        'amount': amount,
        'transaction_id': txnId,
        'utr_number': utrNumber,
        'screenshot_url': screenshotUrl,
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Failed to submit membership request: $e');
    }
  }

  Future<List<MembershipRequest>> getMyMembershipRequests() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final response = await _client
          .from('membership_requests')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => MembershipRequest.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch requests: $e');
    }
  }

  // Admin Methods
  Future<List<MembershipRequest>> getAllPendingRequests() async {
    try {
      final response = await _client
          .from('membership_requests')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: true);

      return (response as List).map((json) => MembershipRequest.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch pending requests: $e');
    }
  }

  Future<void> updateRequestStatus(String requestId, String status, String userId) async {
    try {
      // 1. Update status
      await _client.from('membership_requests').update({'status': status}).eq('id', requestId);

      // 2. If approved, update user's profile to membership_status = true
      if (status == 'approved') {
        // Set expiry to 30 days from now
        final expiryDate = DateTime.now().add(const Duration(days: 30)).toIso8601String();
        
        await _client.from('profiles').update({
          'membership_status': true,
          'membership_expiry': expiryDate,
        }).eq('id', userId);
      }

      // 3. Create Notification for the user
      await SupabaseNotificationService().createNotification(
        userId: userId,
        title: status == 'approved' ? 'Membership Verified' : 'Membership Rejected',
        message: status == 'approved' 
          ? 'Welcome to Unideal Premium! You now have unlimited chat access.' 
          : 'Your membership request was rejected by admin. Please contact support.',
        type: 'membership',
      );
    } catch (e) {
      throw Exception('Failed to update request: $e');
    }
  }
}
