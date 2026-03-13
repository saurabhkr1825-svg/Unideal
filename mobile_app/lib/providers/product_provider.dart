import 'dart:io';
import 'package:flutter/material.dart';
import '../services/supabase_product_service.dart';
import '../services/supabase_storage_service.dart';
import '../models/product_model.dart';

class ProductProvider with ChangeNotifier {
  final SupabaseProductService _productService = SupabaseProductService();
  final SupabaseStorageService _storageService = SupabaseStorageService();
  List<Product> _products = [];
  bool _isLoading = false;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;

  Future<void> fetchProducts({
    String category = '',
    String search = '',
    double? minPrice,
    double? maxPrice,
    String? condition,
    String? itemType,
  }) async {
    _setLoading(true);
    try {
      _products = await _productService.fetchProducts(
        category: category,
        search: search,
        minPrice: minPrice,
        maxPrice: maxPrice,
        condition: condition,
        itemType: itemType,
      );
      notifyListeners();
    } catch (e) {
      print(e);
    } finally {
      _setLoading(false);
    }
  }

  Future<String> uploadProduct({
    required String title,
    required String description,
    required String category,
    required String condition,
    required String donorId,
    required File image,
    required bool isAuction,
    double price = 0.0,
  }) async {
    _setLoading(true);
    try {
      // 1. Upload Image
      final imageUrl = await _storageService.uploadDonationImage(image);

      // 2. Create Donation
      final productId = await _productService.uploadProduct(
        title: title,
        description: description,
        category: category,
        condition: condition,
        donorId: donorId,
        imageUrl: imageUrl,
        isAuction: isAuction,
        price: price,
      );
      
      await fetchProducts(); 
      return productId;
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateAvailability(String donationId, bool isAvailable) async {
    try {
      await _productService.updateAvailability(donationId, isAvailable);
      await fetchProducts();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProductStatus(String productId, String status) async {
    try {
      await _productService.updateProductStatus(productId, status);
      await fetchProducts();
    } catch (e) {
      rethrow;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
