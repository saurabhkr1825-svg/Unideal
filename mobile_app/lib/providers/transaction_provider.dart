import 'package:flutter/material.dart';
import '../services/supabase_transaction_service.dart';
import '../models/transaction_model.dart';

class TransactionProvider with ChangeNotifier {
  final SupabaseTransactionService _transactionService = SupabaseTransactionService();
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;

  List<TransactionModel> get transactions => _transactions;
  bool get isLoading => _isLoading;

  Future<TransactionModel> createTransaction({
    required String userId,
    String? donationId,
    required double amount,
    required String type,
    required String paymentRef,
    String? utrNumber,
    String? sellerId,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final tx = await _transactionService.createTransaction(
        userId: userId,
        donationId: donationId,
        amount: amount,
        type: type,
        paymentRef: paymentRef,
        utrNumber: utrNumber,
        sellerId: sellerId,
      );
      // Refresh transactions
      await fetchTransactions(userId);
      return tx;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTransactions(String userId) async {
    _setLoading(true);
    try {
       _transactions = await _transactionService.getMyTransactions(userId);
       notifyListeners();
    } catch (e) {
      print(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> verifyOTP(String transactionId, String otp, String userId) async {
    try {
      final success = await _transactionService.verifyOTP(transactionId, otp);
      if (success) {
        await fetchTransactions(userId);
      }
      return success;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTransactionStatus({
    required String transactionId,
    required String status,
    required String userId,
    required String itemTitle,
  }) async {
    try {
      await _transactionService.updateTransactionStatus(transactionId, status, userId, itemTitle);
      await fetchTransactions(userId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateSellerPaymentDetails(String transactionId, String paymentMethod, String userId, {String? upi, String? phone}) async {
    try {
      await _transactionService.updateSellerPaymentDetails(transactionId, paymentMethod, upi: upi, phone: phone);
      await fetchTransactions(userId);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<TransactionModel>> getFundReleaseRequests() async {
    try {
      return await _transactionService.getFundReleaseRequests();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> releaseFunds(String transactionId, String sellerId, String title) async {
    try {
      await _transactionService.releaseFunds(transactionId, sellerId, title);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> rejectFunds(String transactionId, String sellerId, String title) async {
    try {
      await _transactionService.rejectFunds(transactionId, sellerId, title);
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
