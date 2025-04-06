import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

class ReplicateApiService {
  /// Analyzes an image using the Omniparser model
  ///
  /// [imageUrl] - The URL of the image to analyze
  /// Returns the analysis result as a Map
  Future<Map<String, dynamic>> analyzeImage(String imageUrl) async {
    try {
      // Get headers asynchronously
      final headers = await ApiConfig.getReplicateHeaders();

      // Create the prediction
      final response = await http.post(
        Uri.parse('${ApiConfig.replicateBaseUrl}/predictions'),
        headers: headers,
        body: jsonEncode({
          'version': ApiConfig.replicateOmniparserModel.split(':')[1],
          'input': {
            'image': imageUrl,
          },
        }),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to create prediction: ${response.body}');
      }

      final predictionData = jsonDecode(response.body);
      final String predictionId = predictionData['id'];

      // Poll for the result
      return await _pollForResult(predictionId);
    } catch (e) {
      print('Error analyzing image: $e');
      rethrow;
    }
  }

  /// Polls for the result of a prediction
  Future<Map<String, dynamic>> _pollForResult(String predictionId) async {
    int attempts = 0;
    const maxAttempts = 30; // 30 seconds timeout

    while (attempts < maxAttempts) {
      final headers = await ApiConfig.getReplicateHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.replicateBaseUrl}/predictions/$predictionId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to get prediction result: ${response.body}');
      }

      final result = jsonDecode(response.body);

      if (result['status'] == 'succeeded') {
        return result['output'];
      } else if (result['status'] == 'failed') {
        throw Exception('Prediction failed: ${result['error']}');
      }

      // Wait before polling again
      await Future.delayed(const Duration(seconds: 1));
      attempts++;
    }

    throw Exception('Prediction timed out after $maxAttempts seconds');
  }
}
