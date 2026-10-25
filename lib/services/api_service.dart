import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/food_analysis_result.dart';

class ApiService {
  final String urlOrSentinel; // currently unused, kept so existing calls work
  final String apiKey;

  ApiService(this.urlOrSentinel, this.apiKey);

  // Check https://ai.google.dev/gemini-api/docs/models for current model codes.
  static const String _model = 'gemini-3.6-flash';
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent';

  static const String _prompt = '''
You are a professional nutrition and food safety assistant. Analyze this food image carefully.
Return ONLY a valid JSON object with exactly these keys, no explanation and no markdown:

{
  "food_name": "string, name of the food",
  "calories": integer, estimated total calories,
  "serving_size": "string, estimated serving size e.g. 1 plate, 200g",
  "nutrition": {
    "protein_g": number,
    "carbs_g": number,
    "fat_g": number,
    "fiber_g": number,
    "sugar_g": number,
    "sodium_mg": number
  },
  "ingredients": ["array", "of", "strings"],
  "allergens": ["only allergens present from: Gluten, Dairy, Eggs, Nuts, Soy, Shellfish, Fish, Wheat, Peanuts"],
  "health_notes": "string, 2-3 sentences on nutritional value, health impact, and who should be cautious",
  "health_score": integer from 1 (very unhealthy) to 10 (very healthy),
  "diet_tags": ["only tags that apply from: High-Protein, Low-Carb, Vegan, Vegetarian, Keto, Gluten-Free, Low-Fat, High-Fiber"]
}

If the image does not contain food, return food_name "Not a food item", calories 0, health_score 1 and empty lists.
''';

  /// Detects the real image type from the first bytes instead of assuming JPEG.
  String _detectMimeType(Uint8List b) {
    if (b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8) return 'image/jpeg';
    if (b.length >= 4 &&
        b[0] == 0x89 &&
        b[1] == 0x50 &&
        b[2] == 0x4E &&
        b[3] == 0x47) {
      return 'image/png';
    }
    if (b.length >= 12 &&
        b[0] == 0x52 && // R
        b[1] == 0x49 && // I
        b[8] == 0x57 && // W
        b[9] == 0x45) {
      return 'image/webp';
    }
    if (b.length >= 12 &&
        b[4] == 0x66 && // f
        b[5] == 0x74 && // t
        b[6] == 0x79 && // y
        b[7] == 0x70) {
      return 'image/heic';
    }
    return 'image/jpeg';
  }

  /// Turns a Gemini error body into a short readable message.
  String _errorMessage(http.Response r) {
    try {
      final msg = jsonDecode(r.body)['error']?['message'];
      if (msg is String && msg.isNotEmpty) return msg;
    } catch (_) {}
    return 'HTTP ${r.statusCode}';
  }

  Future<http.Response> _postWithRetry(String body) async {
    const retryable = {429, 500, 503};
    const maxAttempts = 3;

    late http.Response response;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              // Key in a header, not in the URL, so it can't leak into logs
              // or exception messages.
              'x-goog-api-key': apiKey,
            },
            body: body,
          )
          .timeout(const Duration(seconds: 90));

      if (!retryable.contains(response.statusCode) || attempt == maxAttempts) {
        break;
      }
      await Future.delayed(Duration(seconds: 2 * attempt));
    }
    return response;
  }

  Future<FoodAnalysisResult> analyzeBytes(Uint8List bytes) async {
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': _prompt},
            {
              'inline_data': {
                'mime_type': _detectMimeType(bytes),
                'data': base64Encode(bytes),
              }
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.2,
        // Makes Gemini return pure JSON (no ```json fences).
        'responseMimeType': 'application/json',
      },
    });

    final response = await _postWithRetry(body);

    if (response.statusCode != 200) {
      debugPrint('Gemini ${response.statusCode}: ${response.body}');
      throw Exception(
          'Gemini API error (${response.statusCode}): ${_errorMessage(response)}');
    }

    final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;

    final blockReason = jsonBody['promptFeedback']?['blockReason'];
    if (blockReason != null) {
      throw Exception('Image was blocked by Gemini ($blockReason)');
    }

    final candidates = jsonBody['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Gemini returned no candidates');
    }

    final candidate = candidates[0] as Map<String, dynamic>;
    final finishReason = candidate['finishReason'];
    if (finishReason != null &&
        finishReason != 'STOP' &&
        finishReason != 'FINISH_REASON_UNSPECIFIED') {
      throw Exception('Gemini stopped early ($finishReason)');
    }

    // Join all non-"thought" text parts (newer models can return several).
    final parts = (candidate['content']?['parts'] as List?) ?? const [];
    final text = parts
        .where((p) => p is Map && p['thought'] != true && p['text'] is String)
        .map((p) => p['text'] as String)
        .join();

    if (text.trim().isEmpty) {
      throw Exception('Gemini returned an empty response');
    }

    // Safety net in case the model still adds fences or extra text.
    final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
    final start = cleaned.indexOf('{');
    final end = cleaned.lastIndexOf('}');
    final rawJson = (start >= 0 && end > start)
        ? cleaned.substring(start, end + 1)
        : cleaned;

    final parsed = jsonDecode(rawJson) as Map<String, dynamic>;
    return FoodAnalysisResult.fromJson(parsed);
  }

  Future<FoodAnalysisResult> analyzeImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    return analyzeBytes(bytes);
  }
}
