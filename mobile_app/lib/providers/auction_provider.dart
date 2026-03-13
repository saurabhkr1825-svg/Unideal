import 'package:flutter/material.dart';
import '../services/supabase_auction_service.dart';
import '../models/auction_model.dart';

class AuctionProvider with ChangeNotifier {
  final SupabaseAuctionService _auctionService = SupabaseAuctionService();
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Stream<List<Map<String, dynamic>>> getAuctionStream(String itemId) {
    return _auctionService.getAuctionStream(itemId);
  }

  Stream<List<Map<String, dynamic>>> getBidsStream(String auctionId) {
    return _auctionService.getBidsStream(auctionId);
  }

  Future<Auction?> fetchAuctionByItemId(String itemId) async {
    return await _auctionService.getAuctionByItemId(itemId);
  }

  Future<void> createAuction({
    required String itemId,
    required String sellerId,
    required double startingPrice,
    required int durationHours,
  }) async {
    _setLoading(true);
    try {
      await _auctionService.createAuction(
        itemId: itemId,
        sellerId: sellerId,
        startingPrice: startingPrice,
        durationHours: durationHours,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> placeBid({
    required String auctionId,
    required String bidderId,
    required double bidAmount,
    required double minimumIncrement,
  }) async {
    _setLoading(true);
    try {
      await _auctionService.placeBid(
        auctionId: auctionId,
        bidderId: bidderId,
        bidAmount: bidAmount,
        minimumIncrement: minimumIncrement,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> checkAndFinalizeAuction(String auctionId) async {
    await _auctionService.checkAndFinalizeAuction(auctionId);
  }
}
