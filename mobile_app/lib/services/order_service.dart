import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class OrderService {
  Future<void> createOrder({
    required String productId,
    required double amount,
    required String type,
    required String buyerId,
    DateTime? startDate,
    DateTime? endDate,
    String? proofImage,
  }) async {
    try {
      final response = await http.post(
         Uri.parse('${AppConstants.baseUrl}/orders'),
         headers: {'Content-Type': 'application/json'},
         body: json.encode({
           'productId': productId,
           'amount': amount,
           'type': type,
           'buyerId': buyerId,
           'startDate': startDate?.toIso8601String(),
           'endDate': endDate?.toIso8601String(),
           'proofImage': proofImage,
         }),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to create order');
      }
    } catch (e) {
      throw e;
    }
  }

  Future<List<dynamic>> fetchOrders(String userId, {String? role}) async {
    try {
       String url = '${AppConstants.baseUrl}/orders?userId=$userId';
       if (role != null) {
         url += '&role=$role';
       }
       final response = await http.get(Uri.parse(url));
       if (response.statusCode == 200) {
         return json.decode(response.body);
       } else {
         throw Exception('Failed to load orders');
       }
    } catch (e) {
      throw e;
    }
  }

  Future<void> approveOrder(String orderId, String action) async {
    try {
      final response = await http.patch(
        Uri.parse('${AppConstants.baseUrl}/orders/$orderId/approve'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'action': action}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to update order');
      }
    } catch (e) {
      throw e;
    }
  }
}
