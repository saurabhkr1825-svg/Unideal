import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/auction_model.dart';

class SupabaseAuctionService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<List<Map<String, dynamic>>> getAuctionStream(String itemId) {
    return _client
        .from('auctions')
        .stream(primaryKey: ['id'])
        .eq('item_id', itemId);
  }

  Stream<List<Map<String, dynamic>>> getBidsStream(String auctionId) {
    return _client
        .from('bids')
        .stream(primaryKey: ['id'])
        .eq('auction_id', auctionId)
        .order('created_at', ascending: false);
  }

  Future<Auction?> getAuctionByItemId(String itemId) async {
    try {
      final res = await _client
          .from('auctions')
          .select()
          .eq('item_id', itemId)
          .maybeSingle();
      if (res != null) {
        return Auction.fromJson(res);
      }
      return null;
    } catch (e) {
      print('Error fetching auction: $e');
      return null;
    }
  }

  Future<void> createAuction({
    required String itemId,
    required String sellerId,
    required double startingPrice,
    required int durationHours,
  }) async {
    final endTime = DateTime.now().add(Duration(hours: durationHours)).toUtc().toIso8601String();
    
    await _client.from('auctions').insert({
      'item_id': itemId,
      'seller_id': sellerId,
      'starting_price': startingPrice,
      'current_price': startingPrice,
      'end_time': endTime,
      'status': 'active'
    });
  }

  Future<void> placeBid({
    required String auctionId,
    required String bidderId,
    required double bidAmount,
    required double minimumIncrement,
  }) async {
    // 1. Fetch current auction state to ensure bid > current_price
    final auctionRes = await _client.from('auctions').select('seller_id, current_price, status, end_time').eq('id', auctionId).single();
    
    if (auctionRes['seller_id'] == bidderId) {
      throw Exception('You cannot bid on your own auction');
    }
    
    final currentPrice = (auctionRes['current_price'] as num).toDouble();
    final status = auctionRes['status'] as String;
    final endTime = DateTime.parse(auctionRes['end_time']);

    if (status != 'active' || DateTime.now().toUtc().isAfter(endTime)) {
      throw Exception('Auction has ended');
    }

    if (bidAmount < currentPrice + minimumIncrement) {
      throw Exception('Bid must be at least ₹${currentPrice + minimumIncrement}');
    }

    // 2. Insert bid
    await _client.from('bids').insert({
      'auction_id': auctionId,
      'bidder_id': bidderId,
      'bid_amount': bidAmount,
    });

    // 3. Update auction current price
    await _client.from('auctions').update({
      'current_price': bidAmount
    }).eq('id', auctionId);
  }

  Future<void> checkAndFinalizeAuction(String auctionId) async {
    try {
      final auctionRes = await _client.from('auctions').select('status, end_time').eq('id', auctionId).single();
      final status = auctionRes['status'] as String;
      final endTime = DateTime.parse(auctionRes['end_time']);

      if (status == 'active' && DateTime.now().toUtc().isAfter(endTime)) {
        // Find highest bidder
        final topBidRes = await _client
            .from('bids')
            .select('bidder_id, bid_amount')
            .eq('auction_id', auctionId)
            .order('bid_amount', ascending: false)
            .limit(1)
            .maybeSingle();

        String? winnerId;
        if (topBidRes != null) {
          winnerId = topBidRes['bidder_id'];
        }

        await _client.from('auctions').update({
          'status': 'ended',
          'winner_id': winnerId
        }).eq('id', auctionId);
      }
    } catch (e) {
      print('Error finalizing auction: $e');
    }
  }
}
