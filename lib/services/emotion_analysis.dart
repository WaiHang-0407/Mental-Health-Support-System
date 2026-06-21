// services/emotion_analysis.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EmotionAnalysisService {
  final supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> analyzeEmotion(String journalText) async {
    try {
      final response = await supabase.functions.invoke(
        'gemini-emotion',
        body: {'journalText': journalText},
      );

      final data = response.data;
      if (data is Map && data['emotion'] is String) {
        final emotion = (data['emotion'] as String).trim();
        if (emotion.isNotEmpty) {
          return {'emotion': emotion};
        }
      }

      debugPrint('Emotion function unexpected response: $data');
      return {'emotion': 'Unknown'};
    } catch (e) {
      debugPrint('Emotion analysis function error: $e');
      return {'emotion': 'Unknown'};
    }
  }
}
