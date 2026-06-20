import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';

class ChatRepository {
  final supabase = Supabase.instance.client;

  // Get or create session for a specific animal (enforces one per animal)
  Future<ChatSession> getOrCreateSession(
    String patientId,
    String animal,
  ) async {
    // Check if session already exists for this animal
    final existing = await supabase
        .from('chat_sessions')
        .select()
        .eq('patient_id', patientId)
        .eq('animal', animal)
        .maybeSingle();

    if (existing != null) return ChatSession.fromMap(existing);

    // Create new session for this animal
    final data = await supabase
        .from('chat_sessions')
        .insert({
          'patient_id': patientId,
          'title': '${_capitalize(animal)} Chat',
          'animal': animal,
        })
        .select()
        .single();
    await _log(patientId, 'chat_started', targetId: data['id']);
    return ChatSession.fromMap(data);
  }

  Future<List<ChatSession>> getSessions(String patientId) async {
    final data = await supabase
        .from('chat_sessions')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false);
    return (data as List).map((e) => ChatSession.fromMap(e)).toList();
  }

  Future<void> deleteSession(String sessionId) async {
    await supabase.from('chat_sessions').delete().eq('id', sessionId);
  }

  Future<void> saveMessage(ChatMessage message) async {
    await supabase.from('chat_messages').insert(message.toMap());
  }

  // Upload image to Supabase Storage and return public URL
  Future<String?> uploadImage(File file, String userId) async {
    try {
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await supabase.storage
          .from('chat-images') // 👈 must exactly match your bucket name
          .upload(fileName, file);

      final url = supabase.storage
          .from('chat-images') // 👈 same here
          .getPublicUrl(fileName);

      return url;
    } catch (e) {
      debugPrint('Image upload error: $e');
      return null;
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  // Soft delete user message
  Future<void> softDeleteMessage(String messageId) async {
    await supabase
        .from('chat_messages')
        .update({'is_deleted': true})
        .eq('id', messageId);
  }

  // Hide AI message
  Future<void> hideMessage(String messageId) async {
    await supabase
        .from('chat_messages')
        .update({'is_hidden': true})
        .eq('id', messageId);
  }

  // Fetch messages for DISPLAY (exclude hidden, show deleted as placeholder)
  Future<List<ChatMessage>> getMessages(String sessionId) async {
    final data = await supabase
        .from('chat_messages')
        .select()
        .eq('session_id', sessionId)
        .eq('is_hidden', false)
        .order('created_at', ascending: true);
    return (data as List).map((e) => ChatMessage.fromMap(e)).toList();
  }

  // Fetch FULL history for Gemini context (no filters)
  Future<List<ChatMessage>> getFullHistory(String sessionId) async {
    final data = await supabase
        .from('chat_messages')
        .select()
        .eq('session_id', sessionId)
        .order('created_at', ascending: true);
    return (data as List).map((e) => ChatMessage.fromMap(e)).toList();
  }

  Future<void> _log(String patientId, String action, {String? targetId}) async {
    await supabase.from('user_activity_logs').insert({
      'patient_id': patientId,
      'action': action,
      'target_type': 'chat',
      if (targetId != null) 'target_id': targetId,
    });
  }
}
