import 'package:flutter/foundation.dart';
import 'package:untitled_5/services/api_client.dart';

/// Calls the backend's AI advisor endpoint instead of hitting Gemini
/// directly from the app. This keeps the Gemini API key server-side only,
/// instead of shipped inside the compiled app.
class GeminiClient {
  const GeminiClient();

  Future<String> generateLearningContent({required String topic}) async {
    try {
      final resp = await ApiClient.instance.post('/ai/advice', {'topic': topic});
      if (resp.ok) {
        return (resp.data['content'] as String?)?.trim() ?? '';
      }
      throw Exception('AI advisor error: ${resp.errorMessage}');
    } catch (e) {
      debugPrint('AI advisor error: $e');
      rethrow;
    }
  }
}
