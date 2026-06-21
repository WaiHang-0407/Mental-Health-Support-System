import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/patient_follow.dart';

class PatientFollowsTableRepository {
  final SupabaseClient supabase;

  PatientFollowsTableRepository({SupabaseClient? supabase})
    : supabase = supabase ?? Supabase.instance.client;

  Future<bool> exists(String followerId, String followingId) async {
    final data = await supabase
        .from('patient_follows')
        .select('id')
        .eq('follower_id', followerId)
        .eq('following_id', followingId)
        .maybeSingle();
    return data != null;
  }

  Future<void> upsert(String followerId, String followingId) async {
    final follow = PatientFollow(
      followerId: followerId,
      followingId: followingId,
    );
    await supabase.from('patient_follows').upsert(follow.toMap());
  }

  Future<void> delete(String followerId, String followingId) async {
    await supabase
        .from('patient_follows')
        .delete()
        .eq('follower_id', followerId)
        .eq('following_id', followingId);
  }

  Future<int> followerCount(String patientId) async {
    final data = await supabase
        .from('patient_follows')
        .select('id')
        .eq('following_id', patientId);
    return (data as List).length;
  }

  Future<int> followingCount(String patientId) async {
    final data = await supabase
        .from('patient_follows')
        .select('id')
        .eq('follower_id', patientId);
    return (data as List).length;
  }
}
