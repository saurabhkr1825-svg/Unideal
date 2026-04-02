import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/purchase_request_model.dart';
import 'supabase_notification_service.dart';

class SupabasePurchaseService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> submitPurchaseRequest({
    required String productId,
    required String buyerId,
    required String sellerId,
    required String hostelName,
    required String roomNo,
    required String meetingPoint,
    String? phone,
  }) async {
    try {
      // 1. Insert purchase request
      await _client.from('purchase_requests').insert({
        'product_id': productId,
        'buyer_id': buyerId,
        'seller_id': sellerId,
        'hostel_name': hostelName,
        'room_no': roomNo,
        'meeting_point': meetingPoint,
        'phone': phone,
      });

      // 2. Notify the seller
      final buyerData = await _client.from('profiles').select('full_name').eq('id', buyerId).single();
      final productData = await _client.from('donations').select('title').eq('id', productId).single();

      await SupabaseNotificationService().createNotification(
        userId: sellerId,
        title: 'New Buy Request',
        message: '${buyerData['full_name']} wants to buy "${productData['title']}"',
        type: 'bid', // Keeping type for consistent icon
      );

    } catch (e) {
      if (e.toString().contains('duplicate key')) {
         throw Exception('You have already submitted a request for this item.');
      }
      throw Exception('Failed to submit purchase request: $e');
    }
  }

  Future<List<PurchaseRequest>> getIncomingRequests(String sellerId) async {
    try {
      final List<dynamic> response = await _client
          .from('purchase_requests')
          .select('''
            *,
            donations!inner(title, image_url),
            profiles_buyer:buyer_id(full_name)
          ''')
          .eq('seller_id', sellerId)
          .order('created_at', ascending: false);

      return response.map((json) => PurchaseRequest.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch incoming requests: $e');
    }
  }

  Future<List<PurchaseRequest>> getMySentRequests(String buyerId) async {
    try {
      final List<dynamic> response = await _client
          .from('purchase_requests')
          .select('''
            *,
            donations!inner(title, image_url)
          ''')
          .eq('buyer_id', buyerId)
          .order('created_at', ascending: false);

      return response.map((json) => PurchaseRequest.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch sent requests: $e');
    }
  }

  Future<void> updateRequestStatus(String requestId, String productId, String buyerId, String status) async {
    try {
      // 1. Update request status
      await _client
          .from('purchase_requests')
          .update({'status': status})
          .eq('id', requestId);

      if (status == 'accepted') {
        // 2. Reject all other requests for same item
        await _client
            .from('purchase_requests')
            .update({'status': 'rejected'})
            .eq('product_id', productId)
            .neq('id', requestId);

        // 3. Mark the donation as SOLD
        await _client
            .from('donations')
            .update({
              'status': 'sold', 
              'is_available': false
            })
            .eq('id', productId);
      }

      // 4. Notify the buyer
      final productData = await _client.from('donations').select('title').eq('id', productId).single();
      await SupabaseNotificationService().createNotification(
        userId: buyerId,
        title: status == 'accepted' ? 'Purchase Request Accepted!' : 'Purchase Request Rejected',
        message: 'Your request for "${productData['title']}" was $status.',
        type: 'bid'
      );

    } catch (e) {
      throw Exception('Failed to update request status: $e');
    }
  }
}
