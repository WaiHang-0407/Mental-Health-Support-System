import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class GeminiService {
  static const String _apiKey = 'AIzaSyBHum-c0eHItHk0Pxq4tmNK_JI44ICbkas';
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent';

  String _systemPrompt(String animal) =>
      '''
You are Mindly, a warm mental health companion who presents as a friendly $animal.
Occasionally reference being a $animal naturally (e.g. "As your $animal friend, I...").
Your role:
- Listen actively and respond with empathy
- Provide emotional support and coping strategies  
- Encourage professional help when needed
- Never diagnose or prescribe medication
- Keep responses concise and conversational (2-4 sentences)
- If the user seems in crisis, recommend professional help or a hotline
- If the user sends an image, acknowledge it warmly and ask about it
''';

  Future<String> sendMessage(
    List<Map<String, String>> history,
    String newMessage, {
    String animal = 'dog',
  }) async {
    final contents = [
      {
        'role': 'user',
        'parts': [
          {'text': _systemPrompt(animal)},
        ],
      },
      {
        'role': 'model',
        'parts': [
          {
            'text':
                "Hi! I'm your Mindly $animal friend. How are you feeling today?",
          },
        ],
      },
      ...history.map(
        (msg) => {
          'role': msg['role'] == 'user' ? 'user' : 'model',
          'parts': [
            {'text': msg['content']},
          ],
        },
      ),
      {
        'role': 'user',
        'parts': [
          {'text': newMessage},
        ],
      },
    ];

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'contents': contents}),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'] as String;
      }
      debugPrint('Gemini error ${response.statusCode}: ${response.body}');
      return "I'm having trouble connecting. Please try again.";
    } catch (e) {
      debugPrint('Gemini exception: $e');
      return "Something went wrong. Please check your connection.";
    }
  }
}
