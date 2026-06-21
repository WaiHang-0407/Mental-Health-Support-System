import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_activity_log.dart';

class UserActivityLogsTableRepository {
  final SupabaseClient supabase;

  UserActivityLogsTableRepository({SupabaseClient? supabase})
    : supabase = supabase ?? Supabase.instance.client;

  Future<List<dynamic>> getByPatient(String patientId, {int limit = 50}) async {
    return await supabase
        .from('user_activity_logs')
        .select()
        .eq('patient_id', patientId)
        .order('created_at', ascending: false)
        .limit(limit);
  }

  Future<void> insert({
    required String patientId,
    required String action,
    String? targetType,
    String? targetId,
  }) async {
    final activityLog = UserActivityLog(
      id: '',
      patientId: patientId,
      action: action,
      targetType: targetType,
      targetId: targetId,
      createdAt: DateTime.now(),
    );
    await supabase.from('user_activity_logs').insert(activityLog.toCreateMap());
  }
}
