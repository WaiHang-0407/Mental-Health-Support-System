import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../models/patient.dart';
import '../repositories/chat_table_repository.dart';
import '../repositories/patient_table_repository.dart';
import '../services/gemini_service.dart';

class ChatController extends ChangeNotifier {
  final ChatRepository _repo = ChatRepository();
  final PatientRepository _patientRepo = PatientRepository();
  final GeminiService _gemini = GeminiService();

  List<ChatSession> sessions = [];
  List<ChatMessage> messages = [];
  PatientModel? patient;
  bool isLoading = false;
  bool isSending = false;

  String get _userId => Supabase.instance.client.auth.currentUser!.id;

  // Load patient info (for fav_animal) + all sessions
  Future<void> loadChatPage() async {
    isLoading = true;
    notifyListeners();
    patient = await _patientRepo.getPatientById(_userId);
    sessions = await _repo.getSessions(_userId);
    isLoading = false;
    notifyListeners();
  }

  // Open or create session for a given animal
  Future<ChatSession> openAnimalSession(String animal) async {
    final session = await _repo.getOrCreateSession(_userId, animal);
    // Update local list
    final exists = sessions.any((s) => s.id == session.id);
    if (!exists) {
      sessions.insert(0, session);
      notifyListeners();
    }
    return session;
  }

  Future<void> loadMessages(String sessionId) async {
    isLoading = true;
    notifyListeners();
    messages = await _repo.getMessages(sessionId);
    isLoading = false;
    notifyListeners();
  }

  // Send text message
  Future<void> sendMessage(
    String sessionId,
    String content,
    String animal,
  ) async {
    if (content.trim().isEmpty) return;
    await _sendAndRespond(
      sessionId: sessionId,
      animal: animal,
      userContent: content.trim(),
    );
  }

  // Send image message
  Future<void> sendImage(
    String sessionId,
    File imageFile,
    String animal,
  ) async {
    final url = await _repo.uploadImage(imageFile, _userId);
    if (url == null) return;
    await _sendAndRespond(
      sessionId: sessionId,
      animal: animal,
      userContent: '[Image sent]',
      imageUrl: url,
    );
  }

  Future<void> deleteSession(String sessionId) async {
    await _repo.deleteSession(sessionId);
    sessions.removeWhere((s) => s.id == sessionId);
    if (messages.isNotEmpty && messages.first.sessionId == sessionId) {
      messages.clear();
    }
    notifyListeners();
  }

  // Soft delete a user message
  Future<void> deleteMessage(String messageId) async {
    await _repo.softDeleteMessage(messageId);
    // Update locally — mark as deleted instead of removing
    final index = messages.indexWhere((m) => m.id == messageId);
    if (index != -1) {
      messages[index] = ChatMessage(
        id: messages[index].id,
        sessionId: messages[index].sessionId,
        role: messages[index].role,
        content: messages[index].content,
        isDeleted: true,
        createdAt: messages[index].createdAt,
      );
      notifyListeners();
    }
  }

  // Hide an AI message
  Future<void> hideMessage(String messageId) async {
    await _repo.hideMessage(messageId);
    messages.removeWhere((m) => m.id == messageId); // remove from UI only
    notifyListeners();
  }

  // Update _sendAndRespond to use full history for Gemini
  Future<void> _sendAndRespond({
    required String sessionId,
    required String animal,
    required String userContent,
    String? imageUrl,
  }) async {
    final userMsg = ChatMessage(
      id: DateTime.now().toIso8601String(),
      sessionId: sessionId,
      role: 'user',
      content: userContent,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );
    messages.add(userMsg);
    isSending = true;
    notifyListeners();

    await _repo.saveMessage(userMsg);

    // 👇 Use full history (including deleted/hidden) for AI context
    final fullHistory = await _repo.getFullHistory(sessionId);
    final history = fullHistory
        .where((m) => m.id != userMsg.id)
        .map((m) => {'role': m.role, 'content': m.content})
        .toList();

    final reply = await _gemini.sendMessage(
      history,
      userContent,
      animal: animal,
    );

    final assistantMsg = ChatMessage(
      id: '${DateTime.now().toIso8601String()}_reply',
      sessionId: sessionId,
      role: 'assistant',
      content: reply,
      createdAt: DateTime.now(),
    );
    await _repo.saveMessage(assistantMsg);
    messages.add(assistantMsg);

    isSending = false;
    notifyListeners();
  }
}
