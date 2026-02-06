import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';

class ProductService {
  
  Future<List<dynamic>> fetchProducts({String category = '', String search = ''}) async {
    try {
      String query = '?';
      if (category.isNotEmpty) query += 'category=$category&';
      if (search.isNotEmpty) query += 'search=$search';

      final response = await http.get(Uri.parse('${AppConstants.productsEndpoint}$query'));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      throw Exception('Failed to connect to server');
    }
  }

  Future<void> uploadProduct({
    required String name,
    required String description,
    required String category,
    required String condition,
    required double price,
    required double rentPrice,
    required bool allowBuy,
    required bool allowRent,
    required bool allowDonate,
    required bool allowReturn,
    required String sellerId,
    required List<File> images,
    File? video,
    required String token, // Send auth token if needed, or backend extracts it
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse(AppConstants.uploadEndpoint));
    
    // Fields
    request.fields['name'] = name;
    request.fields['description'] = description;
    request.fields['category'] = category;
    request.fields['condition'] = condition;
    request.fields['price'] = price.toString();
    request.fields['rentPrice'] = rentPrice.toString();
    request.fields['allowBuy'] = allowBuy.toString();
    request.fields['allowRent'] = allowRent.toString();
    request.fields['allowDonate'] = allowDonate.toString();
    request.fields['allowReturn'] = allowReturn.toString();
    request.fields['sellerId'] = sellerId;

    // Files
    for (var image in images) {
      request.files.add(await http.MultipartFile.fromPath('images', image.path));
    }

    if (video != null) {
      request.files.add(await http.MultipartFile.fromPath('video', video.path));
    }

    // Headers
    // request.headers['Authorization'] = 'Bearer $token'; // If auth middleware active

    var response = await request.send();

    if (response.statusCode != 201) {
      throw Exception('Failed to upload product');
    }
  }
  Future<void> lockProduct(String productId, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.productsEndpoint}/$productId/lock'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': userId}),
      );

      if (response.statusCode == 409) {
        throw Exception('Product is currently being purchased by someone else');
      } 
      
      if (response.statusCode != 200) {
        // We might want to allow 200/201
        throw Exception('Failed to lock product');
      }
    } catch (e) {
      throw e;
    }
  }
}
