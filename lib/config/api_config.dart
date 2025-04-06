import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static const _storage = FlutterSecureStorage();
  static const _replicateApiKeyKey = 'REPLICATE_API_KEY';

  // Replicate API endpoints
  static const String replicateBaseUrl = 'https://api.replicate.com/v1';
  static const String replicateOmniparserModel =
      'microsoft/omniparser-v2:49cf3d41b8d3aca1360514e83be4c97131ce8f0d99abfc365526d8384caa88df';

  // Get headers for API requests
  static Map<String, String> getReplicateHeaders() {
    return {
      'Content-Type': 'application/json',
    };
  }
}
