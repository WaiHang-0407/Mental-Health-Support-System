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

  Future<List<Map<String, dynamic>>> getPendingRequestsForPatient(
    String patientId,
  ) async {
    try {
      final data = await supabase
          .from('listener_conversation')
          .select()
          .eq('patient_id', patientId)
          .eq('request_status', 'pending')
          .order('started_at', ascending: false);

      return await _attachListenerDetails(data as List);
    } catch (e) {
      debugPrint('Get pending patient listener requests error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getActiveRequestsForPatient(
    String patientId,
  ) async {
    try {
      final data = await supabase
          .from('listener_conversation')
          .select()
          .eq('patient_id', patientId)
          .eq('request_status', 'accepted')
          .eq('status', 'active')
          .order('accepted_at', ascending: false);

      return await _attachListenerDetails(data as List);
    } catch (e) {
      debugPrint('Get active patient listener requests error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _attachListenerDetails(List rows) async {
    final requests = <Map<String, dynamic>>[];

    for (final row in rows) {
      final request = Map<String, dynamic>.from(row as Map<String, dynamic>);
      final listenerId = request['listener_id']?.toString();

      if (listenerId == null || listenerId.isEmpty) {
        requests.add(request);
        continue;
      }

      final listenerData = await supabase
          .from('listener')
          .select()
          .eq('id', listenerId)
          .maybeSingle();

      if (listenerData != null) {
        request['listener_name'] =
            listenerData['name']?.toString() ?? 'Listener';
        request['listener_profile_url'] =
            listenerData['profile_url']?.toString();
        request['listener_bio'] = listenerData['bio']?.toString();
      }

      requests.add(request);
    }

    return requests;
  }

  Future<void> cancelRequest(String conversationId) async {
    final currentUserId = supabase.auth.currentUser?.id;

    if (currentUserId == null) {
      throw Exception('User is not logged in.');
    }

    final updatedRows = await supabase
        .from('listener_conversation')
        .update({'request_status': 'cancelled'})
        .eq('id', conversationId)
        .eq('patient_id', currentUserId)
        .eq('request_status', 'pending')
        .select('id');

    if ((updatedRows as List).isEmpty) {
      throw Exception(
        'Request was not cancelled. It may already be accepted or cancelled.',
      );
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

  Future<void> updateListenerProfile(
    String listenerId,
    Map<String, dynamic> fields,
  ) async {
    final currentUserId = supabase.auth.currentUser?.id;

    if (currentUserId == null) {
      throw Exception('User is not logged in.');
    }

    final normalizedFields = <String, dynamic>{};

    fields.forEach((key, value) {
      if (value == null) {
        normalizedFields[key] = null;
      } else if (value is String) {
        final trimmed = value.trim();
        normalizedFields[key] = trimmed.isEmpty ? null : trimmed;
      } else {
        normalizedFields[key] = value;
      }
    });

    final updated = await supabase
        .from('listener')
        .update(normalizedFields)
        .eq('id', listenerId)
        .eq('user_id', currentUserId)
        .select()
        .maybeSingle();

    if (updated == null) {
      throw Exception('Listener profile was not updated.');
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
    final conversation = await getConversationById(conversationId);

    if (conversation == null) {
      throw Exception('Conversation not found.');
    }

    if (conversation['request_status'] != 'pending') {
      throw Exception('This request is no longer pending.');
    }

    await supabase
        .from('listener_conversation')
        .update({
          'request_status': 'accepted',
          'status': 'active',
          'accepted_at': DateTime.now().toIso8601String(),
        })
        .eq('id', conversationId);

    final listenerId = conversation['listener_id']?.toString();

    if (listenerId == null || listenerId.isEmpty) return;

    await sendAutomaticIntroduction(
      conversationId: conversationId,
      listenerId: listenerId,
    );
  }

  Future<void> rejectRequest(String conversationId) async {
    final conversation = await getConversationById(conversationId);

    if (conversation == null) {
      throw Exception('Conversation not found.');
    }

    if (conversation['request_status'] != 'pending') {
      throw Exception('This request is no longer pending.');
    }

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
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> endSession(String conversationId) async {
    final currentUserId = supabase.auth.currentUser?.id;

    if (currentUserId == null) {
      throw Exception('User is not logged in.');
    }

    final updatedRows = await supabase
        .from('listener_conversation')
        .update({
          'status': 'closed',
          'ended_at': DateTime.now().toIso8601String(),
        })
        .eq('id', conversationId)
        .eq('status', 'active')
        .select('id');

    if ((updatedRows as List).isEmpty) {
      throw Exception(
        'Session was not ended. It may already be closed or access was denied.',
      );
    }
  }

  Future<void> submitSessionRating({
    required String conversationId,
    required int rating,
    String? remark,
  }) async {
    if (rating < 1 || rating > 5) {
      throw Exception('Rating must be between 1 and 5.');
    }

    final currentUserId = supabase.auth.currentUser?.id;

    if (currentUserId == null) {
      throw Exception('User is not logged in.');
    }

    final conversation = await getConversationById(conversationId);

    if (conversation == null) {
      throw Exception('Conversation not found.');
    }

    if (conversation['status'] != 'closed') {
      throw Exception('This session must end before it can be rated.');
    }

    final listenerId = conversation['listener_id']?.toString();

    if (listenerId == null || listenerId.isEmpty) {
      throw Exception('Listener could not be found.');
    }

    final updatedRows = await supabase
        .from('listener_conversation')
        .update({
          'patient_rating': rating,
          'patient_remark': remark?.trim().isEmpty == true
              ? null
              : remark?.trim(),
          'rated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', conversationId)
        .eq('patient_id', currentUserId)
        .eq('status', 'closed')
        .select('id');

    if ((updatedRows as List).isEmpty) {
      throw Exception(
        'The review was not saved. The session may not belong to this patient.',
      );
    }

    await _updateListenerAverageRating(listenerId);
  }

  Future<void> _updateListenerAverageRating(String listenerId) async {
    try {
      final ratedSessions = await supabase
          .from('listener_conversation')
          .select('patient_rating')
          .eq('listener_id', listenerId)
          .eq('status', 'closed')
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
