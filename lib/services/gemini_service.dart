import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/affirmation.dart';
import '../models/user_location.dart';
import '../models/weather_snapshot.dart';

class GeminiService {
  final supabase = Supabase.instance.client;

  Future<String> sendMessage(
    List<Map<String, String>> history,
    String newMessage, {
    String animal = 'dog',
  }) async {
    try {
      final response = await supabase.functions.invoke(
        'gemini-chat',
        body: {'history': history, 'newMessage': newMessage, 'animal': animal},
      );

      final data = response.data;
      if (data is Map && data['reply'] is String) {
        return data['reply'] as String;
      }

      debugPrint('Gemini function unexpected response: $data');
      return "I'm having trouble connecting. Please try again.";
    } catch (e) {
      debugPrint('Gemini function exception: $e');
      return "Something went wrong. Please check your connection.";
    }
  }

  Future<String?> chooseAffirmation({
    required List<Affirmation> affirmations,
    required UserLocation? location,
    required WeatherSnapshot? weather,
  }) async {
    if (affirmations.isEmpty) return null;

    try {
      final response = await supabase.functions.invoke(
        'gemini-affirmation',
        body: {
          'affirmations': affirmations
              .map((affirmation) => {
                    'id': affirmation.id,
                    'text': affirmation.text,
                  })
              .toList(growable: false),
          'location': location == null
              ? null
              : {
                  'latitude': location.latitude,
                  'longitude': location.longitude,
                },
          'weather': weather == null
              ? null
              : {
                  'code': weather.weatherCode,
                  'category': weather.category,
                  'temperature': weather.temperature,
                },
        },
      );

      final data = response.data;
      if (data is Map && data['affirmationId'] is String) {
        final id = (data['affirmationId'] as String).trim();
        if (id.isNotEmpty) return id;
      }

      debugPrint('Gemini affirmation unexpected response: $data');
      return null;
    } catch (e) {
      debugPrint('Gemini affirmation function error: $e');
      return null;
    }
  }
}
