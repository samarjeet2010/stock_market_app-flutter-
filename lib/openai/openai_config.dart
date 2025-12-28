import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class GeminiClient {
  const GeminiClient();

  static const String geminiApiKey =
      'AIzaSyCugCwvzWopruwqUj3PNqnDDMN8s2no7r4';

  Future<String> generateLearningContent({required String topic}) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$geminiApiKey',
    );

    final body = jsonEncode({
      "contents": [
        {
          "parts": [
            {
              "text": """
You are a concise stock market mentor.
Explain clearly with bullet points and simple examples.
Use INR context and Indian stock market.
Keep sections: Overview, Key Concepts, Practical Tips.

Create an easy-to-follow guide on $topic for a beginner trader in India.
Keep it under 300 words. Include 3 do’s and 3 don’ts.
"""
            }
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.4,
        "maxOutputTokens": 600
      }
    });

    try {
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        return data['candidates'][0]['content']['parts'][0]['text']
            .toString()
            .trim();
      } else {
        throw Exception(
            'Gemini Error ${resp.statusCode}: ${resp.body}');
      }
    } catch (e) {
      debugPrint('Gemini API Error: $e');
      rethrow;
    }
  }
}
