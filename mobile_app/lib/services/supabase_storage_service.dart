import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseStorageService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<String> uploadDonationImage(File imageFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
      final path = '$fileName';

      await _client.storage.from('donations').upload(
        path,
        imageFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      final imageUrl = _client.storage.from('donations').getPublicUrl(path);
      return imageUrl;
    } catch (e) {
      throw Exception('Image Upload Failed: $e');
    }
  }

  Future<List<String>> uploadMultipleImages(List<File> images) async {
    final futures = images.map((image) => uploadDonationImage(image));
    return await Future.wait(futures);
  }
}
