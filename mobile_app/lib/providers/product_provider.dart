import 'dart:io';
import 'package:flutter/material.dart';
import '../services/product_service.dart';
import '../models/product_model.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();
  List<Product> _products = [];
  bool _isLoading = false;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;

  Future<void> fetchProducts({String category = '', String search = ''}) async {
    _setLoading(true);
    try {
      final data = await _productService.fetchProducts(category: category, search: search);
      _products = data.map((item) => Product.fromJson(item)).toList();
      notifyListeners();
    } catch (e) {
      print(e);
      // Handle error
    } finally {
      _setLoading(false);
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
  }) async {
    _setLoading(true);
    try {
      await _productService.uploadProduct(
        name: name,
        description: description,
        category: category,
        condition: condition,
        price: price,
        rentPrice: rentPrice,
        allowBuy: allowBuy,
        allowRent: allowRent,
        allowDonate: allowDonate,
        allowReturn: allowReturn,
        sellerId: sellerId,
        images: images,
        video: video,
        token: '', // Add token if needed
      );
      // Refresh list
      await fetchProducts(); 
    } catch (e) {
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> lockProduct(String productId, String userId) async {
    // Don't set loading here to avoid full screen loader, or handle gracefully
    try {
      await _productService.lockProduct(productId, userId);
    } catch (e) {
      rethrow;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
