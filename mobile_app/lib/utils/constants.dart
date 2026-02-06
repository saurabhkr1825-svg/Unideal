class AppConstants {
  // Use localhost for Android Emulator (10.0.2.2) or local IP for physical device
  // Update this with your machine's IP if running on a real device
  static const String baseUrl = 'http://10.0.2.2:5000/api'; 
  
  static const String authEndpoint = '$baseUrl/auth';
  static const String productsEndpoint = '$baseUrl/products';
  static const String uploadEndpoint = '$baseUrl/products/upload';
}
