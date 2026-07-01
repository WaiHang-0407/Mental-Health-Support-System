import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/listener.dart';
import '../models/listener_message.dart';
import '../repositories/listener_repository.dart';

class ListenerController {
  final ListenerRepository _listenerRepo = ListenerRepository();
  final supabase = Supabase.instance.client;

  String? get currentUserId => supabase.auth.currentUser?.id;

  Future<List<ListenerModel>> getAvailableListeners() async {
    return await _listenerRepo.getAvailableListeners();
  }

  Future<ListenerModel?> getMyListenerProfile() async {
    final userId = currentUserId;

    if (userId == null) {
      debugPrint('Get listener profile failed: user is not logged in');
      return null;
    }

    return await _listenerRepo.getListenerByUserId(userId);
  }

  Future<List<Map<String, dynamic>>> getMyPendingRequests() async {
    final listener = await getMyListenerProfile();
    if (listener == null) return [];

    return await _listenerRepo.getPendingRequests(listener.id);
  }

  Future<List<Map<String, dynamic>>> getMyActiveSessions() async {
    final listener = await getMyListenerProfile();
    if (listener == null) return [];

    return await _listenerRepo.getActiveSessions(listener.id);
  }

  Future<List<Map<String, dynamic>>> getMyCompletedSessions() async {
    final listener = await getMyListenerProfile();
    if (listener == null) return [];

    return await _listenerRepo.getCompletedSessions(listener.id);
  }

  Future<Map<String, dynamic>> getMyListenerStats() async {
    final listener = await getMyListenerProfile();

    if (listener == null) {
      return {
        'completed_sessions': 0,
        'total_reviews': 0,
        'average_rating': 0.0,
      };
    }

    return await _listenerRepo.getListenerStats(listener.id);
  }

  Future<String?> requestListener(String listenerId) async {
    final patientId = currentUserId;

    if (patientId == null) {
      debugPrint('Request listener failed: user is not logged in');
      return null;
    }

    return await _listenerRepo.createConversationRequest(
      patientId: patientId,
      listenerId: listenerId,
    );
  }

  Future<String?> getRequestStatus(String conversationId) async {
    final conversation = await _listenerRepo.getConversationById(
      conversationId,
    );

    if (conversation == null) return null;

    return conversation['request_status']?.toString();
  }

  Future<String?> getConversationStatus(String conversationId) async {
    final conversation = await _listenerRepo.getConversationById(
      conversationId,
    );

    if (conversation == null) return null;

    return conversation['status']?.toString();
  }

  Future<List<ListenerMessageModel>> getMessages(String conversationId) async {
    return await _listenerRepo.getMessages(conversationId);
  }

  Future<String?> sendMessage({
    required String conversationId,
    required String message,
    String senderType = 'patient',
  }) async {
    if (message.trim().isEmpty) {
      return 'Message cannot be empty.';
    }

    try {
      await _listenerRepo.sendMessage(
        conversationId: conversationId,
        senderType: senderType,
        message: message.trim(),
      );

      return null;
    } catch (e) {
      debugPrint('Send listener message error: $e');
      return 'Failed to send message.';
    }
  }

  Future<List<Map<String, dynamic>>> getPendingRequests(
    String listenerId,
  ) async {
    return await _listenerRepo.getPendingRequests(listenerId);
  }

  Future<String?> acceptRequest(String conversationId) async {
    try {
      await _listenerRepo.acceptRequest(conversationId);
      return null;
    } catch (e) {
      debugPrint('Accept request error: $e');
      return 'Failed to accept request.';
    }
  }

  Future<String?> rejectRequest(String conversationId) async {
    try {
      await _listenerRepo.rejectRequest(conversationId);
      return null;
    } catch (e) {
      debugPrint('Reject request error: $e');
      return 'Failed to reject request.';
    }
  }

  Future<String?> endSession(String conversationId) async {
    try {
      await _listenerRepo.endSession(conversationId);
      return null;
    } catch (e) {
      debugPrint('End session error: $e');
      return 'Failed to end session.';
    }
  }

  Future<String?> submitSessionRating({
    required String conversationId,
    required int rating,
    String? remark,
  }) async {
    try {
      await _listenerRepo.submitSessionRating(
        conversationId: conversationId,
        rating: rating,
        remark: remark,
      );
      return null;
    } catch (e) {
      debugPrint('Submit session rating error: $e');
      return 'Failed to submit rating.';
    }
  }
}
