import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../models/product_model.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();
  List<dynamic> _orders = [];
  bool _isLoading = false;

  List<dynamic> get orders => _orders;
  bool get isLoading => _isLoading;

  Future<void> createOrder({
    required Product product,
    required double amount,
    required String type, // 'buy' or 'rent'
    required String buyerId,
    DateTime? startDate,
    DateTime? endDate,
    String? proofImage,
  }) async {
    _setLoading(true);
    try {
      await _orderService.createOrder(
        productId: product.id,
        amount: amount,
        type: type,
        buyerId: buyerId,
        startDate: startDate,
        endDate: endDate,
        proofImage: proofImage,
      );
      // Refresh orders?
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchOrders(String userId, {String? role}) async {
    _setLoading(true);
    try {
       _orders = await _orderService.fetchOrders(userId, role: role);
       notifyListeners();
    } catch (e) {
      print(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> approveOrder(String orderId, String action, String userId) async {
    try {
      await _orderService.approveOrder(orderId, action);
      // Refresh seller orders
      await fetchOrders(userId, role: 'seller');
    } catch (e) {
      rethrow;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
