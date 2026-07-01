import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/listener.dart';
import '../models/listener_message.dart';

class ListenerRepository {
  final supabase = Supabase.instance.client;

  Future<List<ListenerModel>> getAvailableListeners() async {
    try {
      final data = await supabase
          .from('listener')
          .select()
          .eq('status', 'available')
          .order('rating', ascending: false);

      return (data as List)
          .map((e) => ListenerModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Get available listeners error: $e');
      return [];
    }
  }

  Future<ListenerModel?> getListenerByUserId(String userId) async {
    try {
      final data = await supabase
          .from('listener')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (data == null) return null;

      return ListenerModel.fromMap(data);
    } catch (e) {
      debugPrint('Get listener by user id error: $e');
      return null;
    }
  }

  Future<String?> createConversationRequest({
    required String patientId,
    required String listenerId,
  }) async {
    try {
      final data = await supabase
          .from('listener_conversation')
          .insert({
            'patient_id': patientId,
            'listener_id': listenerId,
            'status': 'active',
            'request_status': 'pending',
          })
          .select('''
            *,
               patients(
                 id,
                 name,
                 avatar_url
                 )
          ''')
          .single();

      return data['id']?.toString();
    } catch (e, stack) {
      debugPrint('Create listener request error: $e');
      debugPrint('$stack');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getConversationById(
    String conversationId,
  ) async {
    try {
      final data = await supabase
          .from('listener_conversation')
          .select()
          .eq('id', conversationId)
          .maybeSingle();

      return data;
    } catch (e) {
      debugPrint('Get conversation error: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getPendingRequests(
    String listenerId,
  ) async {
    try {
      final data = await supabase
          .from('listener_conversation')
          .select('''
  *,
  patients(
    id,
    name,
    avatar_url
  )
''')
          .eq('listener_id', listenerId)
          .eq('request_status', 'pending')
          .order('started_at', ascending: false);

      return (data as List).map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Get pending listener requests error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getActiveSessions(
    String listenerId,
  ) async {
    try {
      final data = await supabase
          .from('listener_conversation')
          .select('''
            *,
               patients(
                 id,
                 name,
                 avatar_url
                 )
          ''')
          .eq('listener_id', listenerId)
          .eq('request_status', 'accepted')
          .eq('status', 'active')
          .order('accepted_at', ascending: false);

      return (data as List).map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Get active listener sessions error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCompletedSessions(
    String listenerId,
  ) async {
    try {
      final data = await supabase
          .from('listener_conversation')
          .select('''
            *,
               patients(
                 id,
                 name,
                 avatar_url
                 )
          ''')
          .eq('listener_id', listenerId)
          .eq('status', 'closed')
          .order('ended_at', ascending: false);

      return (data as List).map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Get completed listener sessions error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getListenerStats(String listenerId) async {
    try {
      final completed = await getCompletedSessions(listenerId);

      final ratedSessions = completed.where((session) {
        return session['patient_rating'] != null;
      }).toList();

      final totalCompleted = completed.length;
      final totalReviews = ratedSessions.length;

      double averageRating = 0;

      if (ratedSessions.isNotEmpty) {
        final totalRating = ratedSessions.fold<int>(0, (sum, session) {
          return sum + ((session['patient_rating'] as num?)?.toInt() ?? 0);
        });

        averageRating = totalRating / ratedSessions.length;
      }

      return {
        'completed_sessions': totalCompleted,
        'total_reviews': totalReviews,
        'average_rating': averageRating,
      };
    } catch (e) {
      debugPrint('Get listener stats error: $e');
      return {
        'completed_sessions': 0,
        'total_reviews': 0,
        'average_rating': 0.0,
      };
    }
  }

  Future<String?> getIntroductionMessage(String listenerId) async {
    try {
      final data = await supabase
          .from('listener')
          .select('introduction_message')
          .eq('id', listenerId)
          .maybeSingle();

      return data?['introduction_message']?.toString();
    } catch (e) {
      debugPrint('Get introduction message error: $e');
      return null;
    }
  }

  Future<void> sendAutomaticIntroduction({
    required String conversationId,
    required String listenerId,
  }) async {
    try {
      final intro = await getIntroductionMessage(listenerId);

      if (intro == null || intro.trim().isEmpty) return;

      final existingMessages = await supabase
          .from('listener_message')
          .select('id')
          .eq('conversation_id', conversationId)
          .limit(1);

      if ((existingMessages as List).isNotEmpty) return;

      await supabase.from('listener_message').insert({
        'conversation_id': conversationId,
        'sender_type': 'listener',
        'message': intro.trim(),
      });
    } catch (e) {
      debugPrint('Automatic intro error: $e');
    }
  }

  Future<void> acceptRequest(String conversationId) async {
    await supabase
        .from('listener_conversation')
        .update({
          'request_status': 'accepted',
          'accepted_at': DateTime.now().toIso8601String(),
        })
        .eq('id', conversationId);

    final conversation = await getConversationById(conversationId);

    if (conversation == null) return;

    final listenerId = conversation['listener_id']?.toString();

    if (listenerId == null || listenerId.isEmpty) return;

    await sendAutomaticIntroduction(
      conversationId: conversationId,
      listenerId: listenerId,
    );
  }

  Future<void> rejectRequest(String conversationId) async {
    await supabase
        .from('listener_conversation')
        .update({'request_status': 'rejected'})
        .eq('id', conversationId);
  }

  Future<List<ListenerMessageModel>> getMessages(String conversationId) async {
    try {
      final data = await supabase
          .from('listener_message')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      return (data as List)
          .map((e) => ListenerMessageModel.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Get listener messages error: $e');
      return [];
    }
  }

  Future<void> sendMessage({
    required String conversationId,
    required String senderType,
    required String message,
  }) async {
    final conversation = await getConversationById(conversationId);

    if (conversation == null) {
      throw Exception('Conversation not found.');
    }

    if (conversation['status'] == 'closed') {
      throw Exception('This session has already ended.');
    }

    await supabase.from('listener_message').insert({
      'conversation_id': conversationId,
      'sender_type': senderType,
      'message': message,
    });
  }

  Future<void> endSession(String conversationId) async {
    await supabase
        .from('listener_conversation')
        .update({
          'status': 'closed',
          'ended_at': DateTime.now().toIso8601String(),
        })
        .eq('id', conversationId);
  }

  Future<void> submitSessionRating({
    required String conversationId,
    required int rating,
    String? remark,
  }) async {
    await supabase
        .from('listener_conversation')
        .update({
          'patient_rating': rating,
          'patient_remark': remark?.trim().isEmpty == true
              ? null
              : remark?.trim(),
          'rated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', conversationId);

    await _updateListenerAverageRating(conversationId);
  }

  Future<void> _updateListenerAverageRating(String conversationId) async {
    try {
      final conversation = await getConversationById(conversationId);
      if (conversation == null) return;

      final listenerId = conversation['listener_id']?.toString();
      if (listenerId == null || listenerId.isEmpty) return;

      final ratedSessions = await supabase
          .from('listener_conversation')
          .select('patient_rating')
          .eq('listener_id', listenerId)
          .not('patient_rating', 'is', null);

      final ratings = (ratedSessions as List)
          .map((e) => (e['patient_rating'] as num).toDouble())
          .toList();

      if (ratings.isEmpty) return;

      final average =
          ratings.reduce((value, element) => value + element) / ratings.length;

      await supabase
          .from('listener')
          .update({
            'rating': double.parse(average.toStringAsFixed(1)),
            'total_reviews': ratings.length,
          })
          .eq('id', listenerId);
    } catch (e) {
      debugPrint('Update listener average rating error: $e');
    }
  }
}
