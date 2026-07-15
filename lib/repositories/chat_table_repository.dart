import 'dart:io';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_message.dart';
import '../models/chat_session.dart';
import 'user_activity_logs_table_repository.dart';

class ChatRepository {
  final supabase = Supabase.instance.client;
  final _activityLogsTable = UserActivityLogsTableRepository();

  Future<ChatSession> getOrCreateSession(
    String patientId,
    String animal,
  ) async {
    final animalKey = _animalKey(animal);
    final existing = await supabase
        .from('chat_sessions')
        .select()
        .eq('patient_id', patientId)
        .inFilter('animal', _animalVariants(animalKey))
        .maybeSingle();
    if (existing != null) return ChatSession.fromMap(existing);

    final session = ChatSession(
      id: '',
      patientId: patientId,
      title: '${_capitalize(animalKey)} Chat',
      animal: animalKey,
      createdAt: DateTime.now(),
    );
    final data = await supabase
        .from('chat_sessions')
        .insert(session.toCreateMap())
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

  Future<String?> uploadImage(File file, String userId) async {
    try {
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await supabase.storage.from('chat-images').upload(fileName, file);
      final url = supabase.storage.from('chat-images').getPublicUrl(fileName);

      return url;
    } catch (e) {
      debugPrint('Image upload error: $e');
      return null;
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _animalKey(String animal) {
    return animal.trim().toLowerCase().replaceAll(' ', '-');
  }

  List<String> _animalVariants(String animal) {
    final spaced = animal.replaceAll('-', ' ');
    final titled = spaced
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
    return {animal, spaced, titled}.toList();
  }

  Future<void> softDeleteMessage(String messageId) async {
    await supabase
        .from('chat_messages')
        .update({'is_deleted': true})
        .eq('id', messageId);
  }

  Future<void> hideMessage(String messageId) async {
    await supabase
        .from('chat_messages')
        .update({'is_hidden': true})
        .eq('id', messageId);
  }

  Future<List<ChatMessage>> getMessages(String sessionId) async {
    final data = await supabase
        .from('chat_messages')
        .select()
        .eq('session_id', sessionId)
        .eq('is_hidden', false)
        .order('created_at', ascending: true);
    return (data as List).map((e) => ChatMessage.fromMap(e)).toList();
  }

  Future<List<ChatMessage>> getFullHistory(String sessionId) async {
    final data = await supabase
        .from('chat_messages')
        .select()
        .eq('session_id', sessionId)
        .order('created_at', ascending: true);
    return (data as List).map((e) => ChatMessage.fromMap(e)).toList();
  }

  Future<void> _log(String patientId, String action, {String? targetId}) async {
    await _activityLogsTable.insert(
      patientId: patientId,
      action: action,
      targetType: 'chat',
      targetId: targetId,
    );
  }
}
