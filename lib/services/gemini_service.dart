import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
}
