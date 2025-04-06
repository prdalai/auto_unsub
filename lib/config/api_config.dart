import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static const _storage = FlutterSecureStorage();
  static const _replicateApiKeyKey = 'REPLICATE_API_KEY';

  // Replicate API endpoints
  static const String replicateBaseUrl = 'https://api.replicate.com/v1';
  static const String replicateOmniparserModel =
      'microsoft/omniparser-v2:49cf3d41b8d3aca1360514e83be4c97131ce8f0d99abfc365526d8384caa88df';

  // Get Replicate API key from secure storage or environment
  static Future<String> get replicateApiKey async {
    // Try to get from secure storage first
    String? storedKey = await _storage.read(key: _replicateApiKeyKey);
    if (storedKey != null && storedKey.isNotEmpty) {
      return storedKey;
    }

    // Fall back to environment variable
    final envKey = dotenv.env[_replicateApiKeyKey];
    if (envKey != null && envKey.isNotEmpty) {
      // Store in secure storage for future use
      await _storage.write(key: _replicateApiKeyKey, value: envKey);
      return envKey;
    }

    throw Exception(
        'Replicate API key not found. Please set REPLICATE_API_KEY in .env file or secure storage.');
  }

  // Set Replicate API key in secure storage
  static Future<void> setReplicateApiKey(String apiKey) async {
    await _storage.write(key: _replicateApiKeyKey, value: apiKey);
  }

  // Clear Replicate API key from secure storage
  static Future<void> clearReplicateApiKey() async {
    await _storage.delete(key: _replicateApiKeyKey);
  }

  // Get headers for API requests
  static Future<Map<String, String>> getReplicateHeaders() async {
    final apiKey = await replicateApiKey;
    return {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };
  }
}
