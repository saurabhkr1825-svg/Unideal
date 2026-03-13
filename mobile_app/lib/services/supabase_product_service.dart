import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';

class SupabaseProductService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Product>> fetchProducts({
    String category = '',
    String search = '',
    double? minPrice,
    double? maxPrice,
    String? condition,
    String? itemType,
  }) async {
    try {
      var query = _client.from('donations').select();

      if (category.isNotEmpty && category != 'All') {
        query = query.eq('category', category);
      }
      if (search.isNotEmpty) {
        query = query.ilike('title', '%$search%');
      }
      if (minPrice != null) {
        query = query.gte('price', minPrice);
      }
      if (maxPrice != null) {
        query = query.lte('price', maxPrice);
      }
      if (condition != null && condition.isNotEmpty) {
        query = query.eq('condition', condition);
      }
      if (itemType != null) {
        if (itemType == 'auction') {
          query = query.eq('is_auction', true);
        } else if (itemType == 'donate') {
          query = query.eq('is_auction', false).eq('price', 0);
        } else if (itemType == 'sale') {
          query = query.eq('is_auction', false).gt('price', 0);
        }
      }

      final List<dynamic> response = await query.order('created_at', ascending: false);
      return response.map((item) => Product.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  Future<String> uploadProduct({
    required String title,
    required String description,
    required String category,
    required String condition,
    required String donorId,
    required String? imageUrl,
    required bool isAuction,
    double price = 0.0,
  }) async {
    try {
      final res = await _client.from('donations').insert({
        'title': title,
        'description': description,
        'category': category,
        'condition': condition,
        'donor_id': donorId,
        'image_url': imageUrl,
        'is_auction': isAuction,
        'price': price,
      }).select('id').single();
      return res['id'] as String;
    } catch (e) {
      throw Exception('Failed to upload product: $e');
    }
  }

  Future<void> updateProductImage(String productId, String imageUrl) async {
    try {
      await _client.from('donations').update({
        'image_url': imageUrl,
      }).eq('id', productId);
    } catch (e) {
      throw Exception('Failed to update image: $e');
    }
  }

  Future<void> updateAvailability(String donationId, bool isAvailable) async {
    try {
      await _client.from('donations').update({
        'is_available': isAvailable,
      }).eq('id', donationId);
    } catch (e) {
      throw Exception('Failed to update availability: $e');
    }
  }

  Future<void> updateProductStatus(String productId, String status) async {
    try {
      await _client.from('donations').update({
        'status': status,
        'is_available': status == 'available',
      }).eq('id', productId);
    } catch (e) {
      throw Exception('Failed to update product status: $e');
    }
  }
}
