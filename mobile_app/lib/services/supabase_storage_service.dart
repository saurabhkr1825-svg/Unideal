import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String> uploadDonationImage(Uint8List bytes, String fileName) async {
    try {
      final extension = fileName.split('.').last;
      final path = '${DateTime.now().millisecondsSinceEpoch}.$extension';

      await _client.storage.from('donations').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      final imageUrl = _client.storage.from('donations').getPublicUrl(path);
      return imageUrl;
    } catch (e) {
      throw Exception('Image Upload Failed: $e');
    }
  }

  Future<List<String>> uploadMultipleImages(List<Uint8List> imagesBytes, List<String> fileNames) async {
    final List<Future<String>> futures = [];
    for (int i = 0; i < imagesBytes.length; i++) {
      futures.add(uploadDonationImage(imagesBytes[i], fileNames[i]));
    }
    return await Future.wait(futures);
  }
}
