import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/activity_registration.dart';

class ActivityRegistrationsTableRepository {
  final SupabaseClient supabase;

  ActivityRegistrationsTableRepository({SupabaseClient? supabase})
    : supabase = supabase ?? Supabase.instance.client;

  Future<List<dynamic>> findActiveRegistrations(
    String patientId,
    List activityIds,
  ) async {
    if (activityIds.isEmpty) return [];
    return await supabase
        .from('activity_registrations')
        .select('activity_id')
        .eq('patient_id', patientId)
        .or('is_cancelled.is.null,is_cancelled.eq.false')
        .inFilter('activity_id', activityIds);
  }

  Future<List<dynamic>> findActiveRegistrationsForActivities(
    List activityIds,
  ) async {
    if (activityIds.isEmpty) return [];
    return await supabase
        .from('activity_registrations')
        .select('activity_id')
        .or('is_cancelled.is.null,is_cancelled.eq.false')
        .inFilter('activity_id', activityIds);
  }

  Future<void> register(String activityId, String patientId) async {
    final registration = ActivityRegistration(
      activityId: activityId,
      patientId: patientId,
    );
    await supabase.from('activity_registrations').upsert(
      registration.toMap(),
      onConflict: 'activity_id,patient_id',
    );
  }

  Future<void> cancel(String activityId, String patientId) async {
    await supabase
        .from('activity_registrations')
        .update({'is_cancelled': true})
        .eq('activity_id', activityId)
        .eq('patient_id', patientId);
  }
}
