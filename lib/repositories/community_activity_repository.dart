// repositories/activity_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/community_activity.dart';

class CommunityActivityRepository {
  final supabase = Supabase.instance.client;
  String get _uid => supabase.auth.currentUser!.id;

  Future<List<CommunityActivity>> getActivities() async {
    final data = await supabase
        .from('activities')
        .select('*, activity_registrations(count)')
        .eq('is_deleted', false)
        .eq('is_archived', false)
        .order('event_date', ascending: true);

    final activityIds = (data as List).map((a) => a['id']).toList();
    final registrations = activityIds.isEmpty ? [] : await supabase
        .from('activity_registrations')
        .select('activity_id')
        .eq('patient_id', _uid)
        .eq('is_cancelled', false)
        .inFilter('activity_id', activityIds);

    final registeredIds = (registrations)
        .map((r) => r['activity_id'])
        .toSet();

    return data.map((a) {
      final map = {
        ...a,
        'registered_count':
            (a['activity_registrations'] as List?)?.first?['count'] ?? 0,
      };
      return CommunityActivity.fromMap(map,
          isRegistered: registeredIds.contains(a['id']));
    }).toList();
  }

  Future<void> register(String activityId) async {
    await supabase.from('activity_registrations').upsert({
      'activity_id': activityId,
      'patient_id': _uid,
      'is_cancelled': false,
    });
    await _log('activity_registered', targetId: activityId);
  }

  Future<void> cancelRegistration(String activityId) async {
    await supabase.from('activity_registrations').update({
      'is_cancelled': true,
    }).eq('activity_id', activityId).eq('patient_id', _uid);
    await _log('activity_cancelled', targetId: activityId);
  }

  Future<void> _log(String action, {String? targetId}) async {
    await supabase.from('user_activity_logs').insert({
      'patient_id': _uid,
      'action': action,
      'target_type': 'activity',
      if (targetId != null) 'target_id': targetId,
    });
  }
}